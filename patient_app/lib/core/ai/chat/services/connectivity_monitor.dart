import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';

import 'message_queue_service.dart';

/// Listens for connectivity changes and triggers offline queue processing when
/// connectivity is restored.
class ConnectivityMonitor {
  ConnectivityMonitor({
    required MessageQueueService messageQueueService,
    Connectivity? connectivity,
    void Function(bool isOffline)? onStatusChanged,
  })  : _queueService = messageQueueService,
        _connectivity = connectivity ?? Connectivity(),
        _onStatusChanged = onStatusChanged;

  final MessageQueueService _queueService;
  final Connectivity _connectivity;
  final void Function(bool isOffline)? _onStatusChanged;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOffline = false;

  /// Starts monitoring connectivity and processing the offline queue when
  /// connectivity returns.
  Future<void> start() async {
    // Initialize current state.
    await _updateStatus(await _connectivity.checkConnectivity());

    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      await _updateStatus(results);
    });
  }

  Future<void> _updateStatus(List<ConnectivityResult> results) async {
    final offlineNow = results.every((result) => result == ConnectivityResult.none);
    if (offlineNow == _isOffline) {
      return;
    }
    _isOffline = offlineNow;
    _onStatusChanged?.call(_isOffline);

    await AppLogger.info(
      'Connectivity status changed',
      context: {
        'isOffline': _isOffline,
        'results': results.map((r) => r.name).toList(),
      },
    );

    if (!_isOffline) {
      await _queueService.processQueue();
    }
  }

  /// Stops monitoring connectivity changes.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
