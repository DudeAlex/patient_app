import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';
import 'package:patient_app/core/ai/models/ai_error.dart';

/// Base chat exception that captures retry semantics for transport-layer errors.
abstract class ChatException extends AiServiceException {
  ChatException(
    super.message, {
    required this.isRetryable,
    this.retryAfter,
    super.error,
    super.cause,
  });

  /// Indicates whether the failed operation should be retried automatically.
  final bool isRetryable;

  /// Optional server-provided delay before the next retry should be attempted.
  final Duration? retryAfter;
}

class ChatTimeoutException extends ChatException {
  ChatTimeoutException({
    Duration? timeout,
    AiError? error,
    Object? cause,
  }) : super(
          'Request timed out${timeout != null ? ' after ${timeout.inSeconds}s' : ''}',
          isRetryable: true,
          error: error,
          cause: cause,
        );
}

class NetworkException extends ChatException {
  NetworkException({
    String message = 'No internet connection detected',
    AiError? error,
    Object? cause,
  }) : super(
          message,
          isRetryable: true,
          error: error,
          cause: cause,
        );
}

class ServerException extends ChatException {
  ServerException({
    String message = 'Server error',
    bool retryable = true,
    AiError? error,
    Object? cause,
  }) : super(
          message,
          isRetryable: retryable,
          error: error,
          cause: cause,
        );
}

class RateLimitException extends ChatException {
  RateLimitException({
    String message = 'Rate limit exceeded',
    Duration? retryAfter,
    AiError? error,
    Object? cause,
  }) : super(
          message,
          isRetryable: true,
          retryAfter: retryAfter,
          error: error,
          cause: cause,
        );
}

class UnauthorizedException extends ChatException {
  UnauthorizedException({
    String message = 'Unauthorized',
    AiError? error,
    Object? cause,
  }) : super(
          message,
          isRetryable: false,
          error: error,
          cause: cause,
        );
}

class ValidationException extends ChatException {
  ValidationException({
    String message = 'Request validation failed',
    AiError? error,
    Object? cause,
  }) : super(
          message,
          isRetryable: false,
          error: error,
          cause: cause,
        );
}
