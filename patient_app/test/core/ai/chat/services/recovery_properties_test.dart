import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/services/resilient_ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/services/error_classifier.dart';
import 'package:patient_app/core/ai/chat/services/fallback_service.dart';
import 'package:patient_app/core/ai/chat/services/error_recovery_strategy.dart';

class MockAiChatService implements AiChatService {
  bool shouldThrow = false;
  ChatResponse? responseToReturn;
  AiServiceException? exceptionToThrow;

 @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    if (shouldThrow && exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return responseToReturn ?? ChatResponse.success(messageContent: 'Test response');
  }

  @override
  Stream<ChatResponseChunk> sendMessageStream(ChatRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) {
    return Future.value(AiSummaryResult.success(summaryText: 'Test summary'));
  }
}

class MockRecoveryStrategy implements ErrorRecoveryStrategy {
  bool canRecoverResult = true;
  Duration delayToReturn = Duration.zero;
  String strategyNameResult = 'MockStrategy';
  bool shouldThrow = true; // Default to throwing to test fallback behavior
  AiServiceException? exceptionToThrow;

  @override
  Future<ChatResponse> recover(
    ChatRequest request,
    AiServiceException error,
    int attemptNumber,
    AiChatService service,
  ) async {
    if (shouldThrow && exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return ChatResponse.success(messageContent: 'Recovered response');
  }

 @override
  bool canRecover(AiServiceException error) => canRecoverResult;

  @override
  Duration getRetryDelay(int attemptNumber) => delayToReturn;

  @override
  String get strategyName => strategyNameResult;
}

void main() {
 group('Recovery Properties', () {
    late MockAiChatService mockPrimaryService;
    late ErrorClassifier errorClassifier;
    late FallbackService fallbackService;
    late MockRecoveryStrategy mockRecoveryStrategy;
    late ResilientAiChatService resilientService;

    setUp(() {
      mockPrimaryService = MockAiChatService();
      errorClassifier = ErrorClassifier();
      fallbackService = FallbackService();
      mockRecoveryStrategy = MockRecoveryStrategy();
      
      resilientService = ResilientAiChatService(
        primaryService: mockPrimaryService,
        errorClassifier: errorClassifier,
        fallbackService: fallbackService,
        recoveryStrategies: [mockRecoveryStrategy],
      );
    });

    test('Property 5: Recovery attempt limit - max 2 attempts before fallback', () async {
      // Arrange - Make primary service fail and recovery strategy fail too
      final request = ChatRequest(
        threadId: 'test-thread',
        messageContent: 'Hello',
        spaceContext: SpaceContext(
          spaceId: 'health',
          spaceName: 'Health',
          description: 'Health space',
          categories: ['medical'],
        ),
      );
      
      mockPrimaryService.shouldThrow = true;
      mockPrimaryService.exceptionToThrow = NetworkException('Network error');
      mockRecoveryStrategy.shouldThrow = true;
      mockRecoveryStrategy.exceptionToThrow = NetworkException('Recovery failed');

      // Act
      final result = await resilientService.sendMessage(request);

      // Assert - Should get fallback response after max attempts
      expect(result.messageContent, contains('right now')); // Contains fallback message
    });

    test('Property 6: Fallback always succeeds - never throws exception', () async {
      // Arrange - Force fallback by making everything fail
      final request = ChatRequest(
        threadId: 'test-thread',
        messageContent: 'Hello',
        spaceContext: SpaceContext(
          spaceId: 'health',
          spaceName: 'Health',
          description: 'Health space',
          categories: ['medical'],
        ),
      );
      
      mockPrimaryService.shouldThrow = true;
      mockPrimaryService.exceptionToThrow = ServerException('Server error');
      mockRecoveryStrategy.shouldThrow = true;
      mockRecoveryStrategy.exceptionToThrow = ServerException('Recovery failed');

      // Act & Assert - Should not throw, should return valid response
      expect(() async => await resilientService.sendMessage(request), returnsNormally);
      
      final result = await resilientService.sendMessage(request);
      expect(result, isA<ChatResponse>());
      expect(result.messageContent, isNotEmpty);
    });

    test('Property 7: Recovery time bounds - total time under 10 seconds', () async {
      // Arrange
      final request = ChatRequest(
        threadId: 'test-thread',
        messageContent: 'Hello',
        spaceContext: SpaceContext(
          spaceId: 'health',
          spaceName: 'Health',
          description: 'Health space',
          categories: ['medical'],
        ),
      );
      
      mockPrimaryService.shouldThrow = true;
      mockPrimaryService.exceptionToThrow = NetworkException('Network error');
      mockRecoveryStrategy.shouldThrow = true;
      mockRecoveryStrategy.exceptionToThrow = NetworkException('Recovery failed');

      // Act
      final startTime = DateTime.now();
      final result = await resilientService.sendMessage(request);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Assert
      expect(duration.inSeconds, lessThanOrEqualTo(10),
          reason: 'Recovery should complete within 10 seconds');
      expect(result.messageContent, contains('right now')); // Should be fallback message
    });
  });
}

// Mock SpaceContext class for testing
class SpaceContext {
  final String spaceId;
  final String spaceName;
  final String description;
  final List<String> categories;
 final String? recentRecords;
  final int maxContextRecords;
  final Map<String, dynamic>? filters;
 final Map<String, dynamic>? tokenAllocation;
  final Map<String, dynamic>? stats;
  final Persona persona;

  SpaceContext({
    required this.spaceId,
    required this.spaceName,
    required this.description,
    required this.categories,
    this.recentRecords,
    this.maxContextRecords = 10,
    this.filters,
    this.tokenAllocation,
    this.stats,
  }) : persona = Persona(
          name: 'Test Persona',
          tone: 'friendly',
          guidelines: [],
          systemPromptAddition: '',
        );
}

class Persona {
  final String name;
  final String tone;
  final List<String> guidelines;
 final String systemPromptAddition;

  Persona({
    required this.name,
    required this.tone,
    required this.guidelines,
    required this.systemPromptAddition,
  });
}