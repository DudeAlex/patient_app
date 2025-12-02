import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/services/network_recovery_strategy.dart';

class MockAiChatService extends Mock implements AiChatService {}
class MockChatRequest extends Mock implements ChatRequest {}
class MockChatResponse extends Mock implements ChatResponse {}

void main() {
  late NetworkRecoveryStrategy strategy;
  late MockAiChatService mockService;
  late MockChatRequest mockRequest;
  late MockChatResponse mockResponse;

  setUp(() {
    strategy = NetworkRecoveryStrategy();
    mockService = MockAiChatService();
    mockRequest = MockChatRequest();
    mockResponse = MockChatResponse();
  });

  group('NetworkRecoveryStrategy', () {
    test('canRecover returns true for NetworkException', () {
      final exception = NetworkException(message: 'Network error');

      final result = strategy.canRecover(exception);

      expect(result, true);
    });

    test('canRecover returns false for other exceptions', () {
      final exception = RateLimitException(message: 'Rate limit exceeded');

      final result = strategy.canRecover(exception);

      expect(result, false);
    });

    test('getRetryDelay returns correct exponential backoff delays', () {
      // First attempt - 1 second
      expect(strategy.getRetryDelay(1), const Duration(seconds: 1));

      // Second attempt - 2 seconds
      expect(strategy.getRetryDelay(2), const Duration(seconds: 2));

      // Third attempt and beyond - 5 seconds (max rate limit wait)
      expect(strategy.getRetryDelay(3), const Duration(seconds: 5));
    });

    test('recover waits for specified delay and retries request', () async {
      final exception = NetworkException(message: 'Network error');
      when(mockService.sendMessage(mockRequest)).thenAnswer((_) async => mockResponse);

      final result = await strategy.recover(mockRequest, exception, 1, mockService);

      expect(result, mockResponse);
      verify(mockService.sendMessage(mockRequest)).called(1);
    });

    test('strategy name is correct', () {
      expect(strategy.strategyName, 'NetworkRecoveryStrategy');
    });
  });
}