import 'package:patient_app/core/ai/chat/telemetry/interfaces/alert_monitoring_service.dart';
import 'package:patient_app/core/ai/chat/telemetry/interfaces/metrics_aggregation_service.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/alert.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/alert_condition.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/metric_type.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/time_window.dart';

class _AlertRegistration {
  final String id;
  final MetricType metric;
  final AlertCondition condition;
  final double threshold;
  final String message;

  int consecutiveHits = 0;

  _AlertRegistration({
    required this.id,
    required this.metric,
    required this.condition,
    required this.threshold,
    required this.message,
  });
}

/// Monitors metrics and triggers alerts when thresholds are violated.
class AlertMonitoringServiceImpl implements AlertMonitoringService {
  final MetricsAggregationService _metrics;
  final List<_AlertRegistration> _registrations = [];
  final List<Alert> _triggered = [];

  AlertMonitoringServiceImpl(
    this._metrics, {
    bool registerDefaults = true,
    double requestRateCapacityPerMinute = 1000,
    double latencyThresholdMs = 5000,
    double tokenBudgetPerDay = 100000,
    double tokenBudgetOverageMultiplier = 1.2,
    double errorRateThresholdPercent = 10,
  }) {
    if (registerDefaults) {
      _registerDefaultAlerts(
        requestRateCapacityPerMinute: requestRateCapacityPerMinute,
        latencyThresholdMs: latencyThresholdMs,
        tokenBudgetPerDay: tokenBudgetPerDay,
        tokenBudgetOverageMultiplier: tokenBudgetOverageMultiplier,
        errorRateThresholdPercent: errorRateThresholdPercent,
      );
    }
  }

  @override
  void registerAlert({
    required String alertId,
    required MetricType metric,
    required AlertCondition condition,
    required double threshold,
    required String message,
  }) {
    _registrations.add(_AlertRegistration(
      id: alertId,
      metric: metric,
      condition: condition,
      threshold: threshold,
      message: message,
    ));
  }

  @override
  List<Alert> getTriggeredAlerts({DateTime? since}) {
    if (since == null) {
      return List.unmodifiable(_triggered);
    }
    return _triggered.where((a) => a.triggeredAt.isAfter(since)).toList();
  }

  @override
  Future<List<Alert>> checkAlerts() async {
    final newlyTriggered = <Alert>[];

    for (final reg in _registrations) {
      final currentValue = _currentValueForMetric(reg.metric);
      final isViolation = _compare(currentValue, reg.threshold, reg.condition.operator);

      if (isViolation) {
        reg.consecutiveHits += 1;
      } else {
        reg.consecutiveHits = 0;
      }

      if (isViolation && reg.consecutiveHits >= reg.condition.consecutiveViolations) {
        final alert = Alert(
          alertId: reg.id,
          metric: reg.metric,
          actualValue: currentValue,
          threshold: reg.threshold,
          message: reg.message,
        );
        _triggered.add(alert);
        newlyTriggered.add(alert);
        reg.consecutiveHits = 0; // reset after triggering
      }
    }

    return newlyTriggered;
  }

  void _registerDefaultAlerts({
    required double requestRateCapacityPerMinute,
    required double latencyThresholdMs,
    required double tokenBudgetPerDay,
    required double tokenBudgetOverageMultiplier,
    required double errorRateThresholdPercent,
  }) {
    registerAlert(
      alertId: 'error-rate-high',
      metric: MetricType.errorRate,
      condition: AlertCondition(
        operator: ComparisonOperator.greaterThan,
        evaluationWindow: const Duration(minutes: 1),
        consecutiveViolations: 1,
      ),
      threshold: errorRateThresholdPercent,
      message: 'Error rate exceeded ${errorRateThresholdPercent.toStringAsFixed(0)}%',
    );

    registerAlert(
      alertId: 'latency-high',
      metric: MetricType.totalLatency,
      condition: AlertCondition(
        operator: ComparisonOperator.greaterThan,
        evaluationWindow: const Duration(minutes: 1),
        consecutiveViolations: 1,
      ),
      threshold: latencyThresholdMs,
      message: 'Average latency exceeded ${(latencyThresholdMs / 1000).toStringAsFixed(1)}s',
    );

    registerAlert(
      alertId: 'token-budget-overage',
      metric: MetricType.totalTokens,
      condition: AlertCondition(
        operator: ComparisonOperator.greaterThan,
        evaluationWindow: const Duration(days: 1),
        consecutiveViolations: 1,
      ),
      threshold: tokenBudgetPerDay * tokenBudgetOverageMultiplier,
      message: 'Daily token usage exceeded budget threshold',
    );

    registerAlert(
      alertId: 'request-rate-high',
      metric: MetricType.requestRate,
      condition: AlertCondition(
        operator: ComparisonOperator.greaterThan,
        evaluationWindow: const Duration(minutes: 1),
        consecutiveViolations: 1,
      ),
      threshold: requestRateCapacityPerMinute * 1.5,
      message: 'Request rate exceeded capacity threshold',
    );
  }

  bool _compare(double value, double threshold, ComparisonOperator op) {
    switch (op) {
      case ComparisonOperator.greaterThan:
        return value > threshold;
      case ComparisonOperator.greaterThanOrEqual:
        return value >= threshold;
      case ComparisonOperator.lessThan:
        return value < threshold;
      case ComparisonOperator.lessThanOrEqual:
        return value <= threshold;
      case ComparisonOperator.equal:
        return value == threshold;
    }
  }

  double _currentValueForMetric(MetricType type) {
    switch (type) {
      case MetricType.requestRate:
        return _metrics.getCurrentRequestRate().toDouble();
      case MetricType.totalLatency:
        return _metrics.getLatencyStats().average.inMilliseconds.toDouble();
      case MetricType.contextLatency:
        return _metrics.getLatencyStats().average.inMilliseconds.toDouble();
      case MetricType.llmLatency:
        return _metrics.getLatencyStats().average.inMilliseconds.toDouble();
      case MetricType.promptTokens:
        return _metrics.getTokenUsage(window: TimeWindow.day).promptTokens.toDouble();
      case MetricType.completionTokens:
        return _metrics.getTokenUsage(window: TimeWindow.day).completionTokens.toDouble();
      case MetricType.totalTokens:
        return _metrics.getTokenUsage(window: TimeWindow.day).totalTokens.toDouble();
      case MetricType.errorRate:
        return _metrics.getErrorStats().totalErrorRate;
      case MetricType.cacheHitRate:
        return _metrics.getCacheHitRate() * 100;
    }
  }
}
