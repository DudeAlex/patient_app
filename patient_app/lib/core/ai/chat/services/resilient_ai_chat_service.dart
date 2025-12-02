import 'dart:async';

import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/config/recovery_config.dart';
import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/services/error_classifier.dart';
import 'package:patient_app/core/ai/chat/services/error_recovery_strategy.dart';
import 'package:patient_app/core/ai/chat/services/fallback_service.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';
import 'package:patient_app/core/logging/app_logger.dart';

/// A resilient wrapper around an AI chat service that provides automatic error recovery
/// and fallback mechanisms when the primary service fails.
class ResilientAiChatService implements AiChatService {
  final AiChatService _primaryService;
  final ErrorClassifier _errorClassifier;
  final FallbackService _fallbackService;
  final List<ErrorRecoveryStrategy> _recoveryStrategies;

  /// Creates a [ResilientAiChatService] with the specified primary service and recovery components.
  ResilientAiChatService({
    required AiChatService primaryService,
    required ErrorClassifier errorClassifier,
    required FallbackService fallbackService,
    required List<ErrorRecoveryStrategy> recoveryStrategies,
  })  : _primaryService = primaryService,
        _errorClassifier = errorClassifier,
        _fallbackService = fallbackService,
        _recoveryStrategies = recoveryStrategies;

  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    final startTime = DateTime.now();
    
    // Try the primary service first
    try {
      AppLogger.log('ResilientAiChatService: Attempting primary service call',
          tags: ['ai_chat', 'resilient_service']);
      
      final response = await _primaryService.sendMessage(request);
      AppLogger.log('ResilientAiChatService: Primary service call successful',
          tags: ['ai_chat', 'resilient_service']);
      return response;
    } on AiServiceException catch (error) {
      AppLogger.log('ResilientAiChatService: Primary service failed, attempting recovery',
          tags: ['ai_chat', 'resilient_service'], error: error);
      
      // Attempt recovery with available strategies
      final response = await _attemptRecovery(request, error, startTime);
      return response;
    } catch (error) {
      AppLogger.log('ResilientAiChatService: Unexpected error, attempting recovery',
          tags: ['ai_chat', 'resilient_service'], error: error);
      
      // If it's not an AiServiceException, wrap it in a generic exception
      final aiException = AiServiceException('Unexpected error occurred: ${error.toString()}');
      final response = await _attemptRecovery(request, aiException, startTime);
      return response;
    }
  }

  /// Attempts to recover from an error using available recovery strategies.
  Future<ChatResponse> _attemptRecovery(
    ChatRequest request,
    AiServiceException error,
    DateTime startTime,
  ) async {
    final errorType = _errorClassifier.classify(error);
    AppLogger.log('ResilientAiChatService: Classified error as $errorType',
        tags: ['ai_chat', 'resilient_service']);

    // Try each recovery strategy up to the maximum number of attempts
    for (int attempt = 1; attempt <= RecoveryConfig.maxRecoveryAttempts; attempt++) {
      // Check if we've exceeded the total recovery time
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed >= RecoveryConfig.maxRecoveryTime) {
        AppLogger.log(
          'ResilientAiChatService: Exceeded maximum recovery time (${RecoveryConfig.maxRecoveryTime}), using fallback',
          tags: ['ai_chat', 'resilient_service'],
        );
        return _fallback(request, error);
      }

      AppLogger.log('ResilientAiChatService: Recovery attempt $attempt of ${RecoveryConfig.maxRecoveryAttempts}',
          tags: ['ai_chat', 'resilient_service']);

      // Find an appropriate strategy for this error type
      final strategy = _selectRecoveryStrategy(error);
      if (strategy == null) {
        AppLogger.log(
          'ResilientAiChatService: No suitable recovery strategy found, using fallback',
          tags: ['ai_chat', 'resilient_service'],
        );
        return _fallback(request, error);
      }

      AppLogger.log(
        'ResilientAiChatService: Using recovery strategy: ${strategy.strategyName}',
        tags: ['ai_chat', 'resilient_service'],
      );

      try {
        // Apply delay before attempting recovery
        final delay = strategy.getRetryDelay(attempt);
        await Future.delayed(delay);

        // Attempt recovery
        final response = await strategy.recover(request, error, attempt, _primaryService);
        
        AppLogger.log(
          'ResilientAiChatService: Recovery attempt $attempt successful',
          tags: ['ai_chat', 'resilient_service'],
        );
        
        return response;
      } on AiServiceException catch (recoveryError) {
        AppLogger.log(
          'ResilientAiChatService: Recovery attempt $attempt failed',
          tags: ['ai_chat', 'resilient_service'],
          error: recoveryError,
        );
        
        // Update the error for the next attempt
        error = recoveryError;
      } catch (recoveryError) {
        AppLogger.log(
          'ResilientAiChatService: Recovery attempt $attempt failed with unexpected error',
          tags: ['ai_chat', 'resilient_service'],
          error: recoveryError,
        );
        
        // Wrap the error and continue
        error = AiServiceException('Recovery failed: ${recoveryError.toString()}');
      }
    }

    // All recovery attempts failed, use fallback
    AppLogger.log(
      'ResilientAiChatService: All recovery attempts failed, using fallback',
      tags: ['ai_chat', 'resilient_service'],
    );
    return _fallback(request, error);
  }

  /// Selects the most appropriate recovery strategy for the given error.
  ErrorRecoveryStrategy? _selectRecoveryStrategy(AiServiceException error) {
    for (final strategy in _recoveryStrategies) {
      if (strategy.canRecover(error)) {
        return strategy;
      }
    }
    return null;
  }

  /// Generates a fallback response when all recovery attempts fail.
  Future<ChatResponse> _fallback(ChatRequest request, AiServiceException error) async {
    AppLogger.log(
      'ResilientAiChatService: Generating fallback response',
      tags: ['ai_chat', 'resilient_service'],
    );
    
    final response = _fallbackService.generateFallbackResponse(request, error);
    return response;
  }

  @override
  Stream<ChatResponseChunk> sendMessageStream(ChatRequest request) {
    // For now, we'll delegate to the primary service for streaming
    // In a more complete implementation, we'd need to add resilience to streaming as well
    return _primaryService.sendMessageStream(request);
  }

  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) {
    // Delegate to the primary service for non-chat operations
    return _primaryService.summarizeItem(item);
  }
}