import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/metric_data_point.dart';
import 'package:patient_app/core/ai/chat/telemetry/services/metrics_aggregation_service_impl.dart';
import 'package:patient_app/core/ai/chat/telemetry/storage/metrics_store.dart';

void main() {
  group('Telemetry Property 1 & 2: Request counting and windows', () {
    late MetricsStore store;
    late MetricsAggregationServiceImpl metrics;

    setUp(() {
      store = MetricsStore(
        minuteWindow: const Duration(minutes: 1),
        hourWindow: const Duration(hours: 1),
        dayWindow: const Duration(days: 1),
      );
      metrics = MetricsAggregationServiceImpl(store);
    });

    test('Property 1: Request counting accuracy', () {
      final now = DateTime.now();
      const inWindow = 5;
      const outOfWindow = 3;

      for (var i = 0; i < inWindow; i++) {
        store.requestsPerMinute.add(
          MetricDataPoint(timestamp: now.subtract(Duration(seconds: i)), value: 1),
        );
      }
      for (var i = 0; i < outOfWindow; i++) {
        store.requestsPerMinute.add(
          MetricDataPoint(timestamp: now.subtract(Duration(minutes: 2 + i)), value: 1),
        );
      }

      expect(metrics.getCurrentRequestRate(), inWindow);
    });

    test('Property 2: Time window aggregation', () {
      final now = DateTime.now();
      final random = Random(42);

      // Populate requests across minute/hour/day boundaries.
      for (var i = 0; i < 10; i++) {
        store.requestsPerMinute.add(MetricDataPoint(timestamp: now.subtract(Duration(seconds: i)), value: 1));
      }
      for (var i = 0; i < 7; i++) {
        store.requestsPerHour.add(
          MetricDataPoint(timestamp: now.subtract(Duration(minutes: random.nextInt(59))), value: 1),
        );
      }
      for (var i = 0; i < 4; i++) {
        store.requestsPerDay.add(
          MetricDataPoint(timestamp: now.subtract(Duration(hours: random.nextInt(23))), value: 1),
        );
      }

      final rates = metrics.getRequestRatesByWindow();
      expect(rates['perMinute'], 10);
      expect(rates['perHour'], 7);
      expect(rates['perDay'], 4);
    });
  });
}
