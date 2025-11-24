import 'dart:async';

import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/models/ai_call_log_entry.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/ai/repositories/ai_call_log_repository.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';

/// Decorator that adds diagnostic logging around AI chat operations.
///
/// Message content is intentionally excluded from logs to avoid leaking PHI.
class LoggingAiChatService implements AiChatService {
  LoggingAiChatService(
    this._delegate, {
    AiCallLogRepository? callLogRepository,
  }) : _callLogRepository = callLogRepository;

  final AiChatService _delegate;
  final AiCallLogRepository? _callLogRepository;

  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    final opId = AppLogger.startOperation('ai_chat_send');
    final context = _contextFor(request);

    await AppLogger.info(
      'AI chat send started',
      context: context,
      correlationId: opId,
    );

    try {
      final response = await _delegate.sendMessage(request);
      await AppLogger.info(
        'AI chat send completed',
        context: {
          ...context,
          'provider': response.metadata.provider,
          'latencyMs': response.metadata.latencyMs,
          'tokensUsed': response.metadata.tokensUsed,
        },
        correlationId: opId,
      );
      _callLogRepository?.add(
        AiCallLogEntry(
          timestamp: DateTime.now(),
          spaceId: request.spaceContext.spaceId,
          domainId: 'chat',
          provider: response.metadata.provider,
          latencyMs: response.metadata.latencyMs,
          tokensUsed: response.metadata.tokensUsed,
          confidence: response.metadata.confidence,
          success: true,
        ),
      );
      return response;
    } catch (error, stackTrace) {
      await AppLogger.error(
        'AI chat send failed',
        error: error,
        stackTrace: stackTrace,
        context: context,
        correlationId: opId,
      );
      _callLogRepository?.add(
        AiCallLogEntry(
          timestamp: DateTime.now(),
          spaceId: request.spaceContext.spaceId,
          domainId: 'chat',
          provider: 'chat',
          latencyMs: 0,
          tokensUsed: 0,
          confidence: 0,
          success: false,
          errorMessage: error.toString(),
        ),
      );
      rethrow;
    } finally {
      await AppLogger.endOperation(opId);
    }
  }

  @override
  Stream<ChatResponseChunk> sendMessageStream(ChatRequest request) async* {
    final opId = AppLogger.startOperation('ai_chat_stream');
    final context = _contextFor(request);

    await AppLogger.info(
      'AI chat stream started',
      context: context,
      correlationId: opId,
    );

    try {
      await for (final chunk in _delegate.sendMessageStream(request)) {
        yield chunk;
        if (chunk.isComplete) {
          await AppLogger.info(
            'AI chat stream completed',
            context: context,
            correlationId: opId,
          );
        }
      }
    } catch (error, stackTrace) {
      await AppLogger.error(
        'AI chat stream failed',
        error: error,
        stackTrace: stackTrace,
        context: context,
        correlationId: opId,
      );
      rethrow;
    } finally {
      await AppLogger.endOperation(opId);
    }
  }

  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) {
    // Defer to delegate so logging stays consistent with wrapped implementation.
    return _delegate.summarizeItem(item);
  }

  Map<String, dynamic> _contextFor(ChatRequest request) {
    return {
      'threadId': request.threadId,
      'spaceId': request.spaceContext.spaceId,
      'persona': request.spaceContext.persona.name,
      'attachmentTypes': request.attachments.map((a) => a.type.name).toList(),
      'historyCount': request.messageHistory.length,
    };
  }
}
