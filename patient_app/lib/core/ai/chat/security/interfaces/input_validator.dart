import 'package:patient_app/core/ai/chat/security/models/validation_result.dart';

/// Interface for validating and sanitizing user input.
abstract class InputValidator {
  ValidationResult validateMessage(String message);

  ValidationResult validateSpaceId(String spaceId);

  /// Lightweight sanitization for logs or downstream processing.
  String sanitize(String input);
}
