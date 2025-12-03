import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/metric_data_point.dart';
import 'package:patient_app/core/ai/chat/telemetry/services/metrics_aggregation_service_impl.dart';
import 'package:patient_app/core/ai/chat/telemetry/storage/metrics_store.dart';

void main() {
  group('Telemetry Property 9: Cache hit rate calculation', () {
    test('hit rate reflects hits over total and tracks totals', () {
      final store = MetricsStore();
      final metrics = MetricsAggregationServiceImpl(store);
      final now = DateTime.now();

      for (var i = 0; i < 7; i++) {
        store.cacheHits.add(MetricDataPoint(timestamp: now, value: 1));
      }
      for (var i = 0; i < 3; i++) {
        store.cacheMisses.add(MetricDataPoint(timestamp: now, value: 1));
      }

      final hitRate = metrics.getCacheHitRate();
      expect(hitRate, closeTo(0.7, 0.0001));
      final total = store.cacheHits.snapshot().length + store.cacheMisses.snapshot().length;
      expect(total, 10);
    });
  });
}
