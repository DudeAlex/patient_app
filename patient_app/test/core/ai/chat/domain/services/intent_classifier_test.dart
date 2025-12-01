import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/domain/services/intent_classifier.dart';
import 'package:patient_app/core/ai/chat/models/query_intent.dart';

void main() {
  group('IntentClassifier', () {
    late IntentClassifier classifier;

    setUp(() {
      classifier = IntentClassifier();
    });

    test('classifies English question with high confidence', () {
      const query = "What is my blood pressure?";
      final keywords = <String>["what", "is", "my", "blood", "pressure"];
      
      final result = classifier.classify(query, keywords);
      
      expect(result.intent, equals(QueryIntent.question));
      expect(result.confidence, 0.8);
    });

    test('classifies Russian question with high confidence', () {
      const query = "Какое у меня давление?";
      final keywords = <String>["какое", "меня", "давление"]; // 'у' is filtered out
      
      final result = classifier.classify(query, keywords);
      
      expect(result.intent, equals(QueryIntent.question));
      expect(result.confidence, 0.8);
    });

    test('classifies short greeting with medium confidence', () {
      const query = "Hello";
      final keywords = <String>["hello"];
      
      final result = classifier.classify(query, keywords);
      
      expect(result.intent, equals(QueryIntent.greeting));
      expect(result.confidence, 0.6);
    });

    test('classifies short Russian greeting with medium confidence', () {
      const query = "Привет";
      final keywords = <String>["привет"];
      
      final result = classifier.classify(query, keywords);
      
      expect(result.intent, equals(QueryIntent.greeting));
      expect(result.confidence, 0.6);
    });

    test('classifies longer query without question mark as question with default confidence', () {
      const query = "Show my expenses";
      final keywords = <String>["show", "my", "expenses"];
      
      final result = classifier.classify(query, keywords);
      
      expect(result.intent, equals(QueryIntent.question));
      expect(result.confidence, 0.5);
    });

    test('classifies 2-word query as greeting', () {
      const query = "Hello there";
      final keywords = <String>["hello", "there"];
      
      final result = classifier.classify(query, keywords);
      
      expect(result.intent, equals(QueryIntent.greeting));
      expect(result.confidence, 0.6);
    });

    test('classifies command without question mark as question (default)', () {
      const query = "Show me my records";
      final keywords = <String>["show", "me", "my", "records"];
      
      final result = classifier.classify(query, keywords);
      
      expect(result.intent, equals(QueryIntent.question));
      expect(result.confidence, 0.5);
    });

    test('handles empty query gracefully', () {
      const query = "";
      final keywords = <String>[];
      
      final result = classifier.classify(query, keywords);
      
      expect(result.intent, equals(QueryIntent.greeting)); // keywords.length (0) <= 2
      expect(result.confidence, 0.6);
    });

    test('works for multiple languages', () {
      // French
      const frenchQuery = "Quelles sont mes dépenses?";
      final frenchKeywords = <String>["quelles", "sont", "mes", "dépenses"];
      final frenchResult = classifier.classify(frenchQuery, frenchKeywords);
      expect(frenchResult.intent, equals(QueryIntent.question));
      expect(frenchResult.confidence, 0.8);

      // Uzbek
      const uzbekQuery = "Mening bosimim qanday?";
      final uzbekKeywords = <String>["mening", "bosimim", "qanday"];
      final uzbekResult = classifier.classify(uzbekQuery, uzbekKeywords);
      expect(uzbekResult.intent, equals(QueryIntent.question));
      expect(uzbekResult.confidence, 0.8);
    });
  });
}