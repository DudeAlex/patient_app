/// Configuration for rate limiting thresholds.
class RateLimitConfig {
  const RateLimitConfig({
    required this.perMinute,
    required this.perHour,
    required this.perDay,
    this.softLimitThreshold = 0.8,
    this.warningThreshold = 0.9,
  });

  /// Maximum requests allowed per minute.
  final int perMinute;

  /// Maximum requests allowed per hour.
  final int perHour;

  /// Maximum requests allowed per day.
  final int perDay;

  /// Fraction of the limit considered a soft limit (e.g., 0.8 = 80%).
  final double softLimitThreshold;

  /// Fraction of the limit that triggers a warning (e.g., 0.9 = 90%).
  final double warningThreshold;
}
