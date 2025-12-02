import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/models/ai_message_metadata.dart';

/// Service that provides fallback responses when primary AI services fail.
class FallbackService {
  /// Creates a [FallbackService] instance.
  FallbackService();

  /// Generates a fallback response based on the error type and request.
  ChatResponse generateFallbackResponse(ChatRequest request, AiServiceException error) {
    final errorMessage = _generateFallbackMessage(error, request.spaceContext.spaceId);
    
    return ChatResponse(
      messageContent: errorMessage,
      actionHints: _getActionHints(error),
      metadata: AiMessageMetadata(
        tokensUsed: errorMessage.length ~/ 4, // Rough estimation
        latencyMs: 0,
        provider: 'fallback',
        isFallback: true,
      ),
    );
  }

  /// Generates a user-friendly error message based on the error type.
  String _generateFallbackMessage(AiServiceException error, String spaceId) {
    final errorType = _getErrorType(error);
    
    switch (errorType) {
      case ErrorType.network:
        return _getNetworkErrorMessage(spaceId);
      case ErrorType.rateLimit:
        return _getRateLimitErrorMessage(spaceId);
      case ErrorType.timeout:
        return _getTimeoutErrorMessage(spaceId);
      case ErrorType.server:
        return _getServerErrorMessage(spaceId);
      case ErrorType.validation:
      case ErrorType.unknown:
      default:
        return _getGenericErrorMessage(spaceId);
    }
  }

  /// Determines the error type from the exception.
  ErrorType _getErrorType(AiServiceException error) {
    if (error is RateLimitException) {
      return ErrorType.rateLimit;
    } else if (error is NetworkException) {
      return ErrorType.network;
    } else if (error is ServerException) {
      return ErrorType.server;
    } else if (error is ChatTimeoutException) {
      return ErrorType.timeout;
    } else if (error is ValidationException) {
      return ErrorType.validation;
    } else {
      return ErrorType.unknown;
    }
  }

  /// Gets action hints based on the error type.
  List<String> _getActionHints(AiServiceException error) {
    final errorType = _getErrorType(error);
    
    switch (errorType) {
      case ErrorType.network:
        return ['Check your internet connection', 'Try again in a moment'];
      case ErrorType.rateLimit:
        return ['Wait a bit before sending more messages', 'Try again soon'];
      case ErrorType.timeout:
        return ['Try your request again', 'Keep your message shorter'];
      case ErrorType.server:
        return ['Try again in a few minutes', 'Your message is saved'];
      case ErrorType.validation:
      case ErrorType.unknown:
      default:
        return ['Try rephrasing your message', 'Try again later'];
    }
  }

  // Error-specific message generation methods
  String _getNetworkErrorMessage(String spaceId) {
    switch (spaceId.toLowerCase()) {
      case 'health':
        return "I can't access your health records right now. Please check your internet connection and try again.";
      case 'finance':
        return "I can't access your financial records right now. Please check your internet connection and try again.";
      case 'education':
        return "I can't access your study materials right now. Please check your internet connection and try again.";
      case 'travel':
        return "I can't access your travel plans right now. Please check your internet connection and try again.";
      default:
        return "I can't connect right now. Please check your internet connection and try again.";
    }
  }

  String _getRateLimitErrorMessage(String spaceId) {
    switch (spaceId.toLowerCase()) {
      case 'health':
        return "I'm receiving too many health-related requests right now. Please wait a moment before asking more questions about your health.";
      case 'finance':
        return "I'm receiving too many finance-related requests right now. Please wait a moment before asking more questions about your finances.";
      case 'education':
        return "I'm receiving too many study-related requests right now. Please wait a moment before asking more questions about your studies.";
      case 'travel':
        return "I'm receiving too many travel-related requests right now. Please wait a moment before asking more questions about your travels.";
      default:
        return "I'm receiving too many requests right now. Please wait a moment and try again.";
    }
  }

  String _getTimeoutErrorMessage(String spaceId) {
    switch (spaceId.toLowerCase()) {
      case 'health':
        return "Your health-related request took too long to process. Please try again or rephrase your question about your health.";
      case 'finance':
        return "Your finance-related request took too long to process. Please try again or rephrase your question about your finances.";
      case 'education':
        return "Your study-related request took too long to process. Please try again or rephrase your question about your studies.";
      case 'travel':
        return "Your travel-related request took too long to process. Please try again or rephrase your question about your travels.";
      default:
        return "Your request took too long to process. Please try again.";
    }
  }

  String _getServerErrorMessage(String spaceId) {
    switch (spaceId.toLowerCase()) {
      case 'health':
        return "The health service is temporarily unavailable. Your health-related message is saved and I'll respond when the service is back.";
      case 'finance':
        return "The finance service is temporarily unavailable. Your finance-related message is saved and I'll respond when the service is back.";
      case 'education':
        return "The study service is temporarily unavailable. Your education-related message is saved and I'll respond when the service is back.";
      case 'travel':
        return "The travel service is temporarily unavailable. Your travel-related message is saved and I'll respond when the service is back.";
      default:
        return "The service is temporarily unavailable. Try again soon.";
    }
  }

  String _getGenericErrorMessage(String spaceId) {
    switch (spaceId.toLowerCase()) {
      case 'health':
        return "Something went wrong with your health-related request. Please try again or rephrase your question about your health.";
      case 'finance':
        return "Something went wrong with your finance-related request. Please try again or rephrase your question about your finances.";
      case 'education':
        return "Something went wrong with your study-related request. Please try again or rephrase your question about your studies.";
      case 'travel':
        return "Something went wrong with your travel-related request. Please try again or rephrase your question about your travels.";
      default:
        return "Something went wrong. Please try again.";
    }
  }
}

/// Enum representing different types of errors for fallback handling.
enum ErrorType {
  network,
  rateLimit,
  server,
  validation,
  timeout,
  unknown,
}