import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';
import 'package:patient_app/core/ai/models/ai_error.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';
import 'package:uuid/uuid.dart';

/// HTTP-backed AI chat service that delegates to a backend proxy.
///
/// Uses JSON payloads built from [ChatRequest] and retries retryable failures
/// with exponential backoff (1s, 2s, 4s) up to [maxRetries] attempts.
class HttpAiChatService implements AiChatService {
  HttpAiChatService({
    required this.client,
    required this.baseUrl,
    this.timeout = const Duration(seconds: 60),
    this.maxRetries = 3,
    Connectivity? connectivity,
    Future<List<ConnectivityResult>> Function()? connectivityCheck,
    this.backoffCalculator,
    this.backoffObserver,
  })  : _connectivityCheck =
            connectivityCheck ?? (() => (connectivity ?? Connectivity()).checkConnectivity());

  final http.Client client;
  final String baseUrl;
  final Duration timeout;
  final int maxRetries;
  final Future<List<ConnectivityResult>> Function() _connectivityCheck;
  final Uuid _uuid = const Uuid();
  final Random _random = Random();
  final Duration Function(int attempt)? backoffCalculator;
  final void Function(Duration delay)? backoffObserver;

  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    await _ensureOnline();
    final correlationId = _uuid.v4();
    final opId = AppLogger.startOperation('http_ai_chat_send');
    final uri = _buildEchoUri();
    final payload = request.toJson();

    int attempt = 0;
    try {
      while (attempt < maxRetries) {
        attempt++;
        final stopwatch = Stopwatch()..start();
        try {
          await AppLogger.info(
            'Sending chat request',
            context: {
              'correlationId': correlationId,
              'threadId': request.threadId,
              'endpoint': uri.toString(),
              'attempt': attempt,
              'messageLength': request.messageContent.length,
              'attachments': request.attachments.length,
              'stage': 1,
            },
            correlationId: correlationId,
          );

          final response = await client
              .post(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'X-Correlation-ID': correlationId,
                  'X-Stage': '1',
                },
                body: jsonEncode(payload),
              )
              .timeout(timeout);
          stopwatch.stop();

          final latency = stopwatch.elapsedMilliseconds;
          final exception = _mapError(response);
          if (exception == null) {
            final map = jsonDecode(response.body) as Map<String, dynamic>;
            final chatResponse = _responseFromJson(map);
            await AppLogger.info(
              'AI chat response received',
              context: {
                'correlationId': correlationId,
                'threadId': request.threadId,
                'provider': chatResponse.metadata.provider,
                'latencyMs': latency,
                'tokensUsed': chatResponse.metadata.tokensUsed,
              },
              correlationId: correlationId,
            );
            return chatResponse;
          }

          await AppLogger.warning(
            'Chat request returned non-success status',
            context: {
              'correlationId': correlationId,
              'threadId': request.threadId,
              'statusCode': response.statusCode,
              'retryable': exception.isRetryable,
              'attempt': attempt,
            },
            correlationId: correlationId,
          );

          await _handleRetryable(
            exception,
            attempt,
            correlationId: correlationId,
          );
        } on TimeoutException catch (e, stackTrace) {
          final timeoutException = ChatTimeoutException(
            timeout: timeout,
            cause: e,
          );
          await AppLogger.error(
            'Chat request timed out',
            error: timeoutException,
            stackTrace: stackTrace,
            context: {'correlationId': correlationId, 'attempt': attempt},
            correlationId: correlationId,
          );
          await _handleRetryable(
            timeoutException,
            attempt,
            correlationId: correlationId,
          );
        } on SocketException catch (e, stackTrace) {
          final networkException = NetworkException(cause: e);
          await AppLogger.error(
            'Network failure contacting AI provider',
            error: networkException,
            stackTrace: stackTrace,
            context: {'correlationId': correlationId, 'attempt': attempt},
            correlationId: correlationId,
          );
          await _handleRetryable(
            networkException,
            attempt,
            correlationId: correlationId,
          );
        } on ChatException catch (e, stackTrace) {
          await AppLogger.error(
            'Chat request failed',
            error: e,
            stackTrace: stackTrace,
            context: {
              'correlationId': correlationId,
              'attempt': attempt,
              'retryable': e.isRetryable,
            },
            correlationId: correlationId,
          );
          await _handleRetryable(
            e,
            attempt,
            correlationId: correlationId,
          );
        } catch (e, stackTrace) {
          await AppLogger.error(
            'Unexpected chat request failure',
            error: e,
            stackTrace: stackTrace,
            context: {'correlationId': correlationId, 'attempt': attempt},
            correlationId: correlationId,
          );
          throw ServerException(
            message: 'Unexpected failure sending chat message',
            retryable: false,
            cause: e,
          );
        }
      }

      throw ServerException(
        message: 'Exhausted retries for chat request',
        retryable: false,
      );
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

  Future<void> _ensureOnline() async {
    final results = await _connectivityCheck();
    if (results.every((result) => result == ConnectivityResult.none)) {
      throw NetworkException();
    }
  }

  Uri _buildEchoUri() {
    final base = Uri.parse(baseUrl);
    return base.resolve('/api/v1/chat/message');
  }

  ChatResponse _responseFromJson(Map<String, dynamic> map) {
    if (map.containsKey('error')) {
      final err = map['error'] as Map<String, dynamic>;
      final retryable = err['retryable'] as bool? ?? false;
      final message = err['message'] as String? ?? 'AI error';
      throw ServerException(
        message: message,
        retryable: retryable,
        error: AiError(
          message: message,
          isRetryable: retryable,
          code: err['code'] as String?,
        ),
      );
    }

    final metadata = map['metadata'] as Map<String, dynamic>? ?? const {};
    
    // Parse metadata with backward compatibility for different field names
    final tokenUsage = metadata['tokenUsage'] as Map<String, dynamic>?;
    final tokensUsed =
        tokenUsage?['total'] as int? ?? metadata['tokensUsed'] as int? ?? 0;
    final latencyMs =
        metadata['processingTimeMs'] as int? ?? metadata['latencyMs'] as int? ?? 0;
    final provider =
        metadata['llmProvider'] as String? ?? metadata['provider'] as String? ?? 'remote';
    final confidence = (metadata['confidence'] as num?)?.toDouble() ?? 0.0;
    final finishReason = metadata['finishReason'] as String?;
    final modelVersion = metadata['modelVersion'] as String?;
    
    // Build normalized metadata map for fromJson
    final normalizedMetadata = {
      'tokensUsed': tokensUsed,
      'latencyMs': latencyMs,
      'provider': provider,
      'confidence': confidence,
      if (finishReason != null) 'finishReason': finishReason,
      if (modelVersion != null) 'modelVersion': modelVersion,
      if (metadata['contextStats'] != null) 'contextStats': metadata['contextStats'],
    };

    return ChatResponse(
      messageContent: map['message'] as String? ?? '',
      actionHints: (map['actionHints'] as List?)?.cast<String>() ?? const [],
      metadata: AiMessageMetadata.fromJson(normalizedMetadata),
    );
  }

  Future<void> _handleRetryable(
    ChatException exception,
    int attempt, {
    required String correlationId,
  }) async {
    if (exception.isRetryable && attempt < maxRetries) {
      await _backoff(
        attempt: attempt,
        correlationId: correlationId,
        override: exception.retryAfter,
      );
      return;
    }
    throw exception;
  }

  ChatException? _mapError(http.Response response) {
    if (response.statusCode == 200) {
      return null;
    }

    final retryAfter = _parseRetryAfter(response.headers['retry-after']);
    final message = _extractErrorMessage(response.body) ??
        'Provider returned ${response.statusCode}';
    if (response.statusCode == 429) {
      return RateLimitException(
        message: message,
        retryAfter: retryAfter,
        error: AiError(
          message: message,
          isRetryable: true,
          code: '${response.statusCode}',
        ),
      );
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      return UnauthorizedException(
        message: message,
        error: AiError(
          message: message,
          isRetryable: false,
          code: '${response.statusCode}',
        ),
      );
    }
    if (response.statusCode >= 500 || response.statusCode == 408) {
      return ServerException(
        message: message,
        retryable: true,
        error: AiError(
          message: message,
          isRetryable: true,
          code: '${response.statusCode}',
        ),
      );
    }
    if (response.statusCode >= 400) {
      return ValidationException(
        message: message,
        error: AiError(
          message: message,
          isRetryable: false,
          code: '${response.statusCode}',
        ),
      );
    }

    return ServerException(
      message: 'Unexpected status code ${response.statusCode}',
      retryable: false,
      error: AiError(
        message: message,
        isRetryable: false,
        code: '${response.statusCode}',
      ),
    );
  }

  Duration? _parseRetryAfter(String? header) {
    if (header == null) return null;
    final seconds = int.tryParse(header);
    if (seconds != null) return Duration(seconds: seconds);
    final date = DateTime.tryParse(header);
    if (date == null) return null;
    final diff = date.difference(DateTime.now());
    return diff.isNegative ? null : diff;
  }

  String? _extractErrorMessage(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      final error = map['error'];
      if (error is Map<String, dynamic>) {
        return error['message'] as String?;
      }
      return map['message'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _backoff({
    required int attempt,
    required String correlationId,
    Duration? override,
  }) async {
    final baseDelays = <int>[1, 2, 4];
    final base = baseDelays[min(attempt - 1, baseDelays.length - 1)];
    final delay = override ??
        backoffCalculator?.call(attempt) ??
        Duration(
          milliseconds:
              (base * (1 + (_random.nextDouble() * 0.4 - 0.2)) * 1000).round(),
        );
    backoffObserver?.call(delay);
    await AppLogger.info(
      'Backing off before retry',
      context: {
        'correlationId': correlationId,
        'attempt': attempt,
        'delayMs': delay.inMilliseconds,
      },
      correlationId: correlationId,
    );
    await Future<void>.delayed(delay);
  }
}
