/// Reasons why input validation can fail.
enum ValidationError {
  tooLong,
  tooShort,
  onlyWhitespace,
  invalidCharacters,
  potentialInjection,
  invalidFormat,
}

/// Result of validating input.
class ValidationResult {
  const ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.errors = const [],
  });

  final bool isValid;
  final String? errorMessage;
  final List<ValidationError> errors;
}
