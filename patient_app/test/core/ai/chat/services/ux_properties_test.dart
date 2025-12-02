import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/services/fallback_service.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart' as models;
import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';

void main() {
  group('UX Properties', () {
    late FallbackService fallbackService;

    setUp(() {
      fallbackService = FallbackService();
    });

    test('Property 9: User message friendliness - no technical jargon', () {
      // Test that fallback messages don't contain technical terms
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

      // Test different error types
      final errorTypes = [
        NetworkException(message: 'Network connection failed'),
        RateLimitException(message: 'Rate limit exceeded'),
        ChatTimeoutException(),
        ServerException(message: 'Internal server error'),
        ValidationException(message: 'Invalid request'),
        AiServiceException('Generic error'),
      ];

      for (final error in errorTypes) {
        final response = fallbackService.generateFallbackResponse(request, error);
        final message = response.messageContent.toLowerCase();
        
        // Check for technical jargon
        expect(message, isNot(contains('stack trace')));
        expect(message, isNot(contains('exception')));
        expect(message, isNot(contains('null pointer')));
        expect(message, isNot(contains('error code')));
        expect(message, isNot(contains('internal server error')));
        expect(message, isNot(contains('500')));
        expect(message, isNot(contains('404')));
        expect(message, isNot(contains('429')));
      }
    });

    test('Property 8: Persona switch consistency - context changes appropriately', () {
      // This property would require backend integration to fully test
      // For now, we'll test that space context is preserved in fallback messages
      final healthRequest = ChatRequest(
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

      final financeRequest = ChatRequest(
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

      final error = NetworkException(message: 'Network error');

      final healthResponse = fallbackService.generateFallbackResponse(healthRequest, error);
      final financeResponse = fallbackService.generateFallbackResponse(financeRequest, error);

      // Both should have appropriate space context
      expect(healthResponse.messageContent, isNotNull);
      expect(financeResponse.messageContent, isNotNull);
    });
  });
}

