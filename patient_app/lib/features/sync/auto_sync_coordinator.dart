import 'dart:async';

import 'package:flutter/widgets.dart';

import 'auto_sync_status.dart';
import 'auto_sync_runner.dart';
import 'sync_state_repository.dart';

/// Observes lifecycle changes and persisted sync state so future auto-sync
/// orchestration can run in response to app activity.
class AutoSyncCoordinator {
  AutoSyncCoordinator(this._syncStateRepository, this._runner);

  final SyncStateRepository _syncStateRepository;
  final AutoSyncRunner _runner;

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
    _statusSubscription = _syncStateRepository.watchStatus().listen(
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
    if (!status.autoSyncEnabled) {
      debugPrint('[AutoSync] Resume -> auto sync disabled; skipping backup.');
      return;
    }
    if (!status.hasPendingChanges) {
      debugPrint('[AutoSync] Resume -> no pending changes detected.');
      return;
    }
    unawaited(_runner.handleAppResume(status));
  }

  void _handleAppHidden() {
    debugPrint('[AutoSync] App hidden; future iterations may trigger sync.');
  }
}
