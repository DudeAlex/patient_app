import 'dart:async';

import 'package:flutter/foundation.dart';

import 'application/use_cases/mark_auto_sync_success_use_case.dart';
import 'auto_sync_backup_service.dart';
import 'domain/entities/auto_sync_status.dart';
import 'network/auto_sync_network_info.dart';

/// Handles background Drive backups when auto sync decides conditions are met.
///
/// This class focuses on orchestration (single-flight execution, state updates,
/// analytics logging) and ensures backups only run when the device is on a
/// Wi-Fi/ethernet connection. Failed runs are retried with exponential backoff.
class AutoSyncRunner {
  AutoSyncRunner(
    this._markSuccessUseCase, {
    required AutoSyncBackupClient backupClient,
    DateTime Function()? clock,
    Duration? minInterval,
    AutoSyncNetworkInfo? networkInfo,
    Duration? initialRetryDelay,
    Duration? maxRetryDelay,
  }) : _backupClient = backupClient,
       _clock = clock ?? DateTime.now,
       _minInterval = minInterval ?? const Duration(hours: 6),
       _networkInfo = networkInfo ?? ConnectivityAutoSyncNetworkInfo(),
       _initialRetryDelay = initialRetryDelay ?? const Duration(minutes: 5),
       _maxRetryDelay = maxRetryDelay ?? const Duration(hours: 2),
       _currentRetryDelay = initialRetryDelay ?? const Duration(minutes: 5);

  final MarkAutoSyncSuccessUseCase _markSuccessUseCase;
  final AutoSyncBackupClient _backupClient;
  final DateTime Function() _clock;
  final AutoSyncNetworkInfo _networkInfo;
  final Duration _initialRetryDelay;
  final Duration _maxRetryDelay;

  /// Minimum delay between background backups to avoid re-uploading the full
  /// archive multiple times within a short window.
  final Duration _minInterval;
  Duration _currentRetryDelay;
  DateTime? _nextRetryAt;

  bool _running = false;

  bool get isRunning => _running;

  /// Exposes the next retry window for test diagnostics.
  @visibleForTesting
  DateTime? get nextRetryAt => _nextRetryAt;

  /// Invoked when the app resumes and auto sync should attempt a backup.
  Future<void> handleAppResume(AutoSyncStatus status) async {
    if (_running) {
      debugPrint('[AutoSync] Backup already running; skipping resume trigger.');
      return;
    }
    if (!status.autoSyncEnabled) {
      debugPrint('[AutoSync] Auto sync disabled. Resume trigger ignored.');
      return;
    }
    if (!status.hasPendingChanges) {
      debugPrint('[AutoSync] No pending changes. Resume trigger ignored.');
      return;
    }
    if (status.pendingCriticalChanges == 0) {
      debugPrint(
        '[AutoSync] Only routine changes pending; waiting for critical trigger.',
      );
      return;
    }
    final now = _clock();
    if (_nextRetryAt != null && now.isBefore(_nextRetryAt!)) {
      final remaining = _nextRetryAt!.difference(now);
      debugPrint(
        '[AutoSync] Waiting ${remaining.inMinutes}m before retrying after failure.',
      );
      return;
    }
    final connectionType = await _networkInfo.connectionType();
    if (connectionType != AutoSyncConnectionType.wifiLike) {
      debugPrint(
        '[AutoSync] Connectivity (${connectionType.name}) is not Wi-Fi; '
        'deferring background backup.',
      );
      return;
    }
    final lastSyncedAt = status.lastSyncedAt;
    if (lastSyncedAt != null) {
      final elapsed = now.difference(lastSyncedAt);
      if (elapsed < _minInterval) {
        final remaining = _minInterval - elapsed;
        debugPrint(
          '[AutoSync] Last backup ${elapsed.inMinutes}m ago; deferring for '
          '${remaining.inMinutes}m to reduce duplicate uploads.',
        );
        return;
      }
    }
    if (!_backupClient.hasCachedAccount) {
      debugPrint(
        '[AutoSync] No signed-in account cached; cannot run background backup.',
      );
      return;
    }
    final email = _backupClient.cachedEmail;
    if (email == null || email.isEmpty) {
      debugPrint(
        '[AutoSync] No signed-in account cached; cannot run background backup.',
      );
      return;
    }

    _running = true;
    debugPrint('[AutoSync] Starting background Drive backup for $email.');
    try {
      final result = await _backupClient.runBackup(promptIfNecessary: false);
      if (!result.isSuccess) {
        _scheduleRetry(now, result.error, result.stackTrace);
        return;
      }
      _resetRetry();
      await _markSuccessUseCase.execute(
        MarkAutoSyncSuccessInput(completedAt: result.completedAt ?? _clock()),
      );
      debugPrint('[AutoSync] Backup completed successfully.');
    } on Exception catch (e, st) {
      _scheduleRetry(now, e, st);
    } finally {
      _running = false;
    }
  }

  void _scheduleRetry(DateTime now, Object? error, StackTrace? stackTrace) {
    final delay = _currentRetryDelay;
    _nextRetryAt = now.add(delay);
    _currentRetryDelay = _nextDelay(_currentRetryDelay);
    debugPrint('[AutoSync] Backup failed: $error');
    if (stackTrace != null) {
      debugPrint('[AutoSync] STACK: ${_firstStackLine(stackTrace)}');
    }
    debugPrint(
      '[AutoSync] Next retry scheduled after ${delay.inMinutes}m (at $_nextRetryAt).',
    );
  }

  void _resetRetry() {
    _nextRetryAt = null;
    _currentRetryDelay = _initialRetryDelay;
  }

  Duration _nextDelay(Duration current) {
    final doubled = current.inMicroseconds * 2;
    final clamped = doubled.clamp(
      _initialRetryDelay.inMicroseconds,
      _maxRetryDelay.inMicroseconds,
    );
    return Duration(microseconds: clamped);
  }

  String _firstStackLine(StackTrace stackTrace) {
    final lines = stackTrace.toString().split('\n');
    if (lines.isEmpty) return stackTrace.toString();
    return lines.first;
  }
}
