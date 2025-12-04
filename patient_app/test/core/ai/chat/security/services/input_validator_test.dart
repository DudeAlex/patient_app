import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/security/interfaces/input_validator.dart';
import 'package:patient_app/core/ai/chat/security/models/validation_result.dart';
import 'package:patient_app/core/ai/chat/security/services/input_validator_impl.dart';

void main() {
  final validator = InputValidatorImpl();

  test('accepts normal message', () {
    final result = validator.validateMessage('Hello world');
    expect(result.isValid, isTrue);
  });

  test('rejects too long message', () {
    final msg = 'a' * 10001;
    final result = validator.validateMessage(msg);
    expect(result.isValid, isFalse);
    expect(result.errors, contains(ValidationError.tooLong));
  });

  test('rejects whitespace-only', () {
    final result = validator.validateMessage('   ');
    expect(result.isValid, isFalse);
    expect(result.errors, contains(ValidationError.onlyWhitespace));
  });

  test('rejects control chars', () {
    final result = validator.validateMessage('hi\u0001there');
    expect(result.isValid, isFalse);
    expect(result.errors, contains(ValidationError.invalidCharacters));
  });

  test('rejects injection-like content', () {
    final result = validator.validateMessage('<script>alert(1)</script>');
    expect(result.isValid, isFalse);
    expect(result.errors, contains(ValidationError.potentialInjection));
  });

  test('sanitize removes control and trims', () {
    final out = validator.sanitize('  hi\u0001\tthere  ');
    expect(out, 'hi there');
  });

  test('spaceId validation', () {
    final ok = validator.validateSpaceId('space-123_OK');
    expect(ok.isValid, isTrue);
    final bad = validator.validateSpaceId('space id!');
    expect(bad.isValid, isFalse);
    expect(bad.errors, contains(ValidationError.invalidFormat));
  });
}
