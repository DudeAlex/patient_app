import 'dart:async';

import 'package:patient_app/core/ai/chat/telemetry/models/telemetry_event.dart';

/// Contract for collecting telemetry around AI chat requests.
abstract class TelemetryCollector {
  /// Stream of emitted telemetry events.
  Stream<TelemetryEvent> get events;

  /// Start tracking a request and return the generated requestId.
  String startRequest({
    required String userId,
    required String spaceId,
    required String messageId,
  });

  /// Record request completion with timing/token details.
  Future<void> completeRequest({
    required String requestId,
    required Duration totalLatency,
    required Duration contextAssemblyTime,
    required Duration llmCallTime,
    required int promptTokens,
    required int completionTokens,
    bool fromCache = false,
  });

  /// Record a request error with classification.
  Future<void> recordError({
    required String requestId,
    required String errorType,
    required String errorMessage,
  });
}
