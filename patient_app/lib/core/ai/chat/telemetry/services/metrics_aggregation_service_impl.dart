import 'package:patient_app/core/ai/chat/telemetry/interfaces/metrics_aggregation_service.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/error_stats.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/latency_stats.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/metric_type.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/time_window.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/token_usage_stats.dart';
import 'package:patient_app/core/ai/chat/telemetry/storage/metrics_store.dart';
import 'package:patient_app/core/ai/chat/telemetry/storage/time_series_buffer.dart';

/// In-memory implementation of [MetricsAggregationService].
class MetricsAggregationServiceImpl implements MetricsAggregationService {
  final MetricsStore _store;

  MetricsAggregationServiceImpl(this._store);

  @override
  int getCurrentRequestRate() {
    final now = DateTime.now();
    final points = _store.requestsPerMinute.getRange(
      now.subtract(const Duration(minutes: 1)),
      now,
    );
    return points.length;
  }

  @override
  Map<String, int> getRequestRatesByWindow() {
    final now = DateTime.now();
    final perHour = _store.requestsPerHour.getRange(
      now.subtract(const Duration(hours: 1)),
      now,
    );
    final perDay = _store.requestsPerDay.getRange(
      now.subtract(const Duration(days: 1)),
      now,
    );

    return {
      'perMinute': getCurrentRequestRate(),
      'perHour': perHour.length,
      'perDay': perDay.length,
    };
  }

  @override
  LatencyStats getLatencyStats({TimeWindow window = TimeWindow.hour}) {
    final now = DateTime.now();
    final windowDuration = _windowDuration(window);
    final total = _store.totalLatency.getRange(now.subtract(windowDuration), now);

    if (total.isEmpty) {
      return LatencyStats(
        average: Duration.zero,
        median: Duration.zero,
        p95: Duration.zero,
        p99: Duration.zero,
        min: Duration.zero,
        max: Duration.zero,
      );
    }

    final values = total.map((p) => p.value).toList()..sort();
    final sum = values.reduce((a, b) => a + b);
    final avg = sum / values.length;
    final median = values[values.length ~/ 2];
    final p95 = values[((values.length - 1) * 0.95).round()];
    final p99 = values[((values.length - 1) * 0.99).round()];

    return LatencyStats(
      average: Duration(milliseconds: avg.round()),
      median: Duration(milliseconds: median.round()),
      p95: Duration(milliseconds: p95.round()),
      p99: Duration(milliseconds: p99.round()),
      min: Duration(milliseconds: values.first.round()),
      max: Duration(milliseconds: values.last.round()),
    );
  }

  @override
  TokenUsageStats getTokenUsage({TimeWindow window = TimeWindow.day}) {
    final now = DateTime.now();
    final windowDuration = _windowDuration(window);
    final prompt = _store.promptTokens
        .getRange(now.subtract(windowDuration), now)
        .map((p) => _Point(p.timestamp, p.value, p.metadata))
        .toList();
    final completion = _store.completionTokens
        .getRange(now.subtract(windowDuration), now)
        .map((p) => _Point(p.timestamp, p.value, p.metadata))
        .toList();

    final promptTotal = prompt.fold<int>(0, (sum, p) => sum + p.value.toInt());
    final completionTotal = completion.fold<int>(0, (sum, p) => sum + p.value.toInt());
    final totalTokens = promptTotal + completionTotal;
    final count = (prompt.length > completion.length) ? prompt.length : completion.length;
    final averagePerRequest = count == 0 ? 0.0 : totalTokens / count;

    final byUser = <String, int>{};
    final bySpace = <String, int>{};
    void accumulate(List<_Point> points) {
      for (final point in points) {
        final user = point.metadata['userId'] as String?;
        final space = point.metadata['spaceId'] as String?;
        if (user != null) {
          byUser[user] = (byUser[user] ?? 0) + point.value.toInt();
        }
        if (space != null) {
          bySpace[space] = (bySpace[space] ?? 0) + point.value.toInt();
        }
      }
    }

    accumulate(prompt);
    accumulate(completion);

    return TokenUsageStats(
      totalTokens: totalTokens,
      promptTokens: promptTotal,
      completionTokens: completionTotal,
      byUser: byUser,
      bySpace: bySpace,
      averagePerRequest: averagePerRequest,
    );
  }

  @override
  ErrorStats getErrorStats({TimeWindow window = TimeWindow.hour}) {
    final now = DateTime.now();
    final windowDuration = _windowDuration(window);

    int totalRequests = _store.requestsPerHour.getRange(now.subtract(windowDuration), now).length;
    if (window == TimeWindow.day) {
      totalRequests = _store.requestsPerDay.getRange(now.subtract(windowDuration), now).length;
    }

    int totalErrors = 0;
    final errorCountByType = <String, int>{};
    final errorRateByType = <String, double>{};

    for (final entry in _store.errorsByType.entries) {
      final points = entry.value.getRange(now.subtract(windowDuration), now);
      errorCountByType[entry.key] = points.length;
      totalErrors += points.length;
    }

    for (final entry in errorCountByType.entries) {
      errorRateByType[entry.key] = totalRequests == 0
          ? 0.0
          : (entry.value / totalRequests) * 100;
    }

    final totalErrorRate = totalRequests == 0 ? 0.0 : (totalErrors / totalRequests) * 100;

    return ErrorStats(
      totalErrorRate: totalErrorRate,
      errorRateByType: errorRateByType,
      errorCountByType: errorCountByType,
      totalErrors: totalErrors,
      totalRequests: totalRequests,
    );
  }

  @override
  double getCacheHitRate({TimeWindow window = TimeWindow.hour}) {
    final now = DateTime.now();
    final windowDuration = _windowDuration(window);
    final hits = _store.cacheHits.getRange(now.subtract(windowDuration), now).length;
    final misses = _store.cacheMisses.getRange(now.subtract(windowDuration), now).length;
    final total = hits + misses;
    if (total == 0) {
      return 0.0;
    }
    return hits / total;
  }

  @override
  List<Map<String, dynamic>> getHistoricalMetrics({
    required MetricType type,
    required DateTime startTime,
    required DateTime endTime,
    TimeWindow window = TimeWindow.hour,
  }) {
    final buffer = _bufferForType(type);
    final points = buffer.getRange(startTime, endTime);
    return points
        .map((p) => {
              'timestamp': p.timestamp,
              'value': p.value,
              'metadata': p.metadata,
            })
        .toList();
  }

  Duration _windowDuration(TimeWindow window) {
    switch (window) {
      case TimeWindow.minute:
        return const Duration(minutes: 1);
      case TimeWindow.hour:
        return const Duration(hours: 1);
      case TimeWindow.day:
        return const Duration(days: 1);
      case TimeWindow.week:
        return const Duration(days: 7);
      case TimeWindow.month:
        return const Duration(days: 30);
    }
  }

  /// Selects the appropriate buffer for a given metric type.
  _BufferView _bufferForType(MetricType type) {
    switch (type) {
      case MetricType.requestRate:
        return _BufferView(_store.requestsPerMinute);
      case MetricType.totalLatency:
        return _BufferView(_store.totalLatency);
      case MetricType.contextLatency:
        return _BufferView(_store.contextLatency);
      case MetricType.llmLatency:
        return _BufferView(_store.llmLatency);
      case MetricType.promptTokens:
        return _BufferView(_store.promptTokens);
      case MetricType.completionTokens:
        return _BufferView(_store.completionTokens);
      case MetricType.totalTokens:
        return _BufferView.merge([_store.promptTokens, _store.completionTokens]);
      case MetricType.errorRate:
        // Combine all error buffers into a synthetic view.
        return _BufferView.merge(_store.errorsByType.values.toList());
      case MetricType.cacheHitRate:
        return _BufferView.merge([_store.cacheHits, _store.cacheMisses]);
    }
  }
}

/// Lightweight wrapper to unify single and merged buffers.
class _BufferView {
  final List<_PointAccessor> _sources;

  _BufferView(TimeSeriesBuffer buffer) : _sources = [_PointAccessor(buffer)];

  _BufferView.merge(List<TimeSeriesBuffer> buffers)
      : _sources = buffers.map<_PointAccessor>((b) => _PointAccessor(b)).toList();

  List<_Point> getRange(DateTime start, DateTime end) {
    return _sources
        .expand((s) => s.getRange(start, end))
        .map((p) => _Point(p.timestamp, p.value, p.metadata))
        .toList();
  }
}

class _PointAccessor {
  final TimeSeriesBuffer buffer;
  _PointAccessor(this.buffer);

  List<_Point> getRange(DateTime start, DateTime end) {
    return buffer.getRange(start, end).map((p) => _Point(p.timestamp, p.value, p.metadata)).toList();
  }
}

class _Point {
  final DateTime timestamp;
  final double value;
  final Map<String, dynamic> metadata;

  _Point(this.timestamp, this.value, this.metadata);
}
