import 'dart:async';

import 'package:patient_app/core/ai/chat/security/interfaces/rate_limiter.dart';
import 'package:patient_app/core/ai/chat/security/models/rate_limit_config.dart';
import 'package:patient_app/core/ai/chat/security/models/rate_limit_result.dart';

/// In-memory rate limiter with sliding windows.
class RateLimiterImpl implements RateLimiter {
  RateLimiterImpl({
    required RateLimitConfig config,
    DateTime Function() clock = DateTime.now,
  })  : _config = config,
        _clock = clock;

  final RateLimitConfig _config;
  final DateTime Function() _clock;
  final Map<String, List<DateTime>> _requests = {};

  Duration get _minuteWindow => const Duration(minutes: 1);
  Duration get _hourWindow => const Duration(hours: 1);
  Duration get _dayWindow => const Duration(days: 1);

  @override
  Future<RateLimitResult> checkLimit({
    required String userId,
    required RateLimitType type,
  }) async {
    _cleanup(userId);
    final now = _clock();
    final requests = _requests[userId] ?? <DateTime>[];

    final (limit, window) = _windowFor(type);
    final count = _countWithin(requests, now, window);
    final remaining = limit - count;
    final allowed = remaining > 0;
    final resetTime = _resetTime(now, window);

    final usageRatio = count / limit;
    final isSoft = usageRatio >= _config.softLimitThreshold && usageRatio < 1.0;
    final warn = usageRatio >= _config.warningThreshold && usageRatio < 1.0;

    final message = warn
        ? 'Approaching rate limit: ${(usageRatio * 100).toStringAsFixed(0)}% used'
        : null;

    return RateLimitResult(
      allowed: allowed,
      remaining: remaining.clamp(0, limit),
      resetTime: resetTime,
      message: message,
      isSoftLimited: isSoft,
    );
  }

  @override
  Future<void> recordRequest({required String userId}) async {
    final now = _clock();
    final list = _requests.putIfAbsent(userId, () => <DateTime>[]);
    list.add(now);
    _cleanup(userId);
  }

  @override
  Future<RateLimitQuota> getQuota({required String userId}) async {
    _cleanup(userId);
    final now = _clock();
    final requests = _requests[userId] ?? <DateTime>[];

    final minuteRemaining =
        _config.perMinute - _countWithin(requests, now, _minuteWindow);
    final hourRemaining =
        _config.perHour - _countWithin(requests, now, _hourWindow);
    final dayRemaining = _config.perDay - _countWithin(requests, now, _dayWindow);
    final nextReset = _resetTime(now, _dayWindow);

    return RateLimitQuota(
      perMinuteRemaining: minuteRemaining.clamp(0, _config.perMinute),
      perHourRemaining: hourRemaining.clamp(0, _config.perHour),
      perDayRemaining: dayRemaining.clamp(0, _config.perDay),
      nextReset: nextReset,
    );
  }

  @override
  Future<void> resetQuotas() async {
    _requests.clear();
  }

  int _countWithin(List<DateTime> entries, DateTime now, Duration window) {
    final cutoff = now.subtract(window);
    return entries.where((t) => t.isAfter(cutoff) || t.isAtSameMomentAs(cutoff)).length;
  }

  (int, Duration) _windowFor(RateLimitType type) {
    switch (type) {
      case RateLimitType.perMinute:
        return (_config.perMinute, _minuteWindow);
      case RateLimitType.perHour:
        return (_config.perHour, _hourWindow);
      case RateLimitType.perDay:
        return (_config.perDay, _dayWindow);
    }
  }

  DateTime _resetTime(DateTime now, Duration window) {
    return now.add(window);
  }

  void _cleanup(String userId) {
    final list = _requests[userId];
    if (list == null || list.isEmpty) return;
    final now = _clock();
    final cutoff = now.subtract(_dayWindow);
    list.removeWhere((t) => t.isBefore(cutoff));
    if (list.isEmpty) {
      _requests.remove(userId);
    }
  }
}
