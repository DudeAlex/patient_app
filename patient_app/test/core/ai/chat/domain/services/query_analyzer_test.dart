import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/domain/services/intent_classifier.dart';
import 'package:patient_app/core/ai/chat/domain/services/keyword_extractor.dart';
import 'package:patient_app/core/ai/chat/domain/services/query_analyzer.dart';
import 'package:patient_app/core/ai/chat/models/query_context.dart';
import 'package:patient_app/core/ai/chat/models/query_intent.dart';
import 'package:patient_app/core/ai/chat/domain/services/intent_classifier.dart';

void main() {
  group('QueryAnalyzer', () {
    late QueryAnalyzer analyzer;
    late MockKeywordExtractor mockKeywordExtractor;
    late MockIntentClassifier mockIntentClassifier;

    setUp(() {
      mockKeywordExtractor = MockKeywordExtractor();
      mockIntentClassifier = MockIntentClassifier();
      analyzer = QueryAnalyzer(
        keywordExtractor: mockKeywordExtractor,
        intentClassifier: mockIntentClassifier,
      );
    });

    test('performs full analysis flow with keyword extraction and intent classification', () async {
      const query = "What is my blood pressure?";
      final extractedKeywords = <String>["what", "is", "my", "blood", "pressure"];
      const intent = QueryIntent.question;
      const confidence = 0.8;

      // Setup mocks
      mockKeywordExtractor.mockKeywords = extractedKeywords;
      mockIntentClassifier.mockClassification = IntentClassification(
        intent: intent,
        confidence: confidence,
      );

      // Execute analysis
      final result = await analyzer.analyze(query);

      // Verify the result
      expect(result.originalQuery, equals(query));
      expect(result.keywords, equals(extractedKeywords));
      expect(result.intent, equals(intent));
      expect(result.intentConfidence, equals(confidence));

      // Verify that both extractor and classifier were called
      expect(mockKeywordExtractor.wasCalled, isTrue);
      expect(mockIntentClassifier.wasCalled, isTrue);
    });

    test('correctly analyzes keywords and intent for English query', () async {
      const query = "Show my expenses";
      final extractedKeywords = <String>["show", "my", "expenses"];
      const intent = QueryIntent.question;
      const confidence = 0.5;

      mockKeywordExtractor.mockKeywords = extractedKeywords;
      mockIntentClassifier.mockClassification = IntentClassification(
        intent: intent,
        confidence: confidence,
      );

      final result = await analyzer.analyze(query);

      expect(result.originalQuery, equals(query));
      expect(result.keywords, equals(extractedKeywords));
      expect(result.intent, equals(intent));
      expect(result.intentConfidence, equals(confidence));
    });

    test('correctly analyzes keywords and intent for Russian query', () async {
      const query = "Какое у меня давление?";
      final extractedKeywords = <String>["какое", "меня", "давление"];
      const intent = QueryIntent.question;
      const confidence = 0.8;

      mockKeywordExtractor.mockKeywords = extractedKeywords;
      mockIntentClassifier.mockClassification = IntentClassification(
        intent: intent,
        confidence: confidence,
      );

      final result = await analyzer.analyze(query);

      expect(result.originalQuery, equals(query));
      expect(result.keywords, equals(extractedKeywords));
      expect(result.intent, equals(intent));
      expect(result.intentConfidence, equals(confidence));
    });

    test('handles edge cases like empty query', () async {
      const query = "";
      final extractedKeywords = <String>[];
      const intent = QueryIntent.question; // Default intent when keywords <= 2
      const confidence = 0.5;

      mockKeywordExtractor.mockKeywords = extractedKeywords;
      mockIntentClassifier.mockClassification = IntentClassification(
        intent: intent,
        confidence: confidence,
      );

      final result = await analyzer.analyze(query);

      expect(result.originalQuery, equals(query));
      expect(result.keywords, equals(extractedKeywords));
      expect(result.intent, equals(intent));
      expect(result.intentConfidence, equals(confidence));
    });

    test('handles very long input query', () async {
      const query = "This is a very long query with many words that should be processed properly for analysis";
      final extractedKeywords = <String>[
        "this", "is", "a", "very", "long", "query", 
        "with", "many", "words", "that", "should", 
        "be", "processed", "properly", "for", "analysis"
      ];
      const intent = QueryIntent.question;
      const confidence = 0.5;

      mockKeywordExtractor.mockKeywords = extractedKeywords;
      mockIntentClassifier.mockClassification = IntentClassification(
        intent: intent,
        confidence: confidence,
      );

      final result = await analyzer.analyze(query);

      expect(result.originalQuery, equals(query));
      expect(result.keywords, equals(extractedKeywords));
      expect(result.intent, equals(intent));
      expect(result.intentConfidence, equals(confidence));
    });

    test('handles mixed case and converts appropriately', () async {
      const query = "WHAT IS MY BLOOD PRESSURE?";
      final extractedKeywords = <String>["what", "is", "my", "blood", "pressure"];
      const intent = QueryIntent.question;
      const confidence = 0.8;

      mockKeywordExtractor.mockKeywords = extractedKeywords;
      mockIntentClassifier.mockClassification = IntentClassification(
        intent: intent,
        confidence: confidence,
      );

      final result = await analyzer.analyze(query);

      expect(result.originalQuery, equals(query));
      expect(result.keywords, equals(extractedKeywords));
      expect(result.intent, equals(intent));
      expect(result.intentConfidence, equals(confidence));
    });

    test('works for multiple languages (Uzbek example)', () async {
      const query = "Mening bosimim qanday?";
      final extractedKeywords = <String>["mening", "bosimim", "qanday"];
      const intent = QueryIntent.question;
      const confidence = 0.8;

      mockKeywordExtractor.mockKeywords = extractedKeywords;
      mockIntentClassifier.mockClassification = IntentClassification(
        intent: intent,
        confidence: confidence,
      );

      final result = await analyzer.analyze(query);

      expect(result.originalQuery, equals(query));
      expect(result.keywords, equals(extractedKeywords));
      expect(result.intent, equals(intent));
      expect(result.intentConfidence, equals(confidence));
    });

    test('works for multiple languages (French example)', () async {
      const query = "Mes dépenses ce mois?";
      final extractedKeywords = <String>["mes", "dépenses", "ce", "mois"];
      const intent = QueryIntent.question;
      const confidence = 0.8;

      mockKeywordExtractor.mockKeywords = extractedKeywords;
      mockIntentClassifier.mockClassification = IntentClassification(
        intent: intent,
        confidence: confidence,
      );

      final result = await analyzer.analyze(query);

      expect(result.originalQuery, equals(query));
      expect(result.keywords, equals(extractedKeywords));
      expect(result.intent, equals(intent));
      expect(result.intentConfidence, equals(confidence));
    });

    test('handles conversation history context', () async {
      const query = "What about my blood pressure?";
      const history = ["I checked my blood pressure yesterday", "It was 120/80"];
      final extractedKeywords = <String>["what", "about", "my", "blood", "pressure"];
      const intent = QueryIntent.question;
      const confidence = 0.5;

      mockKeywordExtractor.mockKeywords = extractedKeywords;
      mockIntentClassifier.mockClassification = IntentClassification(
        intent: intent,
        confidence: confidence,
      );

      final result = await analyzer.analyze(query, history: history);

      expect(result.originalQuery, equals(query));
      expect(result.keywords, equals(extractedKeywords));
      expect(result.intent, equals(intent));
      expect(result.intentConfidence, equals(confidence));
      expect(result.context, isNotNull);
      expect(result.context!.conversationHistory, equals(history));
      expect(result.context!.resolvedReferences, isNotNull);
    });

    test('handles conversation history with limit to last 2 messages', () async {
      const query = "How does that compare?";
      const history = [
        "I checked my blood pressure last week",
        "It was 130/85",
        "I checked it again yesterday",
        "It was 120/80"  // Only this and previous should be included
      ];
      final extractedKeywords = <String>["how", "does", "that", "compare"];
      const intent = QueryIntent.question;
      const confidence = 0.5;

      mockKeywordExtractor.mockKeywords = extractedKeywords;
      mockIntentClassifier.mockClassification = IntentClassification(
        intent: intent,
        confidence: confidence,
      );

      final result = await analyzer.analyze(query, history: history);

      expect(result.originalQuery, equals(query));
      expect(result.keywords, equals(extractedKeywords));
      expect(result.intent, equals(intent));
      expect(result.intentConfidence, equals(confidence));
      expect(result.context, isNotNull);
      // Should only include the last 2 messages
      expect(result.context!.conversationHistory.length, equals(2));
      expect(result.context!.conversationHistory, equals(history.sublist(2)));
    });

    test('handles query without conversation history', () async {
      const query = "What is my blood pressure?";
      final extractedKeywords = <String>["what", "is", "my", "blood", "pressure"];
      const intent = QueryIntent.question;
      const confidence = 0.8;

      mockKeywordExtractor.mockKeywords = extractedKeywords;
      mockIntentClassifier.mockClassification = IntentClassification(
        intent: intent,
        confidence: confidence,
      );

      // Call analyze without history parameter
      final result = await analyzer.analyze(query);

      expect(result.originalQuery, equals(query));
      expect(result.keywords, equals(extractedKeywords));
      expect(result.intent, equals(intent));
      expect(result.intentConfidence, equals(confidence));
      expect(result.context, isNull); // Should be null when no history provided
    });
  });
}

// Mock implementations for testing
class MockKeywordExtractor extends KeywordExtractor {
  List<String> mockKeywords = <String>[];
  bool wasCalled = false;

  @override
  List<String> extract(String text) {
    wasCalled = true;
    return mockKeywords;
  }
}

class MockIntentClassifier extends IntentClassifier {
  IntentClassification? mockClassification;
  bool wasCalled = false;

  @override
  IntentClassification classify(String query, List<String> keywords) {
    wasCalled = true;
    return mockClassification ?? const IntentClassification(
      intent: QueryIntent.question,
      confidence: 0.5,
    );
  }
}