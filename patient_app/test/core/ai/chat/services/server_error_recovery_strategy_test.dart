import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/services/server_error_recovery_strategy.dart';

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
  late ServerErrorRecoveryStrategy strategy;
  late MockAiChatService mockService;
  late MockChatRequest mockRequest;
  late MockChatResponse mockResponse;

  setUp(() {
    strategy = ServerErrorRecoveryStrategy();
    mockService = MockAiChatService();
    mockRequest = MockChatRequest();
    mockResponse = MockChatResponse();
  });

  group('ServerErrorRecoveryStrategy', () {
    test('canRecover returns false for ServerException (handled by fallback)', () {
      final exception = ServerException(message: 'Internal server error');

      final result = strategy.canRecover(exception);

      expect(result, false);
    });

    test('canRecover returns false for other exceptions', () {
      final exception = RateLimitException(message: 'Rate limit exceeded');

      final result = strategy.canRecover(exception);

      expect(result, false);
    });

    test('getRetryDelay returns zero for server errors (no retry)', () {
      expect(strategy.getRetryDelay(1), Duration.zero);
      expect(strategy.getRetryDelay(2), Duration.zero);
    });

    test('recover throws the error for server exceptions (no retry)', () async {
      final exception = ServerException(message: 'Internal server error');
      when(mockService.sendMessage(mockRequest)).thenAnswer((_) async => mockResponse);

      expect(() => strategy.recover(mockRequest, exception, 1, mockService), 
             throwsA(exception));
    });

    test('strategy name is correct', () {
      expect(strategy.strategyName, 'ServerErrorRecoveryStrategy');
    });
  });
}
