import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/domain/services/keyword_extractor.dart';

void main() {
  group('KeywordExtractor', () {
    late KeywordExtractor extractor;

    setUp(() {
      extractor = KeywordExtractor();
    });

    test('extracts English query keywords', () {
      const query = "What is my blood pressure?";
      final result = extractor.extract(query);
      
      expect(result, equals(['what', 'is', 'my', 'blood', 'pressure']));
    });

    test('extracts Russian query keywords', () {
      const query = "Какое у меня давление?";
      final result = extractor.extract(query);
      
      expect(result, equals(['какое', 'меня', 'давление'])); // 'у' is filtered out as it's only 1 character
    });

    test('extracts Uzbek query keywords', () {
      const query = "Mening bosimim qanday?";
      final result = extractor.extract(query);
      
      expect(result, equals(['mening', 'bosimim', 'qanday']));
    });

    test('extracts French query keywords', () {
      const query = "Mes dépenses ce mois?";
      final result = extractor.extract(query);
      
      expect(result, equals(['mes', 'dépenses', 'ce', 'mois'])); // 'ce' is 2 chars so it's kept
    });

    test('handles query with punctuation', () {
      const query = "Show me my expenses!";
      final result = extractor.extract(query);
      
      expect(result, equals(['show', 'me', 'my', 'expenses']));
    });

    test('returns empty list for empty query', () {
      const query = "";
      final result = extractor.extract(query);
      
      expect(result, isEmpty);
    });

    test('filters very short words', () {
      const query = "I am ok";
      final result = extractor.extract(query);
      
      expect(result, equals(['am', 'ok'])); // "i" is filtered out as it's only 1 character
    });

    test('handles multiple spaces and punctuation', () {
      const query = "What   is    my  blood-pressure???";
      final result = extractor.extract(query);
      
      expect(result, equals(['what', 'is', 'my', 'blood', 'pressure']));
    });

    test('handles mixed case and converts to lowercase', () {
      const query = "WHAT Is My Blood PRESSURE";
      final result = extractor.extract(query);
      
      expect(result, equals(['what', 'is', 'my', 'blood', 'pressure']));
    });

    test('handles numeric values in text', () {
      const query = "My blood pressure is 120/80";
      final result = extractor.extract(query);
      
      expect(result, equals(['my', 'blood', 'pressure', 'is', '120', '80'])); // '/' is treated as separator
    });

    test('filters out single character words', () {
      const query = "a b cd efg";
      final result = extractor.extract(query);
      
      expect(result, equals(['cd', 'efg'])); // 'a' and 'b' are filtered out
    });
  });
}