import 'dart:async';
import 'dart:math';

import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/config/recovery_config.dart';
import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/services/error_recovery_strategy.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';

/// Recovery strategy for rate limit errors.
class RateLimitRecoveryStrategy implements ErrorRecoveryStrategy {
  final Random _random = Random();

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

    final delay = error.retryAfter ?? getRetryDelay(attemptNumber);
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
      return _withJitter(RecoveryConfig.firstRetryDelay);
    } else if (attemptNumber == 2) {
      return _withJitter(RecoveryConfig.secondRetryDelay);
    } else {
      // For subsequent attempts, return the max rate limit wait
      return _withJitter(RecoveryConfig.maxRateLimitWait);
    }
  }

  Duration _withJitter(Duration base) {
    // Add +/-20% jitter to avoid synchronized retries
    final jitterFactor = 0.8 + _random.nextDouble() * 0.4;
    return Duration(milliseconds: (base.inMilliseconds * jitterFactor).round());
  }
}
