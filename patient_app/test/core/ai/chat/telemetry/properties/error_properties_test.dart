import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/metric_data_point.dart';
import 'package:patient_app/core/ai/chat/telemetry/services/metrics_aggregation_service_impl.dart';
import 'package:patient_app/core/ai/chat/telemetry/storage/metrics_store.dart';

void main() {
  group('Telemetry Property 7 & 8: Error calculations', () {
    late MetricsStore store;
    late MetricsAggregationServiceImpl metrics;

    setUp(() {
      store = MetricsStore();
      metrics = MetricsAggregationServiceImpl(store);
    });

    test('Property 7: Error rate calculation', () {
      final now = DateTime.now();
      for (var i = 0; i < 10; i++) {
        store.requestsPerHour.add(MetricDataPoint(timestamp: now, value: 1));
      }
      for (var i = 0; i < 3; i++) {
        store.errorsByType['network']!.add(MetricDataPoint(timestamp: now, value: 1));
      }

      final stats = metrics.getErrorStats();
      expect(stats.totalErrors, 3);
      expect(stats.totalRequests, 10);
      expect(stats.totalErrorRate, closeTo(30.0, 0.0001));
    });

    test('Property 8: Error categorization completeness', () {
      final now = DateTime.now();
      store.requestsPerHour.add(MetricDataPoint(timestamp: now, value: 1));
      store.errorsByType['network']!.add(MetricDataPoint(timestamp: now, value: 1));
      store.errorsByType['timeout']!.add(MetricDataPoint(timestamp: now, value: 1));
      store.errorsByType['server']!.add(MetricDataPoint(timestamp: now, value: 1));

      final stats = metrics.getErrorStats();
      final summed = stats.errorCountByType.values.fold<int>(0, (s, v) => s + v);
      expect(summed, stats.totalErrors);
      expect(stats.errorCountByType.containsKey('network'), isTrue);
      expect(stats.errorCountByType.containsKey('timeout'), isTrue);
      expect(stats.errorCountByType.containsKey('server'), isTrue);
    });
  });
}
