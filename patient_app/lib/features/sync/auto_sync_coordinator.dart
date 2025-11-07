import 'dart:async';

import 'package:flutter/widgets.dart';

import 'auto_sync_runner.dart';
import 'application/use_cases/promote_routine_changes_use_case.dart';
import 'application/use_cases/watch_auto_sync_status_use_case.dart';
import 'domain/entities/auto_sync_status.dart';

/// Observes lifecycle changes and persisted sync state so future auto-sync
/// orchestration can run in response to app activity.
class AutoSyncCoordinator {
  AutoSyncCoordinator(
    this._watchStatusUseCase,
    this._runner,
    this._promoteRoutineChanges,
  );

  final WatchAutoSyncStatusUseCase _watchStatusUseCase;
  final AutoSyncRunner _runner;
  final PromoteRoutineChangesUseCase _promoteRoutineChanges;

  AppLifecycleListener? _lifecycleListener;
  StreamSubscription<AutoSyncStatus>? _statusSubscription;
  final StreamController<AutoSyncStatus> _statusController =
      StreamController<AutoSyncStatus>.broadcast();

  AutoSyncStatus? _latestStatus;
  bool _started = false;

  /// Public stream for UI or diagnostics consumers that want status updates.
  Stream<AutoSyncStatus> get statusStream => _statusController.stream;

  /// Most recent snapshot emitted by [SyncStateRepository].
  AutoSyncStatus? get latestStatus => _latestStatus;

  bool get isRunning => _started;

  /// Starts watching lifecycle changes and dirty state. Safe to call multiple
  /// times; subsequent invocations are ignored.
  void start() {
    if (_started) return;
    _started = true;
    _statusSubscription = _watchStatusUseCase.execute().listen(
      (status) {
        _latestStatus = status;
        _statusController.add(status);
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[AutoSync] Failed to read status: $error');
      },
    );
    _lifecycleListener = AppLifecycleListener(
      onResume: _handleAppResume,
      onHide: _handleAppHidden,
    );
  }

  /// Disposes listeners; future [start] calls can re-establish them.
  Future<void> stop() async {
    _lifecycleListener?.dispose();
    _lifecycleListener = null;
    await _statusSubscription?.cancel();
    _statusSubscription = null;
    _started = false;
  }

  Future<void> dispose() async {
    await stop();
    await _statusController.close();
  }

  void _handleAppResume() {
    final status = _latestStatus;
    if (status == null) {
      debugPrint('[AutoSync] Resume detected but status not yet loaded.');
      return;
    }
    unawaited(_processResume(status));
  }

  void _handleAppHidden() {
    debugPrint('[AutoSync] App hidden; future iterations may trigger sync.');
  }

  Future<void> _processResume(AutoSyncStatus status) async {
    if (!status.autoSyncEnabled) {
      debugPrint('[AutoSync] Resume -> auto sync disabled; skipping backup.');
      return;
    }
    if (!status.hasPendingChanges) {
      debugPrint('[AutoSync] Resume -> no pending changes detected.');
      return;
    }

    var effectiveStatus = status;
    if (!status.hasPendingCriticalChanges &&
        status.hasPendingRoutineChanges) {
      debugPrint('[AutoSync] Promoting routine changes to trigger backup.');
      try {
        await _promoteRoutineChanges.execute();
        effectiveStatus = status.copyWith(
          pendingCriticalChanges:
              status.pendingCriticalChanges + status.pendingRoutineChanges,
          pendingRoutineChanges: 0,
        );
      } catch (e, st) {
        debugPrint('[AutoSync] Failed to promote routine changes: $e');
        debugPrint('[AutoSync] STACK: ${st.toString().split('\n').first}');
        return;
      }
    }

    if (!effectiveStatus.hasPendingCriticalChanges) {
      debugPrint('[AutoSync] Resume -> no critical changes ready for backup.');
      return;
    }

    await _runner.handleAppResume(effectiveStatus);
  }

  @visibleForTesting
  Future<void> handleResumeForTest(AutoSyncStatus status) {
    return _processResume(status);
  }
}
