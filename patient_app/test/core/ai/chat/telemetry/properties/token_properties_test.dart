import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/metric_data_point.dart';
import 'package:patient_app/core/ai/chat/telemetry/services/metrics_aggregation_service_impl.dart';
import 'package:patient_app/core/ai/chat/telemetry/storage/metrics_store.dart';

void main() {
  group('Telemetry Property 3 & 6: Token aggregation', () {
    late MetricsStore store;
    late MetricsAggregationServiceImpl metrics;

    setUp(() {
      store = MetricsStore();
      metrics = MetricsAggregationServiceImpl(store);
    });

    test('Property 3: Dimensional aggregation consistency', () {
      final now = DateTime.now();
      store.promptTokens.add(
        MetricDataPoint(timestamp: now, value: 40, metadata: {'userId': 'u1', 'spaceId': 's1'}),
      );
      store.promptTokens.add(
        MetricDataPoint(timestamp: now, value: 20, metadata: {'userId': 'u2', 'spaceId': 's1'}),
      );
      store.completionTokens.add(
        MetricDataPoint(timestamp: now, value: 10, metadata: {'userId': 'u1', 'spaceId': 's2'}),
      );

      final stats = metrics.getTokenUsage();
      final byUserTotal = stats.byUser.values.fold<int>(0, (sum, v) => sum + v);
      final bySpaceTotal = stats.bySpace.values.fold<int>(0, (sum, v) => sum + v);

      expect(byUserTotal, stats.totalTokens);
      expect(bySpaceTotal, stats.totalTokens);
    });

    test('Property 6: Token sum consistency', () {
      final now = DateTime.now();
      store.promptTokens.add(MetricDataPoint(timestamp: now, value: 60));
      store.completionTokens.add(MetricDataPoint(timestamp: now, value: 40));

      final stats = metrics.getTokenUsage();
      expect(stats.totalTokens, stats.promptTokens + stats.completionTokens);
    });
  });
}
