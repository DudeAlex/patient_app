import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';

/// Classifies AI service errors by type for appropriate recovery strategies.
class ErrorClassifier {
  /// Classifies an [AiServiceException] into an [ErrorType].
  ErrorType classify(AiServiceException exception) {
    if (exception is RateLimitException) {
      return ErrorType.rateLimit;
    } else if (exception is NetworkException) {
      return ErrorType.network;
    } else if (exception is ServerException) {
      // Check if it's a rate limit that wasn't caught by RateLimitException
      if (_isRateLimitError(exception)) {
        return ErrorType.rateLimit;
      } else if (_isNetworkError(exception)) {
        return ErrorType.network;
      }
      return ErrorType.server;
    } else if (exception is ChatTimeoutException) {
      return ErrorType.timeout;
    } else if (exception is ValidationException) {
      return ErrorType.validation;
    } else {
      // For any other exception type, try to determine the type based on message content
      return _inferErrorTypeFromMessage(exception.message);
    }
  }

  /// Determines if a ServerException represents a rate limit error.
  bool _isRateLimitError(ServerException exception) {
    final message = exception.message.toLowerCase();
    return message.contains('rate') || 
           message.contains('limit') || 
           message.contains('too many requests') ||
           message.contains('429');
  }

  /// Determines if a ServerException represents a network error.
  bool _isNetworkError(ServerException exception) {
    final message = exception.message.toLowerCase();
    return message.contains('network') ||
           message.contains('connection') ||
           message.contains('timeout') ||
           message.contains('offline') ||
           message.contains('dns') ||
           message.contains('socket');
  }

  /// Infers error type from exception message content.
  ErrorType _inferErrorTypeFromMessage(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('rate') || 
        lowerMessage.contains('limit') || 
        lowerMessage.contains('too many requests')) {
      return ErrorType.rateLimit;
    } else if (lowerMessage.contains('network') ||
               lowerMessage.contains('connection') ||
               lowerMessage.contains('offline') ||
               lowerMessage.contains('dns') ||
               lowerMessage.contains('socket')) {
      return ErrorType.network;
    } else if (lowerMessage.contains('timeout')) {
      return ErrorType.timeout;
    } else if (lowerMessage.contains('validation') ||
               lowerMessage.contains('invalid') ||
               lowerMessage.contains('bad request')) {
      return ErrorType.validation;
    } else if (lowerMessage.contains('server') ||
               lowerMessage.contains('500') ||
               lowerMessage.contains('502') ||
               lowerMessage.contains('503') ||
               lowerMessage.contains('504')) {
      return ErrorType.server;
    } else {
      return ErrorType.unknown;
    }
  }
}

/// Types of errors that can be classified for recovery purposes.
enum ErrorType {
  /// Rate limit errors (HTTP 429, "too many requests", etc.)
  rateLimit,

  /// Network connectivity errors (connection refused, timeout, etc.)
  network,

  /// Server errors (HTTP 500, 502, 503, etc.)
  server,

  /// Validation errors (HTTP 400, bad request, etc.)
  validation,

  /// Timeout errors
  timeout,

  /// Any other error type that doesn't fit the above categories
  unknown,
}