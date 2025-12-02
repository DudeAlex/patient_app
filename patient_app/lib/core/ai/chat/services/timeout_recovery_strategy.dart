import 'dart:async';

import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/services/error_recovery_strategy.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';

/// Recovery strategy for timeout errors - retry once with shorter timeout.
class TimeoutRecoveryStrategy implements ErrorRecoveryStrategy {
  @override
  String get strategyName => 'TimeoutRecoveryStrategy';

  @override
  Future<ChatResponse> recover(
    ChatRequest request,
    AiServiceException error,
    int attemptNumber,
    AiChatService service,
  ) async {
    if (error is! ChatTimeoutException) {
      throw ArgumentError('TimeoutRecoveryStrategy can only recover ChatTimeoutException');
    }

    final context = {
      'strategy': strategyName,
      'attemptNumber': attemptNumber,
      'error': error.message,
    };

    await AppLogger.info('Attempting timeout recovery', context: context);

    // For timeout errors, we could retry with a different approach
    // In a real implementation, we might want to reduce the maxTokens or use a different timeout
    // For now, we'll just retry the same request
    return await service.sendMessage(request);
  }

  @override
  bool canRecover(AiServiceException error) {
    return error is ChatTimeoutException;
  }

  @override
  Duration getRetryDelay(int attemptNumber) {
    // Small delay before retrying timeout errors
    return Duration(milliseconds: 500);
  }
}
