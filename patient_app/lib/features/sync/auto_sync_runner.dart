import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_drive_backup/google_drive_backup.dart';

import 'auto_sync_status.dart';
import 'sync_state_repository.dart';

/// Handles background Drive backups when auto sync decides conditions are met.
///
/// This class focuses on orchestration (single-flight execution, state updates,
/// analytics logging). Network heuristics (Wi-Fi vs cellular) will be layered
/// in a follow-up iteration.
class AutoSyncRunner {
  AutoSyncRunner(
    this._syncStateRepository, {
    DriveBackupManager? backupManager,
    DateTime Function()? clock,
  })  : _backupManager = backupManager ?? DriveBackupManager(),
        _clock = clock ?? DateTime.now;

  final SyncStateRepository _syncStateRepository;
  final DriveBackupManager _backupManager;
  final DateTime Function() _clock;

  bool _running = false;

  bool get isRunning => _running;

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
    final email = _backupManager.auth.cachedEmail;
    if (email == null || email.isEmpty) {
      debugPrint(
        '[AutoSync] No signed-in account cached; cannot run background backup.',
      );
      return;
    }

    _running = true;
    debugPrint('[AutoSync] Starting background Drive backup for $email.');
    try {
      await _backupManager.backupToDrive(promptIfNecessary: false);
      await _syncStateRepository.markSyncSuccess(_clock());
      debugPrint('[AutoSync] Backup completed successfully.');
    } on Exception catch (e, st) {
      debugPrint('[AutoSync] Backup failed: $e');
      debugPrint('[AutoSync] STACK: ${_firstStackLine(st)}');
    } finally {
      _running = false;
    }
  }

  String _firstStackLine(StackTrace stackTrace) {
    final lines = stackTrace.toString().split('\n');
    if (lines.isEmpty) return stackTrace.toString();
    return lines.first;
  }
}
