/// Comparison operators for alert conditions.
enum ComparisonOperator { greaterThan, greaterThanOrEqual, lessThan, lessThanOrEqual, equal }

/// Alert condition describing how to evaluate a metric threshold.
class AlertCondition {
  final ComparisonOperator operator;
  final Duration evaluationWindow;
  final int consecutiveViolations;

  AlertCondition({
    required this.operator,
    required this.evaluationWindow,
    this.consecutiveViolations = 1,
  });
}
