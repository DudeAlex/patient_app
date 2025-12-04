import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/security/interfaces/rate_limiter.dart';
import 'package:patient_app/core/ai/chat/security/models/rate_limit_config.dart';
import 'package:patient_app/core/ai/chat/security/services/rate_limiter_impl.dart';

void main() {
  test('enforces per-minute limit and soft/warning thresholds', () async {
    final limiter = RateLimiterImpl(
      config: RateLimitConfig(
        perMinute: 2,
        perHour: 10,
        perDay: 10,
        softLimitThreshold: 0.5,
        warningThreshold: 0.75,
      ),
      clock: () => DateTime(2025, 1, 1, 12, 0, 0),
    );
    const user = 'u1';

    final r1 = await limiter.checkLimit(userId: user, type: RateLimitType.perMinute);
    expect(r1.allowed, isTrue);
    await limiter.recordRequest(userId: user);
    await limiter.recordRequest(userId: user);
    final r2 = await limiter.checkLimit(userId: user, type: RateLimitType.perMinute);
    expect(r2.allowed, isFalse);
    expect(r2.remaining, 0);
  });

  test('computes quotas across windows', () async {
    final limiter = RateLimiterImpl(
      config: RateLimitConfig(
        perMinute: 3,
        perHour: 5,
        perDay: 7,
        softLimitThreshold: 0.8,
        warningThreshold: 0.9,
      ),
      clock: () => DateTime(2025, 1, 1, 12, 0, 0),
    );
    const user = 'u2';

    await limiter.recordRequest(userId: user);
    await limiter.recordRequest(userId: user);
    final quota = await limiter.getQuota(userId: user);
    expect(quota.perMinuteRemaining, 1);
    expect(quota.perHourRemaining, 3);
    expect(quota.perDayRemaining, 5);
  });

  test('respects day cleanup', () async {
    DateTime now = DateTime(2025, 1, 1, 12, 0, 0);
    final limiter = RateLimiterImpl(
      config: RateLimitConfig(
        perMinute: 3,
        perHour: 5,
        perDay: 5,
        softLimitThreshold: 0.8,
        warningThreshold: 0.9,
      ),
      clock: () => now,
    );
    const user = 'u3';

    await limiter.recordRequest(userId: user);
    now = now.add(const Duration(days: 2));
    final quota = await limiter.getQuota(userId: user);
    expect(quota.perDayRemaining, 5);
  });
}
