import 'dart:async';

import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/config/recovery_config.dart';
import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/services/error_recovery_strategy.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';

/// Recovery strategy for network errors using exponential backoff.
class NetworkRecoveryStrategy implements ErrorRecoveryStrategy {
  @override
  String get strategyName => 'NetworkRecoveryStrategy';

  @override
  Future<ChatResponse> recover(
    ChatRequest request,
    AiServiceException error,
    int attemptNumber,
    AiChatService service,
  ) async {
    if (error is! NetworkException) {
      throw ArgumentError('NetworkRecoveryStrategy can only recover NetworkException');
    }

    final delay = getRetryDelay(attemptNumber);
    final context = {
      'strategy': strategyName,
      'attemptNumber': attemptNumber,
      'delayMs': delay.inMilliseconds,
      'error': error.message,
    };

    await AppLogger.info('Attempting network error recovery', context: context);

    // Wait for the specified delay before retrying
    await Future<void>.delayed(delay);

    // Retry the request with the service
    return await service.sendMessage(request);
  }

  @override
  bool canRecover(AiServiceException error) {
    return error is NetworkException;
  }

  @override
  Duration getRetryDelay(int attemptNumber) {
    // Exponential backoff: 1s, 2s for first and second attempts
    // For subsequent attempts, use maxRateLimitWait as cap
    if (attemptNumber == 1) {
      return RecoveryConfig.firstRetryDelay; // 1 second
    } else if (attemptNumber == 2) {
      return RecoveryConfig.secondRetryDelay; // 2 seconds
    } else {
      // For subsequent attempts, return the max rate limit wait
      return RecoveryConfig.maxRateLimitWait; // 5 seconds
    }
  }
}