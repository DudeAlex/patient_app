import 'package:patient_app/core/ai/chat/telemetry/models/metric_type.dart';

/// Alert triggered when a metric crosses a threshold.
class Alert {
  final String alertId;
  final DateTime triggeredAt;
  final MetricType metric;
  final double actualValue;
  final double threshold;
  final String message;

  Alert({
    required this.alertId,
    required this.metric,
    required this.actualValue,
    required this.threshold,
    required this.message,
    DateTime? triggeredAt,
  }) : triggeredAt = triggeredAt ?? DateTime.now();
}
