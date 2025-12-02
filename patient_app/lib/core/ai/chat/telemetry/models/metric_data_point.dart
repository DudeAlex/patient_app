/// A single metric value captured at a point in time.
class MetricDataPoint {
  /// Timestamp when the metric was captured.
  final DateTime timestamp;

  /// The numeric value for the metric.
  final double value;

  /// Optional metadata for dimension or context (e.g., userId, spaceId).
  final Map<String, dynamic> metadata;

  /// Creates a [MetricDataPoint].
  MetricDataPoint({
    required this.timestamp,
    required this.value,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? const {};
}
