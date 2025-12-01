import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/domain/services/relevance_scorer.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

void main() {
  group('RelevanceScorer - Simple Tests', () {
    late RelevanceScorer scorer;

    setUp(() {
      scorer = RelevanceScorer();
    });

    test('perfect match gives high score', () {
      // Arrange
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Blood Pressure',
        date: DateTime.now(),
        title: 'Blood Pressure Reading',
        text: 'My blood pressure today was 120/80',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final keywords = ['blood', 'pressure'];
      final now = DateTime.now();
      
      // Act
      final score = scorer.score(
        record: record,
        keywords: keywords,
        now: now,
      );
      
      // Assert
      expect(score, greaterThan(0.5)); // High score for perfect match
    });

    test('no match gives low score', () {
      // Arrange
      final record = RecordEntity(
        id: 1,
        spaceId: 'finance',
        type: 'Expense',
        date: DateTime.now(),
        title: 'Grocery Shopping',
        text: 'Spent \$150 on groceries today',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final keywords = ['blood', 'pressure'];
      final now = DateTime.now();
      
      // Act
      final score = scorer.score(
        record: record,
        keywords: keywords,
        now: now,
      );
      
      // Assert
      expect(score, lessThan(0.6)); // Low score for no match (accounting for recency factor)
    });

    test('score is always between 0.0 and 1.0', () {
      // Arrange
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Blood Pressure',
        date: DateTime.now(),
        title: 'Blood Pressure Reading',
        text: 'My blood pressure today was 120/80',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final keywords = ['blood', 'pressure'];
      final now = DateTime.now();
      
      // Act
      final score = scorer.score(
        record: record,
        keywords: keywords,
        now: now,
      );
      
      // Assert
      expect(score, greaterThanOrEqualTo(0.0));
      expect(score, lessThanOrEqualTo(1.0));
    });
  });
}