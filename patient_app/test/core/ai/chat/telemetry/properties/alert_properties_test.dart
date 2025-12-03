import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/telemetry/interfaces/metrics_aggregation_service.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/alert_condition.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/metric_type.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/time_window.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/error_stats.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/latency_stats.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/token_usage_stats.dart';
import 'package:patient_app/core/ai/chat/telemetry/services/alert_monitoring_service_impl.dart';

class _MetricsStub implements MetricsAggregationService {
  _MetricsStub({
    this.requestRate = 0,
    this.latencyMs = 0,
    this.cacheHitRateValue = 0,
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.errorRate = 0,
  });

  double requestRate;
  double latencyMs;
  double cacheHitRateValue;
  int promptTokens;
  int completionTokens;
  double errorRate;

  @override
  double getCacheHitRate({window = TimeWindow.hour}) => cacheHitRateValue;

  @override
  int getCurrentRequestRate() => requestRate.round();

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
        average: Duration(milliseconds: latencyMs.round()),
        median: Duration(milliseconds: latencyMs.round()),
        p95: Duration(milliseconds: latencyMs.round()),
        p99: Duration(milliseconds: latencyMs.round()),
        min: Duration(milliseconds: latencyMs.round()),
        max: Duration(milliseconds: latencyMs.round()),
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
        'perMinute': requestRate.round(),
        'perHour': 0,
        'perDay': 0,
      };
}

void main() {
  group('Telemetry Property 10: Alert threshold triggering', () {
    late _MetricsStub metrics;
    late AlertMonitoringServiceImpl alerts;

    setUp(() {
      metrics = _MetricsStub();
      alerts = AlertMonitoringServiceImpl(metrics, registerDefaults: false);
    });

    test('triggers when threshold exceeded', () async {
      metrics.requestRate = 200;
      alerts.registerAlert(
        alertId: 'req-rate',
        metric: MetricType.requestRate,
        condition: AlertCondition(
          operator: ComparisonOperator.greaterThan,
          evaluationWindow: const Duration(minutes: 1),
        ),
        threshold: 100,
        message: 'High request rate',
      );

      final triggered = await alerts.checkAlerts();
      expect(triggered.length, 1);
      expect(triggered.first.alertId, 'req-rate');
    });

    test('does not trigger when below threshold', () async {
      metrics.latencyMs = 50;
      alerts.registerAlert(
        alertId: 'latency',
        metric: MetricType.totalLatency,
        condition: AlertCondition(
          operator: ComparisonOperator.greaterThan,
          evaluationWindow: const Duration(minutes: 1),
        ),
        threshold: 100,
        message: 'Latency high',
      );

      final triggered = await alerts.checkAlerts();
      expect(triggered, isEmpty);
    });
  });
}
