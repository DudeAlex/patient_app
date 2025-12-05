import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/security/models/security_event.dart';
import 'package:patient_app/core/ai/chat/security/services/security_monitor_impl.dart';

class _FakeClock {
  _FakeClock(this._now);

  DateTime _now;

  DateTime call() => _now;

  void advance(Duration duration) {
    _now = _now.add(duration);
  }
}

void main() {
  test('logs events, prunes by retention, and returns recent events', () async {
    final clock = _FakeClock(DateTime(2025, 1, 1, 12, 0, 0));
    final monitor = SecurityMonitorImpl(clock: clock.call);

    await monitor.logEvent(type: SecurityEventType.rateLimitViolation, userId: 'u1');
    var recent = await monitor.getRecentEvents();
    expect(recent.length, 1);
    expect(recent.first.type, SecurityEventType.rateLimitViolation);

    clock.advance(const Duration(hours: 25));
    recent = await monitor.getRecentEvents();
    expect(recent, isEmpty);
  });

  test('detects suspicious activity from repeated auth failures', () async {
    final clock = _FakeClock(DateTime(2025, 1, 1, 12, 0, 0));
    final monitor = SecurityMonitorImpl(clock: clock.call);

    await monitor.logEvent(type: SecurityEventType.authenticationFailure, userId: 'u2');
    await monitor.logEvent(type: SecurityEventType.authenticationFailure, userId: 'u2');
    expect(await monitor.isSuspiciousActivity(userId: 'u2'), isFalse);

    clock.advance(const Duration(minutes: 2));
    await monitor.logEvent(type: SecurityEventType.authenticationFailure, userId: 'u2');
    expect(await monitor.isSuspiciousActivity(userId: 'u2'), isTrue);
  });

  test('flags mixed burst of different security failures', () async {
    final clock = _FakeClock(DateTime(2025, 1, 1, 12, 0, 0));
    final monitor = SecurityMonitorImpl(clock: clock.call);
    const userId = 'u3';

    await monitor.logEvent(type: SecurityEventType.rateLimitViolation, userId: userId);
    await monitor.logEvent(type: SecurityEventType.authenticationFailure, userId: userId);
    await monitor.logEvent(type: SecurityEventType.inputValidationFailure, userId: userId);
    await monitor.logEvent(type: SecurityEventType.rateLimitViolation, userId: userId);
    await monitor.logEvent(type: SecurityEventType.suspiciousActivity, userId: userId);

    expect(await monitor.isSuspiciousActivity(userId: userId), isTrue);
  });

  test('forwards events to telemetry sink', () async {
    final clock = _FakeClock(DateTime(2025, 1, 1, 12, 0, 0));
    SecurityEvent? forwarded;
    final monitor = SecurityMonitorImpl(
      clock: clock.call,
      telemetrySink: (event) => forwarded = event,
    );

    await monitor.logEvent(
      type: SecurityEventType.inputValidationFailure,
      userId: 'u4',
      metadata: {'field': 'message'},
    );

    expect(forwarded, isNotNull);
    expect(forwarded!.userId, 'u4');
    expect(forwarded!.metadata['field'], 'message');
  });
}
