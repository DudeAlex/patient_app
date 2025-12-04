import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/security/interfaces/data_redaction_service.dart';
import 'package:patient_app/core/ai/chat/security/models/redaction_pattern.dart';
import 'package:patient_app/core/ai/chat/security/services/data_redaction_service_impl.dart';

void main() {
  final svc = DataRedactionServiceImpl();

  test('redacts names', () {
    final input = 'Contact John Doe for details';
    final out = svc.redact(input);
    expect(out.contains('John Doe'), isFalse);
    expect(out.contains('[REDACTED]'), isTrue);
  });

  test('redacts emails', () {
    final input = 'Send to test.user@example.com';
    final out = svc.redact(input);
    expect(out.contains('example.com'), isFalse);
  });

  test('redacts phones', () {
    final input = 'Call 555-123-4567 now';
    final out = svc.redact(input);
    expect(out.contains('555-123-4567'), isFalse);
  });

  test('redacts ssn', () {
    final input = 'SSN 123-45-6789';
    final out = svc.redact(input);
    expect(out.contains('123-45-6789'), isFalse);
  });

  test('redacts addresses', () {
    final input = '123 Main Street, Springfield';
    final out = svc.redact(input);
    expect(out.contains('123 Main Street'), isFalse);
  });

  test('custom pattern', () {
    final custom = DataRedactionServiceImpl(patterns: []);
    custom.addPattern(RedactionPattern(name: 'secret', pattern: RegExp('SECRET')));
    final out = custom.redact('SECRET code');
    expect(out.contains('SECRET'), isFalse);
    expect(out.contains('[REDACTED]'), isTrue);
  });

  test('containsSensitiveData detects', () {
    expect(svc.containsSensitiveData('Email a@b.com'), isTrue);
    expect(svc.containsSensitiveData('No pii here'), isFalse);
  });
}
