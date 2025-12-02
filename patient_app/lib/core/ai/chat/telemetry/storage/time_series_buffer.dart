import 'package:patient_app/core/ai/chat/telemetry/models/metric_data_point.dart';

/// Circular buffer for storing time-series metric data with a rolling window.
class TimeSeriesBuffer {
  /// The duration of time retained in this buffer.
  final Duration windowSize;

  /// Maximum number of data points to keep.
  final int maxDataPoints;

  final List<MetricDataPoint> _buffer = [];

  TimeSeriesBuffer({
    required this.windowSize,
    required this.maxDataPoints,
  });

  /// Adds a data point, trimming old/overflow entries.
  void add(MetricDataPoint point) {
    _buffer.add(point);
    _trimOverflow();
    cleanup();
  }

  /// Returns data points whose timestamps fall within [start] and [end], inclusive.
  List<MetricDataPoint> getRange(DateTime start, DateTime end) {
    return _buffer.where((p) => !p.timestamp.isBefore(start) && !p.timestamp.isAfter(end)).toList();
  }

  /// Removes entries older than the window size relative to now.
  void cleanup() {
    final cutoff = DateTime.now().subtract(windowSize);
    _buffer.removeWhere((p) => p.timestamp.isBefore(cutoff));
  }

  /// Returns a snapshot copy of the underlying buffer.
  List<MetricDataPoint> snapshot() => List.unmodifiable(_buffer);

  void _trimOverflow() {
    final overflow = _buffer.length - maxDataPoints;
    if (overflow > 0) {
      _buffer.removeRange(0, overflow);
    }
  }
}
