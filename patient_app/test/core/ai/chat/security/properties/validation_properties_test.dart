import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/security/models/validation_result.dart';
import 'package:patient_app/core/ai/chat/security/services/input_validator_impl.dart';

/// Property 6: Input validation rejection
/// Feature: llm-stage-7e-privacy-security, Property 6: Input validation rejection
/// Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5
///
/// Malformed or malicious inputs are rejected; valid inputs are sanitized.
void main() {
  final validator = InputValidatorImpl();

  test('Property 6: rejects malicious or malformed inputs', () {
    final invalidSamples = [
      '', // too short
      '   ', // whitespace only
      'a' * 10001, // too long
      '<script>alert(1)</script>', // XSS
      'DROP TABLE users;', // SQL/command injection
      'bad id!*', // invalid space id if treated as id
    ];

    for (final sample in invalidSamples) {
      final result = validator.validateMessage(sample);
      if (sample == 'bad id!*') {
        final spaceResult = validator.validateSpaceId(sample);
        expect(spaceResult.isValid, isFalse, reason: 'Space ID should be invalid: $sample');
      } else {
        expect(result.isValid, isFalse, reason: 'Message should be invalid: $sample');
      }
    }
  });

  test('Property 6: sanitizes valid input by normalizing whitespace and stripping controls', () {
    final sanitized = validator.sanitize('  hello\tworld\u0001  ');
    expect(sanitized, 'hello world');
    final valid = validator.validateMessage('hello world');
    expect(valid.isValid, isTrue);
    expect(valid.errors, isEmpty);
  });
}
