/// Configuration for error recovery behavior.
class RecoveryConfig {
  /// Maximum number of recovery attempts before using fallback.
  static const int maxRecoveryAttempts = 2;

  /// Maximum total time allowed for all recovery attempts before using fallback.
  static const Duration maxRecoveryTime = Duration(seconds: 10);

  /// Delay for the first recovery attempt.
  static const Duration firstRetryDelay = Duration(seconds: 1);

  /// Delay for the second recovery attempt.
  static const Duration secondRetryDelay = Duration(seconds: 2);

  /// Maximum time to wait for rate limit before using fallback.
  static const Duration maxRateLimitWait = Duration(seconds: 5);
}