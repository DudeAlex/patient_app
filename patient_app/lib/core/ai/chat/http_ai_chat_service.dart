import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';
import 'package:patient_app/core/ai/models/ai_error.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';

/// HTTP-backed AI chat service that delegates to a backend proxy.
///
/// Uses JSON payloads built from [ChatRequest] and retries retryable failures
/// with exponential backoff (1s, 2s, 4s) up to [maxRetries] attempts.
class HttpAiChatService implements AiChatService {
  HttpAiChatService({
    required this.client,
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
  });

  final http.Client client;
  final String baseUrl;
  final Duration timeout;
  final int maxRetries;

  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    final opId = AppLogger.startOperation('http_ai_chat_send');
    final uri = Uri.parse('$baseUrl/chat/send');
    final payload = request.toJson();

    int attempt = 0;
    try {
      while (true) {
        attempt++;
        try {
          final response = await client
              .post(
                uri,
                headers: const {'Content-Type': 'application/json'},
                body: jsonEncode(payload),
              )
              .timeout(timeout);

          if (response.statusCode == 200) {
            final map = jsonDecode(response.body) as Map<String, dynamic>;
            final chatResponse = _responseFromJson(map);
            await AppLogger.info(
              'AI chat response received',
              context: {
                'threadId': request.threadId,
                'spaceId': request.spaceContext.spaceId,
                'provider': chatResponse.metadata.provider,
                'latencyMs': chatResponse.metadata.latencyMs,
                'tokensUsed': chatResponse.metadata.tokensUsed,
              },
            );
            return chatResponse;
          }

          if (_isRetryableStatus(response.statusCode) && attempt < maxRetries) {
            await _backoff(attempt);
            continue;
          }

          throw AiProviderUnavailableException(
            error: AiError(
              message: 'Provider returned ${response.statusCode}',
              isRetryable: _isRetryableStatus(response.statusCode),
              code: '${response.statusCode}',
            ),
          );
        } on TimeoutException catch (e) {
          if (attempt >= maxRetries) {
            throw AiProviderUnavailableException(
              error: const AiError(
                message: 'AI chat request timed out',
                isRetryable: true,
              ),
              cause: e,
            );
          }
          await _backoff(attempt);
        } on AiServiceException {
          rethrow;
        } catch (e) {
          if (attempt >= maxRetries) {
            throw AiProviderUnavailableException(
              error: const AiError(
                message: 'Network failure contacting AI provider',
                isRetryable: true,
              ),
              cause: e,
            );
          }
          await _backoff(attempt);
        }
      }
    } finally {
      await AppLogger.endOperation(opId);
    }
  }

  @override
  Stream<ChatResponseChunk> sendMessageStream(ChatRequest request) async* {
    // Simple fallback: use the non-streaming endpoint and emit a single chunk.
    final response = await sendMessage(request);
    yield ChatResponseChunk(content: response.messageContent, isComplete: true);
  }

  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) async {
    await AppLogger.error(
      'summarizeItem called on HttpAiChatService',
      context: {'spaceId': item.spaceId, 'domainId': item.domainId},
    );
    throw AiServiceException('summarizeItem is not supported by HttpAiChatService');
  }

  ChatResponse _responseFromJson(Map<String, dynamic> map) {
    if (map.containsKey('error')) {
      final err = map['error'] as Map<String, dynamic>;
      throw AiProviderUnavailableException(
        error: AiError(
          message: err['message'] as String? ?? 'AI error',
          isRetryable: err['retryable'] as bool? ?? false,
          code: err['code'] as String?,
        ),
      );
    }

    final metadata = map['metadata'] as Map<String, dynamic>? ?? const {};
    return ChatResponse(
      messageContent: map['message'] as String? ?? '',
      actionHints: (map['actionHints'] as List?)?.cast<String>() ?? const [],
      metadata: AiMessageMetadata(
        tokensUsed: metadata['tokensUsed'] as int? ?? 0,
        latencyMs: metadata['latencyMs'] as int? ?? 0,
        provider: metadata['provider'] as String? ?? 'remote',
        confidence: (metadata['confidence'] as num?)?.toDouble() ?? 0.0,
      ),
    );
  }

  bool _isRetryableStatus(int status) => status == 408 || status >= 500;

  Future<void> _backoff(int attempt) async {
    final delaySeconds = attempt >= 3 ? 4 : (1 << (attempt - 1));
    await Future<void>.delayed(Duration(seconds: delaySeconds));
  }
}
