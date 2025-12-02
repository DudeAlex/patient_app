import 'dart:async';

import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/services/error_recovery_strategy.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';

/// Recovery strategy for server errors - no retry, immediate fallback.
class ServerErrorRecoveryStrategy implements ErrorRecoveryStrategy {
  @override
  String get strategyName => 'ServerErrorRecoveryStrategy';

  @override
  Future<ChatResponse> recover(
    ChatRequest request,
    AiServiceException error,
    int attemptNumber,
    AiChatService service,
  ) async {
    if (error is! ServerException) {
      throw ArgumentError('ServerErrorRecoveryStrategy can only recover ServerException');
    }

    final context = {
      'strategy': strategyName,
      'attemptNumber': attemptNumber,
      'error': error.message,
    };

    await AppLogger.info('Server error recovery - no retry, immediate fallback', context: context);

    // For server errors, we don't retry as the issue is likely on the server side
    // and retrying may overwhelm the server. Instead, we throw the error to trigger fallback.
    throw error;
  }

  @override
  bool canRecover(AiServiceException error) {
    // Allow fallback to be handled by the resilient service instead of retrying.
    return false;
  }

  @override
  Duration getRetryDelay(int attemptNumber) {
    // No delay needed as we don't retry for server errors
    return Duration.zero;
  }
}
