class ImportResult {
  final int successCount;
  final int failureCount;
  final List<ImportError> errors;
  final Duration duration;

  ImportResult({
    required this.successCount,
    required this.failureCount,
    required this.errors,
    required this.duration,
  });

  bool get isFullSuccess => failureCount == 0;
  bool get isPartialSuccess => successCount > 0 && failureCount > 0;
  bool get isFullFailure => successCount == 0;
}

class ImportError {
  final int recordIndex;
  final String message;
  final String? field;

  ImportError({required this.recordIndex, required this.message, this.field});
}

class ClearResult {
  final int deletedCount;
  final Duration duration;
  final bool success;
  final String? error;

  ClearResult({
    required this.deletedCount,
    required this.duration,
    required this.success,
    this.error,
  });
}

class ValidationResult {
  final bool isValid;
  final List<ValidationError> errors;

  ValidationResult({required this.isValid, required this.errors});

  bool get hasErrors => errors.isNotEmpty;
}

class ValidationError {
  final int? lineNumber;
  final String field;
  final String message;

  ValidationError({
    this.lineNumber,
    required this.field,
    required this.message,
  });
}
