import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/security/models/security_event.dart';
import 'package:patient_app/core/ai/chat/security/services/security_monitor_impl.dart';

/// Property 10: Security event logging
/// Feature: llm-stage-7e-privacy-security, Property 10: Security event logging
/// Validates: Requirements 10.1, 10.2, 10.3, 10.5
///
/// Security events are logged with metadata and retrievable within retention.
void main() {
  test('Property 10: monitor stores and retrieves recent security events', () async {
    final monitor = SecurityMonitorImpl();
    await monitor.logEvent(
      type: SecurityEventType.rateLimitViolation,
      userId: 'u1',
      metadata: {'window': 'perMinute'},
    );
    await monitor.logEvent(
      type: SecurityEventType.authenticationFailure,
      userId: 'u2',
      metadata: {'reason': 'INVALID_SIGNATURE'},
    );
    final events = await monitor.getRecentEvents();
    expect(events.length, 2);
    expect(events.map((e) => e.type), contains(SecurityEventType.rateLimitViolation));
    expect(events.map((e) => e.type), contains(SecurityEventType.authenticationFailure));
  });
}
