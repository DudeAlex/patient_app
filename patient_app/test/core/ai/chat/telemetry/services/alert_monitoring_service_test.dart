import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/telemetry/interfaces/metrics_aggregation_service.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/alert_condition.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/metric_type.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/time_window.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/error_stats.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/latency_stats.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/token_usage_stats.dart';
import 'package:patient_app/core/ai/chat/telemetry/services/alert_monitoring_service_impl.dart';

class FakeMetricsService implements MetricsAggregationService {
  int requestRate = 0;
  double avgLatencyMs = 0;
  double cacheHitRate = 0;
  int promptTokens = 0;
  int completionTokens = 0;
  double errorRate = 0;

  @override
  double getCacheHitRate({window = TimeWindow.hour}) => cacheHitRate;

  @override
  int getCurrentRequestRate() => requestRate;

  @override
  ErrorStats getErrorStats({window = TimeWindow.hour}) => ErrorStats(
        totalErrorRate: errorRate,
        errorRateByType: const {},
        errorCountByType: const {},
        totalErrors: 0,
        totalRequests: 0,
      );

  @override
  List<Map<String, dynamic>> getHistoricalMetrics({required MetricType type, required DateTime startTime, required DateTime endTime, window = TimeWindow.hour}) => [];

  @override
  LatencyStats getLatencyStats({window = TimeWindow.hour}) => LatencyStats(
        average: Duration(milliseconds: avgLatencyMs.round()),
        median: Duration(milliseconds: avgLatencyMs.round()),
        p95: Duration(milliseconds: avgLatencyMs.round()),
        p99: Duration(milliseconds: avgLatencyMs.round()),
        min: Duration(milliseconds: avgLatencyMs.round()),
        max: Duration(milliseconds: avgLatencyMs.round()),
      );

  @override
  TokenUsageStats getTokenUsage({window = TimeWindow.day}) => TokenUsageStats(
        totalTokens: promptTokens + completionTokens,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        averagePerRequest: 0,
      );

  @override
  Map<String, int> getRequestRatesByWindow() => {
        'perMinute': requestRate,
        'perHour': 0,
        'perDay': 0,
      };
}

void main() {
  group('AlertMonitoringServiceImpl', () {
    late FakeMetricsService metrics;
    late AlertMonitoringServiceImpl service;

    setUp(() {
      metrics = FakeMetricsService();
      service = AlertMonitoringServiceImpl(
        metrics,
        registerDefaults: false,
      );
    });

    test('triggers alert when value exceeds threshold', () async {
      metrics.requestRate = 200;
      service.registerAlert(
        alertId: 'req-rate',
        metric: MetricType.requestRate,
        condition: AlertCondition(
          operator: ComparisonOperator.greaterThan,
          evaluationWindow: const Duration(minutes: 1),
        ),
        threshold: 100,
        message: 'High request rate',
      );

      final alerts = await service.checkAlerts();
      expect(alerts.length, 1);
      expect(alerts.first.alertId, 'req-rate');
    });

    test('requires consecutive violations before triggering', () async {
      metrics.errorRate = 5;
      service.registerAlert(
        alertId: 'error-rate',
        metric: MetricType.errorRate,
        condition: AlertCondition(
          operator: ComparisonOperator.greaterThan,
          evaluationWindow: const Duration(minutes: 1),
          consecutiveViolations: 2,
        ),
        threshold: 4,
        message: 'High error rate',
      );

      // First violation should not trigger yet
      var alerts = await service.checkAlerts();
      expect(alerts, isEmpty);

      // Second consecutive violation should trigger
      metrics.errorRate = 6;
      alerts = await service.checkAlerts();
      expect(alerts.length, 1);
      expect(alerts.first.alertId, 'error-rate');
    });

    test('reset consecutive count when no violation', () async {
      metrics.errorRate = 6;
      service.registerAlert(
        alertId: 'error-rate',
        metric: MetricType.errorRate,
        condition: AlertCondition(
          operator: ComparisonOperator.greaterThan,
          evaluationWindow: const Duration(minutes: 1),
          consecutiveViolations: 2,
        ),
        threshold: 5,
        message: 'High error rate',
      );

      await service.checkAlerts(); // violation 1
      metrics.errorRate = 3; // reset
      await service.checkAlerts(); // no violation
      metrics.errorRate = 6; // violation again
      final alerts = await service.checkAlerts(); // should be violation 1 again, not triggering yet
      expect(alerts, isEmpty);
    });
  });
}
