import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/services/error_classifier.dart';
import 'package:patient_app/core/ai/chat/services/error_recovery_strategy.dart';
import 'package:patient_app/core/ai/chat/services/fallback_service.dart';
import 'package:patient_app/core/ai/chat/services/resilient_ai_chat_service.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';

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

class MockErrorRecoveryStrategy implements ErrorRecoveryStrategy {
  bool canRecoverResult = true;
  Duration delayToReturn = Duration.zero;
  String strategyNameResult = 'MockStrategy';
  ChatResponse? recoveryResponse;
  bool shouldThrow = false;
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
    return recoveryResponse ?? ChatResponse.success(messageContent: 'Recovered response');
  }

  @override
  bool canRecover(AiServiceException error) => canRecoverResult;

  @override
  Duration getRetryDelay(int attemptNumber) => delayToReturn;

  @override
  String get strategyName => strategyNameResult;
}

class MockFallbackService extends FallbackService {
  @override
  ChatResponse generateFallbackResponse(ChatRequest request, AiServiceException error) {
    return ChatResponse.success(messageContent: 'Fallback response');
  }
}

void main() {
 group('ResilientAiChatService', () {
    late MockAiChatService mockPrimaryService;
    late ErrorClassifier errorClassifier;
    late MockFallbackService mockFallbackService;
    late MockErrorRecoveryStrategy mockRecoveryStrategy;
    late ResilientAiChatService resilientService;

    setUp(() {
      mockPrimaryService = MockAiChatService();
      errorClassifier = ErrorClassifier();
      mockFallbackService = MockFallbackService();
      mockRecoveryStrategy = MockErrorRecoveryStrategy();
      
      resilientService = ResilientAiChatService(
        primaryService: mockPrimaryService,
        errorClassifier: errorClassifier,
        fallbackService: mockFallbackService,
        recoveryStrategies: [mockRecoveryStrategy],
      );
    });

    group('sendMessage', () {
      test('returns response when primary service succeeds', () async {
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
        mockPrimaryService.responseToReturn = ChatResponse.success(messageContent: 'Primary response');

        // Act
        final result = await resilientService.sendMessage(request);

        // Assert
        expect(result.messageContent, 'Primary response');
      });

      test('attempts recovery when primary service fails', () async {
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
        mockRecoveryStrategy.recoveryResponse = ChatResponse.success(messageContent: 'Recovered response');

        // Act
        final result = await resilientService.sendMessage(request);

        // Assert
        expect(result.messageContent, 'Recovered response');
      });

      test('uses fallback when all recovery attempts fail', () async {
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
        final result = await resilientService.sendMessage(request);

        // Assert
        expect(result.messageContent, 'Fallback response');
      });

      test('returns fallback when no recovery strategy is available', () async {
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
        mockPrimaryService.exceptionToThrow = ValidationException('Validation error');
        // Use a recovery strategy that can't handle validation errors
        mockRecoveryStrategy.canRecoverResult = false;

        // Act
        final result = await resilientService.sendMessage(request);

        // Assert
        expect(result.messageContent, 'Fallback response');
      });
    });

    group('summarizeItem', () {
      test('delegates to primary service', () async {
        // Arrange
        final item = InformationItem(
          id: 1,
          spaceId: 'health',
          domainId: 'test_domain',
          data: {'name': 'test'},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final result = await resilientService.summarizeItem(item);

        // Assert
        expect(result.summaryText, 'Test summary');
      });
    });
  });
}

// Mock SpaceContext class since it's not available in test scope
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