import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/metric_type.dart';
import 'package:patient_app/core/ai/chat/telemetry/services/metrics_aggregation_service_impl.dart';
import 'package:patient_app/core/ai/chat/telemetry/storage/metrics_store.dart';
import 'package:patient_app/core/ai/chat/telemetry/storage/time_series_buffer.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/metric_data_point.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/time_window.dart';

void main() {
  group('MetricsAggregationServiceImpl', () {
    late MetricsStore store;
    late MetricsAggregationServiceImpl service;

    setUp(() {
      store = MetricsStore(
        maxDataPointsPerBuffer: 100,
        minuteWindow: const Duration(minutes: 1),
        hourWindow: const Duration(hours: 1),
        dayWindow: const Duration(days: 1),
      );
      service = MetricsAggregationServiceImpl(store);
    });

    test('getCurrentRequestRate counts last minute', () {
      final now = DateTime.now();
      store.requestsPerMinute.add(MetricDataPoint(timestamp: now.subtract(const Duration(seconds: 10)), value: 1));
      store.requestsPerMinute.add(MetricDataPoint(timestamp: now, value: 1));

      expect(service.getCurrentRequestRate(), 2);
    });

    test('getRequestRatesByWindow returns minute/hour/day counts', () {
      final now = DateTime.now();
      store.requestsPerMinute.add(MetricDataPoint(timestamp: now, value: 1));
      store.requestsPerHour.add(MetricDataPoint(timestamp: now, value: 1));
      store.requestsPerDay.add(MetricDataPoint(timestamp: now, value: 1));

      final rates = service.getRequestRatesByWindow();
      expect(rates['perMinute'], 1);
      expect(rates['perHour'], 1);
      expect(rates['perDay'], 1);
    });

    test('getLatencyStats returns avg/median/p95/p99/min/max', () {
      final now = DateTime.now();
      final values = [10.0, 20.0, 30.0, 40.0, 50.0];
      for (final v in values) {
        store.totalLatency.add(MetricDataPoint(timestamp: now, value: v));
      }

      final stats = service.getLatencyStats();
      expect(stats.average.inMilliseconds, 30);
      expect(stats.median.inMilliseconds, 30);
      expect(stats.p95.inMilliseconds, 50);
      expect(stats.p99.inMilliseconds, 50);
      expect(stats.min.inMilliseconds, 10);
      expect(stats.max.inMilliseconds, 50);
    });

    test('getTokenUsage aggregates prompt and completion', () {
      final now = DateTime.now();
      store.promptTokens.add(MetricDataPoint(timestamp: now, value: 100));
      store.completionTokens.add(MetricDataPoint(timestamp: now, value: 50));

      final stats = service.getTokenUsage();
      expect(stats.promptTokens, 100);
      expect(stats.completionTokens, 50);
      expect(stats.totalTokens, 150);
      expect(stats.averagePerRequest, greaterThan(0));
    });

    test('getErrorStats aggregates by type and computes rates', () {
      final now = DateTime.now();
      store.requestsPerHour.add(MetricDataPoint(timestamp: now, value: 1));
      store.requestsPerHour.add(MetricDataPoint(timestamp: now, value: 1));
      store.errorsByType['network']?.add(MetricDataPoint(timestamp: now, value: 1));

      final stats = service.getErrorStats();
      expect(stats.totalErrors, 1);
      expect(stats.totalRequests, 2);
      expect(stats.totalErrorRate, closeTo(50.0, 0.0001));
      expect(stats.errorCountByType['network'], 1);
      expect(stats.errorRateByType['network'], closeTo(50.0, 0.0001));
    });

    test('getCacheHitRate computes hits over total', () {
      final now = DateTime.now();
      store.cacheHits.add(MetricDataPoint(timestamp: now, value: 1));
      store.cacheMisses.add(MetricDataPoint(timestamp: now, value: 1));

      final rate = service.getCacheHitRate();
      expect(rate, 0.5);
    });

    test('getHistoricalMetrics returns points for type', () {
      final now = DateTime.now();
      store.requestsPerMinute.add(MetricDataPoint(timestamp: now, value: 1));

      final points = service.getHistoricalMetrics(
        type: MetricType.requestRate,
        startTime: now.subtract(const Duration(minutes: 1)),
        endTime: now.add(const Duration(minutes: 1)),
      );

      expect(points.length, 1);
      expect(points.first['value'], 1);
    });
  });
}
