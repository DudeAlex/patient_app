import 'dart:async';

import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/config/recovery_config.dart';
import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/models/context_stats.dart';
import 'package:patient_app/core/ai/chat/services/error_classifier.dart';
import 'package:patient_app/core/ai/chat/services/error_recovery_strategy.dart';
import 'package:patient_app/core/ai/chat/services/fallback_service.dart';
import 'package:patient_app/core/ai/chat/telemetry/interfaces/telemetry_collector.dart';
import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';

/// A resilient wrapper around an AI chat service that provides automatic error recovery
/// and fallback mechanisms when the primary service fails.
class ResilientAiChatService implements AiChatService {
  final AiChatService _primaryService;
  final ErrorClassifier _errorClassifier;
  final FallbackService _fallbackService;
  final List<ErrorRecoveryStrategy> _recoveryStrategies;
  final TelemetryCollector? _telemetryCollector;

  /// Creates a [ResilientAiChatService] with the specified primary service and recovery components.
  ResilientAiChatService({
    required AiChatService primaryService,
    required ErrorClassifier errorClassifier,
    required FallbackService fallbackService,
    required List<ErrorRecoveryStrategy> recoveryStrategies,
    TelemetryCollector? telemetryCollector,
  })  : _primaryService = primaryService,
        _errorClassifier = errorClassifier,
        _fallbackService = fallbackService,
        _recoveryStrategies = recoveryStrategies,
        _telemetryCollector = telemetryCollector;

  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    final startTime = DateTime.now();
    final totalStopwatch = Stopwatch()..start();
    final correlationId = request.threadId;
    final opId = AppLogger.startOperation('resilient_ai_chat_request');
    final telemetryRequestId = _telemetryCollector?.startRequest(
      userId: _userIdFor(request),
      spaceId: request.spaceContext.spaceId,
      messageId: _messageIdFor(request),
    );
    
    // Try the primary service first
    try {
      await AppLogger.info(
        'ResilientAiChatService: Attempting primary service call',
        context: {'threadId': request.threadId},
        correlationId: correlationId,
      );
      
      final response = await _primaryService.sendMessage(request);
      totalStopwatch.stop();
      await _recordTelemetryCompletion(
        requestId: telemetryRequestId,
        request: request,
        response: response,
        totalLatency: totalStopwatch.elapsed,
      );
      await AppLogger.info(
        'ResilientAiChatService: Primary service call successful',
        context: {'threadId': request.threadId},
        correlationId: correlationId,
      );
      return response;
    } on AiServiceException catch (error) {
      await AppLogger.warning(
        'ResilientAiChatService: Primary service failed, attempting recovery',
        context: {
          'threadId': request.threadId,
          'error': error.message,
        },
        correlationId: correlationId,
      );
      
      await _recordTelemetryError(
        requestId: telemetryRequestId,
        errorType: _errorClassifier.classify(error).name,
        message: error.message,
      );

      // Attempt recovery with available strategies
      final response = await _attemptRecovery(request, error, startTime, correlationId);
      totalStopwatch.stop();
      await _recordTelemetryCompletion(
        requestId: telemetryRequestId,
        request: request,
        response: response,
        totalLatency: totalStopwatch.elapsed,
      );
      return response;
    } catch (error) {
      await AppLogger.error(
        'ResilientAiChatService: Unexpected error, attempting recovery',
        error: error,
        context: {'threadId': request.threadId},
        correlationId: correlationId,
      );
      
      // If it's not an AiServiceException, wrap it in a generic exception
      final aiException = AiServiceException('Unexpected error occurred: ${error.toString()}');
      await _recordTelemetryError(
        requestId: telemetryRequestId,
        errorType: _errorClassifier.classify(aiException).name,
        message: aiException.message,
      );
      final response = await _attemptRecovery(request, aiException, startTime, correlationId);
      totalStopwatch.stop();
      await _recordTelemetryCompletion(
        requestId: telemetryRequestId,
        request: request,
        response: response,
        totalLatency: totalStopwatch.elapsed,
      );
      return response;
    } finally {
      await AppLogger.endOperation(opId);
    }
  }

  /// Attempts to recover from an error using available recovery strategies.
  Future<ChatResponse> _attemptRecovery(
    ChatRequest request,
    AiServiceException error,
    DateTime startTime,
    String correlationId,
  ) async {
    final errorType = _errorClassifier.classify(error);
    await AppLogger.info(
      'ResilientAiChatService: Classified error',
      context: {'type': errorType.name, 'threadId': request.threadId},
      correlationId: correlationId,
    );

    if (error is ChatException && !error.isRetryable) {
      await AppLogger.warning(
        'ResilientAiChatService: Error is not retryable, using fallback',
        context: {'threadId': request.threadId, 'type': errorType.name},
        correlationId: correlationId,
      );
      return _fallback(request, error, correlationId);
    }

    if (errorType == ErrorType.server || errorType == ErrorType.validation) {
      await AppLogger.warning(
        'ResilientAiChatService: Server/validation error, skipping retries and using fallback',
        context: {'threadId': request.threadId, 'type': errorType.name},
        correlationId: correlationId,
      );
      return _fallback(request, error, correlationId);
    }

    final triedStrategies = <String>{};

    // Try each recovery strategy up to the maximum number of attempts
    for (int attempt = 1; attempt <= RecoveryConfig.maxRecoveryAttempts; attempt++) {
      // Check if we've exceeded the total recovery time
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed >= RecoveryConfig.maxRecoveryTime) {
        await AppLogger.warning(
          'ResilientAiChatService: Exceeded maximum recovery time (${RecoveryConfig.maxRecoveryTime}), using fallback',
          context: {'threadId': request.threadId},
          correlationId: correlationId,
        );
        return _fallback(request, error, correlationId);
      }

      await AppLogger.info(
        'ResilientAiChatService: Recovery attempt $attempt of ${RecoveryConfig.maxRecoveryAttempts}',
        context: {'threadId': request.threadId},
        correlationId: correlationId,
      );

      // Find an appropriate strategy for this error type that we haven't tried yet
      final strategy = _selectRecoveryStrategy(error, triedStrategies);
      if (strategy == null) {
        await AppLogger.warning(
          'ResilientAiChatService: No suitable recovery strategy found, using fallback',
          context: {'threadId': request.threadId},
          correlationId: correlationId,
        );
        return _fallback(request, error, correlationId);
      }

      triedStrategies.add(strategy.strategyName);

      await AppLogger.info(
        'ResilientAiChatService: Using recovery strategy: ${strategy.strategyName}',
        context: {'threadId': request.threadId, 'strategy': strategy.strategyName},
        correlationId: correlationId,
      );

      try {
        // Attempt recovery
        final response = await strategy.recover(request, error, attempt, _primaryService);
        
        await AppLogger.info(
          'ResilientAiChatService: Recovery attempt $attempt successful',
          context: {'threadId': request.threadId, 'strategy': strategy.strategyName},
          correlationId: correlationId,
        );
        
        return response;
      } on AiServiceException catch (recoveryError) {
        await AppLogger.warning(
          'ResilientAiChatService: Recovery attempt $attempt failed',
          context: {
            'threadId': request.threadId,
            'strategy': strategy.strategyName,
            'error': recoveryError.message,
          },
          correlationId: correlationId,
        );
        
        // Update the error for the next attempt
        error = recoveryError;
      } catch (recoveryError) {
        await AppLogger.error(
          'ResilientAiChatService: Recovery attempt $attempt failed with unexpected error',
          error: recoveryError,
          context: {
            'threadId': request.threadId,
            'strategy': strategy.strategyName,
          },
          correlationId: correlationId,
        );
        
        // Wrap the error and continue
        error = AiServiceException('Recovery failed: ${recoveryError.toString()}');
      }
    }

    // All recovery attempts failed, use fallback
    await AppLogger.warning(
      'ResilientAiChatService: All recovery attempts failed, using fallback',
      context: {'threadId': request.threadId},
      correlationId: correlationId,
    );
    return _fallback(request, error, correlationId);
  }

  /// Selects the most appropriate recovery strategy for the given error.
  ErrorRecoveryStrategy? _selectRecoveryStrategy(
    AiServiceException error,
    Set<String> triedStrategies,
  ) {
    for (final strategy in _recoveryStrategies) {
      if (!triedStrategies.contains(strategy.strategyName) && strategy.canRecover(error)) {
        return strategy;
      }
    }
    return null;
  }

  /// Generates a fallback response when all recovery attempts fail.
  Future<ChatResponse> _fallback(
    ChatRequest request,
    AiServiceException error,
    String correlationId,
  ) async {
    await AppLogger.info(
      'ResilientAiChatService: Generating fallback response',
      context: {'threadId': request.threadId},
      correlationId: correlationId,
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

  String _userIdFor(ChatRequest request) {
    // User identity is not currently part of the chat request; use a neutral placeholder.
    return 'anonymous';
  }

  String _messageIdFor(ChatRequest request) {
    if (request.messageHistory.isNotEmpty) {
      return request.messageHistory.last.id;
    }
    return request.threadId;
  }

  Duration _contextAssemblyTime(ChatRequest request) {
    final stats = request.spaceContext.stats;
    if (stats is ContextStats) {
      return stats.assemblyTime;
    }
    return Duration.zero;
  }

  Future<void> _recordTelemetryCompletion({
    required String? requestId,
    required ChatRequest request,
    required ChatResponse response,
    required Duration totalLatency,
  }) async {
    if (_telemetryCollector == null || requestId == null) return;
    final contextAssemblyTime = _contextAssemblyTime(request);
    final llmCallTime = Duration(milliseconds: response.metadata.latencyMs);

    var promptTokens = response.metadata.promptTokens;
    var completionTokens = response.metadata.completionTokens;
    if (promptTokens == 0 && completionTokens == 0 && response.metadata.tokensUsed > 0) {
      promptTokens = response.metadata.tokensUsed;
    }

    await _telemetryCollector!.completeRequest(
      requestId: requestId,
      totalLatency: totalLatency + contextAssemblyTime,
      contextAssemblyTime: contextAssemblyTime,
      llmCallTime: llmCallTime,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      fromCache: false,
    );
  }

  Future<void> _recordTelemetryError({
    required String? requestId,
    required String errorType,
    required String message,
  }) async {
    if (_telemetryCollector == null || requestId == null) return;
    await _telemetryCollector!.recordError(
      requestId: requestId,
      errorType: errorType,
      errorMessage: message,
    );
  }
}
