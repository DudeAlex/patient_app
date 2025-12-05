import 'dart:async';

import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/security/interfaces/authentication_service.dart';
import 'package:patient_app/core/ai/chat/security/interfaces/data_redaction_service.dart';
import 'package:patient_app/core/ai/chat/security/interfaces/input_validator.dart';
import 'package:patient_app/core/ai/chat/security/interfaces/rate_limiter.dart';
import 'package:patient_app/core/ai/chat/security/interfaces/security_monitor.dart';
import 'package:patient_app/core/ai/chat/security/models/security_event.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/ai/models/ai_error.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';

typedef TokenProvider = FutureOr<String?> Function();
typedef LogSink = void Function(String message, Map<String, dynamic>? context);

/// Decorator that enforces security controls around chat requests.
class SecureAiChatService implements AiChatService {
  SecureAiChatService({
    required AiChatService inner,
    required RateLimiter rateLimiter,
    required DataRedactionService dataRedactionService,
    required InputValidator inputValidator,
    required AuthenticationService authenticationService,
    required SecurityMonitor securityMonitor,
    TokenProvider? tokenProvider,
    bool autoProvisionToken = true,
    LogSink? logSink,
  })  : _inner = inner,
        _rateLimiter = rateLimiter,
        _dataRedactionService = dataRedactionService,
        _inputValidator = inputValidator,
        _authenticationService = authenticationService,
        _securityMonitor = securityMonitor,
        _tokenProvider = tokenProvider ?? (() => null),
        _autoProvisionToken = autoProvisionToken,
        _logSink = logSink;

  final AiChatService _inner;
  final RateLimiter _rateLimiter;
  final DataRedactionService _dataRedactionService;
  final InputValidator _inputValidator;
  final AuthenticationService _authenticationService;
  final SecurityMonitor _securityMonitor;
  final TokenProvider _tokenProvider;
  final bool _autoProvisionToken;
  final LogSink? _logSink;

  String? _cachedToken;

  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    final userId = _deriveUserId(request);
    final sanitizedRequest = await _enforceGuards(userId, request);
    return _inner.sendMessage(sanitizedRequest);
  }

  @override
  Stream<ChatResponseChunk> sendMessageStream(ChatRequest request) async* {
    final userId = _deriveUserId(request);
    final sanitizedRequest = await _enforceGuards(userId, request);
    yield* _inner.sendMessageStream(sanitizedRequest);
  }

  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) {
    return _inner.summarizeItem(item);
  }

  Future<ChatRequest> _enforceGuards(String userId, ChatRequest request) async {
    // Authentication
    final token = await _ensureValidToken(userId);
    final authResult = await _authenticationService.validateToken(token);
    if (!authResult.isValid) {
      await _securityMonitor.logEvent(
        type: SecurityEventType.authenticationFailure,
        userId: userId,
        metadata: {'error': authResult.error},
      );
      throw UnauthorizedException(
        message: 'Invalid or expired token',
        error: AiError(
          message: authResult.error ?? 'Invalid token',
          isRetryable: false,
          code: authResult.error,
        ),
      );
    }

    // Rate limits (minute, hour, day)
    for (final window in RateLimitType.values) {
      final result = await _rateLimiter.checkLimit(userId: userId, type: window);
      if (!result.allowed) {
        final retryAfter = result.resetTime.difference(DateTime.now());
        await _securityMonitor.logEvent(
          type: SecurityEventType.rateLimitViolation,
          userId: userId,
          metadata: {
            'remaining': result.remaining,
            'window': window.name,
            'resetTime': result.resetTime.toIso8601String(),
          },
        );
        throw RateLimitException(
          message: result.message ?? 'Rate limit exceeded',
          retryAfter: retryAfter.isNegative ? null : retryAfter,
          error: AiError(
            message: 'Rate limit exceeded',
            isRetryable: true,
            code: '429-${window.name}',
          ),
        );
      } else if (result.isSoftLimited || result.message != null) {
        await _logInfo(
          'Rate limit warning',
          {
            'userId': userId,
            'window': window.name,
            'remaining': result.remaining,
            'resetTime': result.resetTime.toIso8601String(),
            if (result.message != null) 'message': result.message,
          },
        );
      }
    }

    // Input validation
    final validation = _inputValidator.validateMessage(request.messageContent);
    if (!validation.isValid) {
      await _securityMonitor.logEvent(
        type: SecurityEventType.inputValidationFailure,
        userId: userId,
        metadata: {
          'errors': validation.errors.map((e) => e.name).toList(),
        },
      );
      throw ValidationException(
        message: validation.errorMessage ?? 'Invalid input',
        error: AiError(
          message: validation.errorMessage ?? 'Invalid input',
          isRetryable: false,
          code: 'validation_failed',
        ),
      );
    }

    // Sanitization and redaction for logging
    final sanitizedMessage = _inputValidator.sanitize(request.messageContent);
    final redactedMessage = _dataRedactionService.redact(sanitizedMessage);
    await _logInfo(
      'Processing chat request',
      {
        'userId': userId,
        'spaceId': request.spaceContext.spaceId,
        'threadId': request.threadId,
        'messageLength': sanitizedMessage.length,
        'messagePreview': redactedMessage,
        if (_dataRedactionService.containsSensitiveData(request.messageContent))
          'piiDetected': true,
      },
    );

    // Record successful request
    await _rateLimiter.recordRequest(userId: userId);

    return ChatRequest(
      threadId: request.threadId,
      messageContent: sanitizedMessage,
      spaceContext: request.spaceContext,
      attachments: request.attachments,
      messageHistory: request.messageHistory,
      maxHistoryMessages: request.maxHistoryMessages,
      filters: request.filters,
      tokenBudget: request.tokenBudget,
    );
  }

  Future<String> _ensureValidToken(String userId) async {
    final provided = await _tokenProvider();
    if (provided != null) {
      _cachedToken = provided;
    }

    if (_cachedToken != null) {
      final result = await _authenticationService.validateToken(_cachedToken!);
      if (result.isValid) {
        return _cachedToken!;
      }
    }

    if (!_autoProvisionToken) {
      throw UnauthorizedException(message: 'Authentication required');
    }

    _cachedToken = await _authenticationService.generateToken(
      userId: userId,
      roles: const ['user'],
    );
    return _cachedToken!;
  }

  String _deriveUserId(ChatRequest request) {
    // Use a stable, non-PII identifier for rate limiting and monitoring.
    return 'user-${request.spaceContext.spaceId}';
  }

  Future<void> _logInfo(String message, Map<String, dynamic>? context) async {
    final redactedMessage = _dataRedactionService.redact(message);
    final redactedContext = context == null
        ? null
        : context.map((key, value) => MapEntry(key, _maybeRedact(value)));

    _logSink?.call(redactedMessage, redactedContext);
    await AppLogger.info(redactedMessage, context: redactedContext);
  }

  Object? _maybeRedact(Object? value) {
    if (value is String) {
      return _dataRedactionService.redact(value);
    }
    return value;
  }
}
