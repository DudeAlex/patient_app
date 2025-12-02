import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/services/rate_limit_recovery_strategy.dart';

class MockAiChatService extends Mock implements AiChatService {
  @override
  Future<ChatResponse> sendMessage(ChatRequest request) =>
      super.noSuchMethod(
        Invocation.method(#sendMessage, [request]),
        returnValue: Future.value(ChatResponse.success(messageContent: 'ok')),
      ) as Future<ChatResponse>;
}
class MockChatRequest extends Mock implements ChatRequest {}
class MockChatResponse extends Mock implements ChatResponse {}

void main() {
  late RateLimitRecoveryStrategy strategy;
  late MockAiChatService mockService;
  late MockChatRequest mockRequest;
  late MockChatResponse mockResponse;

  setUp(() {
    strategy = RateLimitRecoveryStrategy();
    mockService = MockAiChatService();
    mockRequest = MockChatRequest();
    mockResponse = MockChatResponse();
  });

  group('RateLimitRecoveryStrategy', () {
    test('canRecover returns true for RateLimitException', () {
      final exception = RateLimitException(message: 'Rate limit exceeded');
      
      final result = strategy.canRecover(exception);
      
      expect(result, true);
    });

    test('canRecover returns false for other exceptions', () {
      final exception = NetworkException(message: 'Network error');
      
      final result = strategy.canRecover(exception);
      
      expect(result, false);
    });

    test('getRetryDelay returns jittered delays based on attempt number', () {
      final first = strategy.getRetryDelay(1);
      final second = strategy.getRetryDelay(2);
      final third = strategy.getRetryDelay(3);

      expect(first.inMilliseconds, inInclusiveRange(800, 1200));
      expect(second.inMilliseconds, inInclusiveRange(1600, 2400));
      expect(third.inMilliseconds, inInclusiveRange(4000, 6000));
    });

    test('recover waits for specified delay and retries request', () async {
      final exception = RateLimitException(message: 'Rate limit exceeded');
      when(mockService.sendMessage(mockRequest)).thenAnswer((_) async => mockResponse);

      final result = await strategy.recover(mockRequest, exception, 1, mockService);

      expect(result, mockResponse);
      verify(mockService.sendMessage(mockRequest)).called(1);
    });

    test('strategy name is correct', () {
      expect(strategy.strategyName, 'RateLimitRecoveryStrategy');
    });
  });
}
