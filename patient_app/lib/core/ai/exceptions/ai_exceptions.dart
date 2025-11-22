import 'package:patient_app/core/ai/models/ai_error.dart';

/// Base exception for AI service failures.
class AiServiceException implements Exception {
  AiServiceException(this.message, {this.error, this.cause});

  final String message;
  final AiError? error;
  final Object? cause;

  @override
  String toString() => 'AiServiceException(message: $message, error: $error)';
}

/// Thrown when the user has not granted consent for AI processing.
class AiConsentRequiredException extends AiServiceException {
  AiConsentRequiredException()
      : super('AI assistance requires consent from the user');
}

/// Thrown when the AI provider fails due to network or timeout issues.
class AiProviderUnavailableException extends AiServiceException {
  AiProviderUnavailableException({AiError? error, Object? cause})
      : super('AI provider is currently unavailable', error: error, cause: cause);
}
