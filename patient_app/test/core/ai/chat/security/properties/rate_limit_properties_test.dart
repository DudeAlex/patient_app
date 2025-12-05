import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/security/interfaces/rate_limiter.dart';
import 'package:patient_app/core/ai/chat/security/models/rate_limit_config.dart';
import 'package:patient_app/core/ai/chat/security/services/rate_limiter_impl.dart';

/// Property 1: Rate limit enforcement
/// Feature: llm-stage-7e-privacy-security, Property 1: Rate limit enforcement
/// Validates: Requirements 1.1, 1.2, 1.3, 1.4
///
/// For any user and time window, allowed requests never exceed the configured limit.
void main() {
  test('Property 1: rate limiter blocks after configured limits', () async {
    final limiter = RateLimiterImpl(
      config: const RateLimitConfig(
        perMinute: 5,
        perHour: 8,
        perDay: 12,
        softLimitThreshold: 0.8,
        warningThreshold: 0.9,
      ),
    );
    const user = 'user-a';

    // Within per-minute window: allow first 5, reject the 6th.
    for (int i = 0; i < 5; i++) {
      final result = await limiter.checkLimit(userId: user, type: RateLimitType.perMinute);
      expect(result.allowed, isTrue, reason: 'Attempt $i should be allowed');
      await limiter.recordRequest(userId: user);
    }
    final blocked = await limiter.checkLimit(userId: user, type: RateLimitType.perMinute);
    expect(blocked.allowed, isFalse);

    // Per-hour limit still above per-minute; adding more should eventually block per-hour too.
    for (int i = 0; i < 3; i++) {
      await limiter.recordRequest(userId: user);
    }
    final hourCheck = await limiter.checkLimit(userId: user, type: RateLimitType.perHour);
    expect(hourCheck.allowed, isFalse, reason: 'Per-hour limit should be enforced');
  });

  /// Property 2: Soft limit warnings
  /// Feature: llm-stage-7e-privacy-security, Property 2: Soft limit warnings
  /// Validates: Requirements 2.1, 2.2
  ///
  /// When approaching limits, soft warnings fire at 80% and 90% thresholds.
  test('Property 2: soft limit warnings trigger at thresholds', () async {
    final limiter = RateLimiterImpl(
      config: const RateLimitConfig(
        perMinute: 10,
        perHour: 20,
        perDay: 20,
        softLimitThreshold: 0.8,
        warningThreshold: 0.9,
      ),
    );
    const user = 'user-b';

    // First 7 requests are below threshold.
    for (int i = 0; i < 7; i++) {
      await limiter.recordRequest(userId: user);
    }
    final belowSoft = await limiter.checkLimit(userId: user, type: RateLimitType.perMinute);
    expect(belowSoft.isSoftLimited, isFalse);
    expect(belowSoft.message, isNull);

    // At 8/10 (80%) should be soft limited.
    await limiter.recordRequest(userId: user);
    final soft = await limiter.checkLimit(userId: user, type: RateLimitType.perMinute);
    expect(soft.isSoftLimited, isTrue);

    // At 9/10 (90%) warning message should appear.
    await limiter.recordRequest(userId: user);
    final warning = await limiter.checkLimit(userId: user, type: RateLimitType.perMinute);
    expect(warning.isSoftLimited, isTrue);
    expect(warning.message, isNotNull);
  });
}
