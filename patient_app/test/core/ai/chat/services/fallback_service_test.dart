import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart' as models;
import 'package:patient_app/core/ai/chat/services/fallback_service.dart';
import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';

void main() {
  group('FallbackService Tests', () {
    late FallbackService fallbackService;

    setUp(() {
      fallbackService = FallbackService();
    });

    test('Task 7d.1: Basic fallback tests - never throws exceptions', () {
      final request = ChatRequest(
        threadId: 'test-thread',
        messageContent: 'Hello',
        spaceContext: models.SpaceContext(
          spaceId: 'health',
          spaceName: 'Health',
          persona: models.SpacePersona.health,
          description: 'Health space',
          categories: ['medical'],
        ),
      );
      
      final error = NetworkException(message: 'Network error');
      
      // Should never throw an exception
      expect(() => fallbackService.generateFallbackResponse(request, error), returnsNormally);
    });

    test('Task 7d.1: Basic fallback tests - always returns valid ChatResponse', () {
      final request = ChatRequest(
        threadId: 'test-thread',
        messageContent: 'Hello',
        spaceContext: models.SpaceContext(
          spaceId: 'health',
          spaceName: 'Health',
          persona: models.SpacePersona.health,
          description: 'Health space',
          categories: ['medical'],
        ),
      );
      
      final error = NetworkException(message: 'Network error');
      final response = fallbackService.generateFallbackResponse(request, error);
      
      expect(response, isA<ChatResponse>());
      expect(response.messageContent, isNotNull);
      expect(response.messageContent, isNotEmpty);
      expect(response.metadata, isNotNull);
    });

    test('Task 7d.2: Error-specific message tests - network error message', () {
      final request = ChatRequest(
        threadId: 'test-thread',
        messageContent: 'Hello',
        spaceContext: models.SpaceContext(
          spaceId: 'health',
          spaceName: 'Health',
          persona: models.SpacePersona.health,
          description: 'Health space',
          categories: ['medical'],
        ),
      );
      
      final error = NetworkException(message: 'Network error');
      final response = fallbackService.generateFallbackResponse(request, error);
      
      expect(response.messageContent, contains('connect'));
      expect(response.messageContent, contains('internet'));
      expect(response.messageContent, isNot(contains('technical')));
      expect(response.messageContent, isNot(contains('exception')));
    });

    test('Task 7d.2: Error-specific message tests - rate limit error message', () {
      final request = ChatRequest(
        threadId: 'test-thread',
        messageContent: 'Hello',
        spaceContext: models.SpaceContext(
          spaceId: 'finance',
          spaceName: 'Finance',
          persona: models.SpacePersona.finance,
          description: 'Finance space',
          categories: ['budget'],
        ),
      );
      
      final error = RateLimitException(message: 'Rate limit exceeded');
      final response = fallbackService.generateFallbackResponse(request, error);
      
      expect(response.messageContent, contains('too many'));
      expect(response.messageContent, contains('wait'));
      expect(response.messageContent, isNot(contains('technical')));
      expect(response.messageContent, isNot(contains('exception')));
    });

    test('Task 7d.2: Error-specific message tests - timeout error message', () {
      final request = ChatRequest(
        threadId: 'test-thread',
        messageContent: 'Hello',
        spaceContext: models.SpaceContext(
          spaceId: 'education',
          spaceName: 'Education',
          persona: models.SpacePersona.education,
          description: 'Education space',
          categories: ['study'],
        ),
      );
      
      final error = ChatTimeoutException();
      final response = fallbackService.generateFallbackResponse(request, error);
      
      expect(response.messageContent, contains('took too long'));
      expect(response.messageContent, contains('try again'));
      expect(response.messageContent, isNot(contains('technical')));
      expect(response.messageContent, isNot(contains('exception')));
    });

    test('Task 7d.2: Error-specific message tests - server error message', () {
      final request = ChatRequest(
        threadId: 'test-thread',
        messageContent: 'Hello',
        spaceContext: models.SpaceContext(
          spaceId: 'travel',
          spaceName: 'Travel',
          persona: models.SpacePersona.travel,
          description: 'Travel space',
          categories: ['trip'],
        ),
      );
      
      final error = ServerException(message: 'Server error');
      final response = fallbackService.generateFallbackResponse(request, error);
      
      expect(response.messageContent, contains('unavailable'));
      expect(response.messageContent, contains('try again'));
      expect(response.messageContent, isNot(contains('technical')));
      expect(response.messageContent, isNot(contains('exception')));
    });

    test('Task 7d.2: Error-specific message tests - generic error message', () {
      final request = ChatRequest(
        threadId: 'test-thread',
        messageContent: 'Hello',
        spaceContext: models.SpaceContext(
          spaceId: 'health',
          spaceName: 'Health',
          persona: models.SpacePersona.health,
          description: 'Health space',
          categories: ['medical'],
        ),
      );
      
      final error = AiServiceException('Generic error');
      final response = fallbackService.generateFallbackResponse(request, error);
      
      expect(response.messageContent, contains('Something went wrong'));
      expect(response.messageContent, contains('try again'));
      expect(response.messageContent, isNot(contains('technical')));
      expect(response.messageContent, isNot(contains('exception')));
    });

    test('Task 7d.3: Context-aware tests - Space-specific messages', () {
      final healthRequest = ChatRequest(
        threadId: 'test-thread',
        messageContent: 'How is my blood pressure?',
        spaceContext: models.SpaceContext(
          spaceId: 'health',
          spaceName: 'Health',
          persona: models.SpacePersona.health,
          description: 'Health space',
          categories: ['medical'],
        ),
      );
      
      final financeRequest = ChatRequest(
        threadId: 'test-thread',
        messageContent: 'How much did I spend?',
        spaceContext: models.SpaceContext(
          spaceId: 'finance',
          spaceName: 'Finance',
          persona: models.SpacePersona.finance,
          description: 'Finance space',
          categories: ['budget'],
        ),
      );
      
      final error = NetworkException(message: 'Network error');
      
      final healthResponse = fallbackService.generateFallbackResponse(healthRequest, error);
      final financeResponse = fallbackService.generateFallbackResponse(financeRequest, error);
      
      expect(healthResponse.messageContent, contains('health'));
      expect(financeResponse.messageContent, contains('finance'));
    });

    test('Task 7d.3: Context-aware tests - retry suggestions included', () {
      final request = ChatRequest(
        threadId: 'test-thread',
        messageContent: 'Hello',
        spaceContext: models.SpaceContext(
          spaceId: 'health',
          spaceName: 'Health',
          persona: models.SpacePersona.health,
          description: 'Health space',
          categories: ['medical'],
        ),
      );
      
      final error = NetworkException(message: 'Network error');
      final response = fallbackService.generateFallbackResponse(request, error);
      
      // Check that action hints are provided
      expect(response.actionHints, isNotNull);
      expect(response.actionHints.length, greaterThan(0));
      expect(response.actionHints.first, contains('Check your internet'));
    });

    test('Task 7d.3: Context-aware tests - error prevention tips', () {
      final request = ChatRequest(
        threadId: 'test-thread',
        messageContent: 'Hello',
        spaceContext: models.SpaceContext(
          spaceId: 'health',
          spaceName: 'Health',
          persona: models.SpacePersona.health,
          description: 'Health space',
          categories: ['medical'],
        ),
      );
      
      final error = RateLimitException(message: 'Rate limit exceeded');
      final response = fallbackService.generateFallbackResponse(request, error);
      
      // Check that action hints provide prevention tips
      expect(response.actionHints, isNotNull);
      expect(response.actionHints.any((hint) => hint.contains('Wait')), isTrue);
    });
  });
}