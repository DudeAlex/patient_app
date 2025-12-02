import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/services/timeout_recovery_strategy.dart';

class MockAiChatService extends Mock implements AiChatService {}
class MockChatRequest extends Mock implements ChatRequest {}
class MockChatResponse extends Mock implements ChatResponse {}

void main() {
  late TimeoutRecoveryStrategy strategy;
  late MockAiChatService mockService;
  late MockChatRequest mockRequest;
  late MockChatResponse mockResponse;

  setUp(() {
    strategy = TimeoutRecoveryStrategy();
    mockService = MockAiChatService();
    mockRequest = MockChatRequest();
    mockResponse = MockChatResponse();
  });

  group('TimeoutRecoveryStrategy', () {
    test('canRecover returns true for ChatTimeoutException', () {
      final exception = ChatTimeoutException(timeout: Duration(seconds: 30));

      final result = strategy.canRecover(exception);

      expect(result, true);
    });

    test('canRecover returns false for other exceptions', () {
      final exception = RateLimitException(message: 'Rate limit exceeded');

      final result = strategy.canRecover(exception);

      expect(result, false);
    });

    test('getRetryDelay returns 500ms for timeout errors', () {
      expect(strategy.getRetryDelay(1), const Duration(milliseconds: 500));
      expect(strategy.getRetryDelay(2), const Duration(milliseconds: 500));
    });

    test('recover retries the request', () async {
      final exception = ChatTimeoutException(timeout: Duration(seconds: 30));
      when(mockService.sendMessage(mockRequest)).thenAnswer((_) async => mockResponse);

      final result = await strategy.recover(mockRequest, exception, 1, mockService);

      expect(result, mockResponse);
      verify(mockService.sendMessage(mockRequest)).called(1);
    });

    test('strategy name is correct', () {
      expect(strategy.strategyName, 'TimeoutRecoveryStrategy');
    });
  });
}