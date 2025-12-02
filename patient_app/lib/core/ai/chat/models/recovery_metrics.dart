/// Metrics for tracking error recovery effectiveness.
class RecoveryMetrics {
  /// Total number of recovery attempts made.
  final int totalAttempts;

  /// Number of successful recovery attempts.
  final int successfulRecoveries;

  /// Number of failed recovery attempts.
  final int failedRecoveries;

  /// Number of times the fallback was used.
  final int fallbacksUsed;

  /// Average recovery time across all attempts.
  final Duration averageRecoveryTime;

  /// Count of errors by type.
  final Map<String, int> errorTypeCount;

  /// Creates a [RecoveryMetrics] instance.
 RecoveryMetrics({
    required this.totalAttempts,
    required this.successfulRecoveries,
    required this.failedRecoveries,
    required this.fallbacksUsed,
    required this.averageRecoveryTime,
    required this.errorTypeCount,
  });

  /// Calculates the recovery success rate as a percentage (0.0 to 1.0).
  double get successRate => totalAttempts > 0 ? successfulRecoveries / totalAttempts : 0.0;

  /// Calculates the fallback usage rate as a percentage (0.0 to 1.0).
  double get fallbackRate => totalAttempts > 0 ? fallbacksUsed / totalAttempts : 0.0;
}