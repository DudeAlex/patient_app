import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/telemetry/storage/metrics_store.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/metric_data_point.dart';

void main() {
  group('MetricsStore', () {
    test('derives buffer capacity from memory budget', () {
      final store = MetricsStore(
        totalMemoryBudgetBytes: 1024, // tiny budget to force small capacity
        bytesPerPointEstimate: 128,
        maxDataPointsPerBuffer: 100,
        errorTypes: const ['network', 'timeout'],
      );

      expect(store.bufferCapacity, greaterThan(0));
      expect(store.bufferCapacity, lessThanOrEqualTo(100));
      expect(store.errorsByType.length, 2);
    });

    test('cleanupAll prunes old points from all buffers', () {
      final store = MetricsStore(
        totalMemoryBudgetBytes: 1024 * 1024,
        bytesPerPointEstimate: 64,
        maxDataPointsPerBuffer: 10,
        minuteWindow: const Duration(milliseconds: 10),
        hourWindow: const Duration(milliseconds: 10),
        dayWindow: const Duration(milliseconds: 10),
        latencyWindow: const Duration(milliseconds: 10),
      );

      final oldTimestamp = DateTime.now().subtract(const Duration(seconds: 1));
      final oldPoint = MetricDataPoint(timestamp: oldTimestamp, value: 1);

      // Add to a few buffers
      store.requestsPerMinute.add(oldPoint);
      store.totalLatency.add(oldPoint);
      store.cacheHits.add(oldPoint);

      store.cleanupAll();

      expect(store.requestsPerMinute.snapshot(), isEmpty);
      expect(store.totalLatency.snapshot(), isEmpty);
      expect(store.cacheHits.snapshot(), isEmpty);
    });
  });
}
