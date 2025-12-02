import 'package:patient_app/core/ai/chat/telemetry/models/error_stats.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/latency_stats.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/metric_type.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/time_window.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/token_usage_stats.dart';

/// Contract for aggregating telemetry metrics into higher-level statistics.
abstract class MetricsAggregationService {
  /// Current request rate (per minute).
  int getCurrentRequestRate();

  /// Request rate per hour and per day.
  Map<String, int> getRequestRatesByWindow();

  /// Latency statistics for a given window.
  LatencyStats getLatencyStats({TimeWindow window = TimeWindow.hour});

  /// Token usage statistics for a given window.
  TokenUsageStats getTokenUsage({TimeWindow window = TimeWindow.day});

  /// Error metrics for a given window.
  ErrorStats getErrorStats({TimeWindow window = TimeWindow.hour});

  /// Cache hit rate (0.0 - 1.0) for a given window.
  double getCacheHitRate({TimeWindow window = TimeWindow.hour});

  /// Historical time-series data for a metric type within a range.
  List<Map<String, dynamic>> getHistoricalMetrics({
    required MetricType type,
    required DateTime startTime,
    required DateTime endTime,
    TimeWindow window = TimeWindow.hour,
  });
}
