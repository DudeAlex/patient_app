import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/metric_data_point.dart';
import 'package:patient_app/core/ai/chat/telemetry/storage/time_series_buffer.dart';

void main() {
  group('TimeSeriesBuffer', () {
    test('add and getRange returns points in interval', () {
      final buffer = TimeSeriesBuffer(
        windowSize: const Duration(minutes: 1),
        maxDataPoints: 10,
      );

      final now = DateTime.now();
      final p1 = MetricDataPoint(timestamp: now.subtract(const Duration(seconds: 5)), value: 1);
      final p2 = MetricDataPoint(timestamp: now, value: 2);

      buffer.add(p1);
      buffer.add(p2);

      final result = buffer.getRange(
        now.subtract(const Duration(seconds: 10)),
        now.add(const Duration(seconds: 1)),
      );

      expect(result.length, 2);
      expect(result.map((p) => p.value), containsAll(<double>[1, 2]));
    });

    test('cleanup removes points older than window', () {
      final buffer = TimeSeriesBuffer(
        windowSize: const Duration(milliseconds: 50),
        maxDataPoints: 5,
      );

      final oldPoint = MetricDataPoint(
        timestamp: DateTime.now().subtract(const Duration(seconds: 1)),
        value: 1,
      );
      final freshPoint = MetricDataPoint(timestamp: DateTime.now(), value: 2);

      buffer.add(oldPoint);
      buffer.add(freshPoint);

      buffer.cleanup();

      final snapshot = buffer.snapshot();
      expect(snapshot.length, 1);
      expect(snapshot.first.value, 2);
    });

    test('trimOverflow keeps most recent points within capacity', () {
      final buffer = TimeSeriesBuffer(
        windowSize: const Duration(minutes: 1),
        maxDataPoints: 3,
      );

      final now = DateTime.now();
      for (int i = 0; i < 5; i++) {
        buffer.add(MetricDataPoint(timestamp: now.add(Duration(milliseconds: i)), value: i.toDouble()));
      }

      final snapshot = buffer.snapshot();
      expect(snapshot.length, 3);
      expect(snapshot.first.value, 2); // earliest retained after trimming
      expect(snapshot.last.value, 4);
    });
  });
}
