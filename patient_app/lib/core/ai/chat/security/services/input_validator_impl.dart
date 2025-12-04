import 'package:patient_app/core/ai/chat/security/interfaces/input_validator.dart';
import 'package:patient_app/core/ai/chat/security/models/validation_result.dart';

/// Basic input validator for chat content and space identifiers.
class InputValidatorImpl implements InputValidator {
  InputValidatorImpl({
    this.minLength = 1,
    this.maxLength = 10000,
  });

  final int minLength;
  final int maxLength;

  static final RegExp _controlChars = RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F]');
  static final RegExp _possibleInjection = RegExp(r'(<script|</script|--|\b(drop|delete|insert|update)\b)', caseSensitive: false);
  static final RegExp _spaceIdPattern = RegExp(r'^[a-zA-Z0-9_-]+$');

  @override
  ValidationResult validateMessage(String message) {
    final errors = <ValidationError>[];
    final trimmed = message.trim();

    if (trimmed.isEmpty) {
      errors.add(ValidationError.onlyWhitespace);
    }
    if (message.length < minLength) {
      errors.add(ValidationError.tooShort);
    }
    if (message.length > maxLength) {
      errors.add(ValidationError.tooLong);
    }
    if (_controlChars.hasMatch(message)) {
      errors.add(ValidationError.invalidCharacters);
    }
    if (_possibleInjection.hasMatch(message)) {
      errors.add(ValidationError.potentialInjection);
    }

    if (errors.isEmpty) {
      return const ValidationResult(isValid: true);
    }
    return ValidationResult(
      isValid: false,
      errors: errors,
      errorMessage: 'Invalid message input',
    );
  }

  @override
  ValidationResult validateSpaceId(String spaceId) {
    final errors = <ValidationError>[];
    if (spaceId.isEmpty) {
      errors.add(ValidationError.tooShort);
    }
    if (spaceId.length > 64) {
      errors.add(ValidationError.tooLong);
    }
    if (!_spaceIdPattern.hasMatch(spaceId)) {
      errors.add(ValidationError.invalidFormat);
    }

    if (errors.isEmpty) {
      return const ValidationResult(isValid: true);
    }
    return ValidationResult(
      isValid: false,
      errors: errors,
      errorMessage: 'Invalid space id',
    );
  }

  @override
  String sanitize(String input) {
    var output = input.replaceAll(_controlChars, '');
    output = output.replaceAll(RegExp(r'\s+'), ' ').trim();
    return output;
  }
}
