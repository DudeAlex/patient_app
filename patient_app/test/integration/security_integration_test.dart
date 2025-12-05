import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/chat/security/interfaces/authentication_service.dart';
import 'package:patient_app/core/ai/chat/security/interfaces/data_redaction_service.dart';
import 'package:patient_app/core/ai/chat/security/interfaces/input_validator.dart';
import 'package:patient_app/core/ai/chat/security/interfaces/rate_limiter.dart';
import 'package:patient_app/core/ai/chat/security/services/authentication_service_impl.dart';
import 'package:patient_app/core/ai/chat/security/services/data_redaction_service_impl.dart';
import 'package:patient_app/core/ai/chat/security/services/input_validator_impl.dart';
import 'package:patient_app/core/ai/chat/security/services/rate_limiter_impl.dart';
import 'package:patient_app/core/ai/chat/security/services/secure_ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/security/services/security_monitor_impl.dart';
import 'package:patient_app/core/ai/chat/security/models/rate_limit_config.dart';
import 'package:patient_app/core/ai/chat/security/models/security_event.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/ai/models/ai_error.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';

class _FakeAiChatService implements AiChatService {
  final List<ChatRequest> captured = [];

  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    captured.add(request);
    return ChatResponse.success(
      messageContent: 'ok',
      metadata: AiMessageMetadata(provider: 'fake'),
    );
  }

  @override
  Stream<ChatResponseChunk> sendMessageStream(ChatRequest request) async* {
    yield const ChatResponseChunk(content: 'ok', isComplete: true);
  }

  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) {
    return Future.value(AiSummaryResult.success(summaryText: 'summary'));
  }
}

ChatRequest _request(String message) {
  return ChatRequest(
    threadId: 'thread-1',
    messageContent: message,
    spaceContext: SpaceContext(
      spaceId: 'health',
      spaceName: 'Health',
      persona: SpacePersona.health,
      description: 'Health space',
    ),
  );
}

SecureAiChatService _buildSecureService({
  RateLimitConfig? limits,
  AuthenticationService? auth,
  TokenProvider? tokenProvider,
  bool autoProvisionToken = true,
  LogSink? logSink,
  _FakeAiChatService? inner,
}) {
  final rateLimiter = RateLimiterImpl(
    config: limits ??
        const RateLimitConfig(
          perMinute: 2,
          perHour: 10,
          perDay: 20,
        ),
  );
  final dataRedactionService = DataRedactionServiceImpl();
  final inputValidator = InputValidatorImpl();
  final authenticationService = auth ?? AuthenticationServiceImpl();
  final monitor = SecurityMonitorImpl();

  return SecureAiChatService(
    inner: inner ?? _FakeAiChatService(),
    rateLimiter: rateLimiter,
    dataRedactionService: dataRedactionService,
    inputValidator: inputValidator,
    authenticationService: authenticationService,
    securityMonitor: monitor,
    tokenProvider: tokenProvider,
    autoProvisionToken: autoProvisionToken,
    logSink: logSink,
  );
}

void main() {
  test('enforces rate limiting across requests', () async {
    final inner = _FakeAiChatService();
    final service = _buildSecureService(
      limits: const RateLimitConfig(perMinute: 2, perHour: 5, perDay: 5),
      inner: inner,
    );

    await service.sendMessage(_request('hello'));
    await service.sendMessage(_request('world'));
    expect(() => service.sendMessage(_request('blocked')), throwsA(isA<RateLimitException>()));
    expect(inner.captured.length, 2);
  });

  test('rejects invalid input and sanitizes valid input', () async {
    final service = _buildSecureService();
    expect(
      () => service.sendMessage(_request('DROP TABLE users;')),
      throwsA(isA<ValidationException>()),
    );

    final inner = _FakeAiChatService();
    final secure = _buildSecureService(inner: inner);
    await secure.sendMessage(_request('  neat message  '));
    expect(inner.captured.single.messageContent, 'neat message');
  });

  test('authenticates tokens and rejects expired ones', () async {
    DateTime now = DateTime(2025, 1, 1, 12, 0, 0);
    final auth = AuthenticationServiceImpl(
      secret: 'secret',
      tokenExpiry: const Duration(minutes: 1),
      clock: () => now,
    );
    final validToken = await auth.generateToken(userId: 'user-1');

    final secure = _buildSecureService(
      auth: auth,
      tokenProvider: () => validToken,
      autoProvisionToken: false,
    );
    await secure.sendMessage(_request('valid'));

    now = now.add(const Duration(minutes: 2));
    final secureExpired = _buildSecureService(
      auth: auth,
      tokenProvider: () => validToken,
      autoProvisionToken: false,
    );
    expect(() => secureExpired.sendMessage(_request('expired')), throwsA(isA<UnauthorizedException>()));
  });

  test('redacts PII in logs', () async {
    String? loggedMessage;
    Map<String, dynamic>? loggedContext;
    final service = _buildSecureService(
      logSink: (msg, ctx) {
        loggedMessage = msg;
        loggedContext = ctx;
      },
    );
    await service.sendMessage(_request('Contact john.doe@example.com'));
    expect(loggedMessage, isNot(contains('john.doe@example.com')));
    expect(loggedContext?['messagePreview'] as String?, isNot(contains('john.doe@example.com')));
  });

  test('records security events for validation failures', () async {
    final monitor = SecurityMonitorImpl();
    final service = SecureAiChatService(
      inner: _FakeAiChatService(),
      rateLimiter: RateLimiterImpl(
        config: const RateLimitConfig(perMinute: 5, perHour: 5, perDay: 5),
      ),
      dataRedactionService: DataRedactionServiceImpl(),
      inputValidator: InputValidatorImpl(),
      authenticationService: AuthenticationServiceImpl(),
      securityMonitor: monitor,
      tokenProvider: () => null,
    );

    try {
      await service.sendMessage(_request('<script>alert(1)</script>'));
    } catch (_) {}

    final events = await monitor.getRecentEvents();
    expect(events.any((e) => e.type == SecurityEventType.inputValidationFailure), isTrue);
  });
}
