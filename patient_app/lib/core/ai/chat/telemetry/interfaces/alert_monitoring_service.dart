import 'package:patient_app/core/ai/chat/telemetry/models/alert.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/alert_condition.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/metric_type.dart';

/// Contract for monitoring metrics and triggering alerts.
abstract class AlertMonitoringService {
  /// Register an alert threshold.
  void registerAlert({
    required String alertId,
    required MetricType metric,
    required AlertCondition condition,
    required double threshold,
    required String message,
  });

  /// Evaluate all alerts and return newly triggered ones.
  Future<List<Alert>> checkAlerts();

  /// Get triggered alerts, optionally filtered by time.
  List<Alert> getTriggeredAlerts({DateTime? since});
}
