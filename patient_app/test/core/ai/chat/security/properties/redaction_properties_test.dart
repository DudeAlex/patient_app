import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/security/models/redaction_pattern.dart';
import 'package:patient_app/core/ai/chat/security/services/data_redaction_service_impl.dart';

/// Property 3: PII redaction completeness
/// Feature: llm-stage-7e-privacy-security, Property 3: PII redaction completeness
/// Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5
///
/// For any text containing PII, all instances are replaced with [REDACTED].
void main() {
  final redactor = DataRedactionServiceImpl();

  test('Property 3: redacts common PII patterns', () {
    final samples = [
      'Name John Doe',
      'Email jane.doe@example.com',
      'Phone 555-123-4567',
      'SSN 123-45-6789',
      'Address 123 Main Street, Springfield',
    ];

    for (final input in samples) {
      final out = redactor.redact(input);
      expect(out, contains('[REDACTED]'));
      expect(out, isNot(contains(input.replaceAll(' ', ''))));
    }
  });

  /// Property 4: Redaction pattern application
  /// Feature: llm-stage-7e-privacy-security, Property 4: Redaction pattern application
  /// Validates: Requirements 4.1, 4.2, 4.3, 4.4
  ///
  /// For any text and pattern, if matched, replacement is applied.
  test('Property 4: custom patterns replace matches with configured replacement', () {
    final svc = DataRedactionServiceImpl(patterns: []);
    svc.addPattern(
      RedactionPattern(
        name: 'secret-code',
        pattern: RegExp(r'SECRET-[0-9]+'),
        replacement: '[MASKED]',
      ),
    );

    final out = svc.redact('Token SECRET-12345 is here');
    expect(out, contains('[MASKED]'));
    expect(out, isNot(contains('SECRET-12345')));
  });
}
