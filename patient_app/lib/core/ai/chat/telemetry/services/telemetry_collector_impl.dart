import 'dart:async';

import 'package:patient_app/core/ai/chat/telemetry/interfaces/telemetry_collector.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/telemetry_event.dart';
import 'package:uuid/uuid.dart';

/// Default telemetry collector that emits events asynchronously without blocking requests.
class TelemetryCollectorImpl implements TelemetryCollector {
  final Uuid _uuid;
  final StreamController<TelemetryEvent> _controller;
  final Map<String, Map<String, String>> _requestContext = {};

  TelemetryCollectorImpl({
    Uuid? uuid,
    StreamController<TelemetryEvent>? controller,
  })  : _uuid = uuid ?? const Uuid(),
        _controller = controller ?? StreamController<TelemetryEvent>.broadcast();

  @override
  Stream<TelemetryEvent> get events => _controller.stream;

  @override
  String startRequest({
    required String userId,
    required String spaceId,
    required String messageId,
  }) {
    final requestId = _uuid.v4();
    final anonymizedUserId = _anonymize(userId);
    _requestContext[requestId] = {
      'userId': anonymizedUserId,
      'spaceId': spaceId,
      'messageId': messageId,
    };
    _emitAsync(
      TelemetryEvent(
        requestId: requestId,
        type: 'start',
        payload: {
          'userId': anonymizedUserId,
          'spaceId': spaceId,
          'messageId': messageId,
        },
      ),
    );
    return requestId;
  }

  @override
  Future<void> completeRequest({
    required String requestId,
    required Duration totalLatency,
    required Duration contextAssemblyTime,
    required Duration llmCallTime,
    required int promptTokens,
    required int completionTokens,
    bool fromCache = false,
  }) async {
    final context = _requestContext.remove(requestId) ?? {};
    _emitAsync(
      TelemetryEvent(
        requestId: requestId,
        type: 'complete',
        payload: {
          ...context,
          'totalLatencyMs': totalLatency.inMilliseconds,
          'contextAssemblyMs': contextAssemblyTime.inMilliseconds,
          'llmCallMs': llmCallTime.inMilliseconds,
          'promptTokens': promptTokens,
          'completionTokens': completionTokens,
          'fromCache': fromCache,
        },
      ),
    );
  }

  @override
  Future<void> recordError({
    required String requestId,
    required String errorType,
    required String errorMessage,
  }) async {
    final context = _requestContext.remove(requestId) ?? {};
    _emitAsync(
      TelemetryEvent(
        requestId: requestId,
        type: 'error',
        payload: {
          ...context,
          'errorType': errorType,
          'errorMessage': errorMessage,
        },
      ),
    );
  }

  void _emitAsync(TelemetryEvent event) {
    // Emit on microtask to avoid blocking caller.
    Future.microtask(() {
      if (!_controller.isClosed) {
        _controller.add(event);
      }
    });
  }

  /// Dispose the underlying stream controller.
  Future<void> dispose() async {
    await _controller.close();
  }

  String _anonymize(String userId) {
    // Lightweight, deterministic hashing to avoid storing raw identifiers.
    return userId.hashCode.toRadixString(16);
  }
}
