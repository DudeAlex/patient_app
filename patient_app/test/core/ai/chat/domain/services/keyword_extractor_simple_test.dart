import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/domain/services/keyword_extractor.dart';

void main() {
  group('KeywordExtractor - Simple Tests', () {
    late KeywordExtractor extractor;

    setUp(() {
      extractor = KeywordExtractor();
    });

    test('extracts keywords from Russian query', () {
      // Arrange
      const query = "Какое у меня давление?";
      
      // Act
      final result = extractor.extract(query);
      
      // Assert
      expect(result, equals(['какое', 'меня', 'давление']));
      // Note: 'у' is filtered out because it's only 1 character
    });

    test('returns empty list for empty query', () {
      // Arrange
      const query = "";
      
      // Act
      final result = extractor.extract(query);
      
      // Assert
      expect(result, isEmpty);
    });

    test('extracts keywords from English query', () {
      // Arrange
      const query = "What is my blood pressure?";
      
      // Act
      final result = extractor.extract(query);
      
      // Assert
      expect(result, equals(['what', 'is', 'my', 'blood', 'pressure']));
    });
  });
}