/// Result of a rate limit check.
class RateLimitResult {
  const RateLimitResult({
    required this.allowed,
    required this.remaining,
    required this.resetTime,
    this.message,
    this.isSoftLimited = false,
  });

  /// Whether the request is allowed.
  final bool allowed;

  /// Remaining quota for the evaluated window.
  final int remaining;

  /// When the quota resets for this window.
  final DateTime resetTime;

  /// Optional descriptive message (e.g., soft-limit warning).
  final String? message;

  /// Whether this result represents a soft-limit warning state.
  final bool isSoftLimited;
}

/// Remaining quota across all windows.
class RateLimitQuota {
  const RateLimitQuota({
    required this.perMinuteRemaining,
    required this.perHourRemaining,
    required this.perDayRemaining,
    required this.nextReset,
  });

  final int perMinuteRemaining;
  final int perHourRemaining;
  final int perDayRemaining;
  final DateTime nextReset;
}
