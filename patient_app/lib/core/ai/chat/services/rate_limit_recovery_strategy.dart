import 'dart:async';

import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/config/recovery_config.dart';
import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/services/error_recovery_strategy.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';

/// Recovery strategy for rate limit errors.
class RateLimitRecoveryStrategy implements ErrorRecoveryStrategy {
  @override
  String get strategyName => 'RateLimitRecoveryStrategy';

  @override
  Future<ChatResponse> recover(
    ChatRequest request,
    AiServiceException error,
    int attemptNumber,
    AiChatService service,
  ) async {
    if (error is! RateLimitException) {
      throw ArgumentError('RateLimitRecoveryStrategy can only recover RateLimitException');
    }

    final delay = getRetryDelay(attemptNumber);
    final context = {
      'strategy': strategyName,
      'attemptNumber': attemptNumber,
      'delayMs': delay.inMilliseconds,
      'error': error.message,
    };

    await AppLogger.info('Attempting rate limit recovery', context: context);

    // Wait for the specified delay before retrying
    await Future<void>.delayed(delay);

    // Retry the request with the service
    return await service.sendMessage(request);
  }

  @override
  bool canRecover(AiServiceException error) {
    return error is RateLimitException;
  }

  @override
  Duration getRetryDelay(int attemptNumber) {
    // Use the delay from the error if available, otherwise use configured delays
    // For the base implementation, we'll return a fixed delay based on attempt number
    if (attemptNumber == 1) {
      return RecoveryConfig.firstRetryDelay;
    } else if (attemptNumber == 2) {
      return RecoveryConfig.secondRetryDelay;
    } else {
      // For subsequent attempts, return the max rate limit wait
      return RecoveryConfig.maxRateLimitWait;
    }
  }
}