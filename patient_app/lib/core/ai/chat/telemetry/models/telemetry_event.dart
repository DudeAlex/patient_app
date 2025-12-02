/// Telemetry event emitted by the collector.
class TelemetryEvent {
  /// Unique request identifier.
  final String requestId;

  /// Event type (start, complete, error).
  final String type;

  /// Arbitrary payload for metrics.
  final Map<String, dynamic> payload;

  /// Timestamp when the event was created.
  final DateTime timestamp;

  TelemetryEvent({
    required this.requestId,
    required this.type,
    required this.payload,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
