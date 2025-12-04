import 'package:patient_app/core/ai/chat/security/models/rate_limit_result.dart';

/// Interface for enforcing per-user rate limits.
abstract class RateLimiter {
  /// Check if the user is within quota for the given window type.
  Future<RateLimitResult> checkLimit({
    required String userId,
    required RateLimitType type,
  });

  /// Record a request for the user.
  Future<void> recordRequest({
    required String userId,
  });

  /// Get remaining quotas across all windows.
  Future<RateLimitQuota> getQuota({
    required String userId,
  });

  /// Reset all quotas (e.g., midnight UTC).
  Future<void> resetQuotas();
}

/// Windows for rate limiting.
enum RateLimitType {
  perMinute,
  perHour,
  perDay,
}
