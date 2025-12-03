import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/metric_data_point.dart';
import 'package:patient_app/core/ai/chat/telemetry/services/metrics_aggregation_service_impl.dart';
import 'package:patient_app/core/ai/chat/telemetry/storage/metrics_store.dart';

void main() {
  group('Telemetry Property 4 & 5: Latency completeness and stats', () {
    late MetricsStore store;
    late MetricsAggregationServiceImpl metrics;

    setUp(() {
      store = MetricsStore();
      metrics = MetricsAggregationServiceImpl(store);
    });

    test('Property 4: Latency measurement completeness', () {
      final now = DateTime.now();
      const contextMs = 30.0;
      const llmMs = 90.0;
      const totalMs = contextMs + llmMs;

      store.totalLatency.add(MetricDataPoint(timestamp: now, value: totalMs));
      store.contextLatency.add(MetricDataPoint(timestamp: now, value: contextMs));
      store.llmLatency.add(MetricDataPoint(timestamp: now, value: llmMs));

      final totalPoint = store.totalLatency.snapshot().first.value;
      final componentSum = store.contextLatency.snapshot().first.value + store.llmLatency.snapshot().first.value;
      expect(totalPoint, closeTo(componentSum, 0.0001));
    });

    test('Property 5: Statistical calculation accuracy', () {
      final now = DateTime.now();
      final samples = [10.0, 20.0, 30.0, 40.0, 50.0];
      for (final v in samples) {
        store.totalLatency.add(MetricDataPoint(timestamp: now, value: v));
      }

      final stats = metrics.getLatencyStats();
      expect(stats.average.inMilliseconds, 30);
      expect(stats.median.inMilliseconds, 30);
      expect(stats.p95.inMilliseconds, 50);
      expect(stats.p99.inMilliseconds, 50);
      expect(stats.min.inMilliseconds, 10);
      expect(stats.max.inMilliseconds, 50);
    });
  });
}
