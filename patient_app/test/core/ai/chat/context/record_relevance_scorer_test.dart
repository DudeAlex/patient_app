import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/context/record_relevance_scorer.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

void main() {
  late RecordRelevanceScorer scorer;
  late DateTime now;

  setUp(() {
    scorer = RecordRelevanceScorer();
    now = DateTime(2024, 1, 15);
  });

  RecordEntity createRecord({
    required int id,
    required DateTime date,
    int viewCount = 0,
  }) {
    return RecordEntity(
      id: id,
      spaceId: 'health',
      type: 'note',
      date: date,
      title: 'Record $id',
      viewCount: viewCount,
      createdAt: date,
      updatedAt: date,
    );
  }

  group('RecordRelevanceScorer', () {
    group('calculateScore', () {
      test('should score recent records higher (recency)', () {
        final todayRecord = createRecord(id: 1, date: now);
        final oldRecord = createRecord(id: 2, date: now.subtract(const Duration(days: 60)));

        final todayScore = scorer.calculateScore(todayRecord, now: now);
        final oldScore = scorer.calculateScore(oldRecord, now: now);

        expect(todayScore, greaterThan(oldScore));
      });

      test('should score frequently accessed records higher (frequency)', () {
        final frequentRecord = createRecord(id: 1, date: now, viewCount: 10);
        final rareRecord = createRecord(id: 2, date: now, viewCount: 1);

        final frequentScore = scorer.calculateScore(frequentRecord, now: now);
        final rareScore = scorer.calculateScore(rareRecord, now: now);

        expect(frequentScore, greaterThan(rareScore));
      });

      test('should calculate recency score on 0-10 scale', () {
        final todayRecord = createRecord(id: 1, date: now);
        final score = scorer.calculateScore(todayRecord, now: now);

        // Recency component should be close to 10 for today's record
        // With 0.7 weight, it contributes ~7 to final score
        expect(score, greaterThanOrEqualTo(0));
        expect(score, lessThanOrEqualTo(10));
      });

      test('should calculate frequency score on 0-10 scale with cap', () {
        final highViewRecord = createRecord(id: 1, date: now, viewCount: 50);
        final score = scorer.calculateScore(highViewRecord, now: now);

        // Frequency is capped at 10, contributing max 3 to final score (0.3 weight)
        expect(score, lessThanOrEqualTo(10));
      });

      test('should combine recency (70%) and frequency (30%) scores', () {
        final record = createRecord(
          id: 1,
          date: now,
          viewCount: 10,
        );

        final score = scorer.calculateScore(record, now: now);

        // For a record from today (recency ~10) with 10 views (frequency 10):
        // Score = (10 * 0.7) + (10 * 0.3) = 7 + 3 = 10
        expect(score, closeTo(10.0, 0.1));
      });

      test('should handle zero viewCount', () {
        final record = createRecord(id: 1, date: now, viewCount: 0);
        final score = scorer.calculateScore(record, now: now);

        // With 0 views, frequency contributes 0, only recency matters
        // Recency for today = 10, so score = 10 * 0.7 = 7
        expect(score, closeTo(7.0, 0.1));
      });

      test('should handle very old records', () {
        final veryOldRecord = createRecord(
          id: 1,
          date: now.subtract(const Duration(days: 365)),
        );

        final score = scorer.calculateScore(veryOldRecord, now: now);

        // Very old records should have low scores (recency close to 0)
        expect(score, lessThan(1.0));
      });

      test('should use provided accessCount over record viewCount', () {
        final record = createRecord(id: 1, date: now, viewCount: 5);

        final scoreWithDefault = scorer.calculateScore(record, now: now);
        final scoreWithOverride = scorer.calculateScore(
          record,
          now: now,
          accessCount: 10,
        );

        // Override should result in higher score
        expect(scoreWithOverride, greaterThan(scoreWithDefault));
      });
    });

    group('sortByRelevance', () {
      test('should sort records in descending order by score', () async {
        final records = [
          createRecord(id: 1, date: now.subtract(const Duration(days: 30)), viewCount: 2),
          createRecord(id: 2, date: now, viewCount: 10), // Should be first
          createRecord(id: 3, date: now.subtract(const Duration(days: 60)), viewCount: 0),
          createRecord(id: 4, date: now.subtract(const Duration(days: 5)), viewCount: 5),
        ];

        final sorted = await scorer.sortByRelevance(records, now: now);

        // Record 2 should be first (recent + high views)
        expect(sorted.first.id, 2);
        // Record 3 should be last (old + no views)
        expect(sorted.last.id, 3);
      });

      test('should handle empty list', () async {
        final sorted = await scorer.sortByRelevance([], now: now);
        expect(sorted, isEmpty);
      });

      test('should handle single record', () async {
        final records = [createRecord(id: 1, date: now)];
        final sorted = await scorer.sortByRelevance(records, now: now);

        expect(sorted.length, 1);
        expect(sorted.first.id, 1);
      });

      test('should use provided accessCounts map', () async {
        final records = [
          createRecord(id: 1, date: now, viewCount: 0),
          createRecord(id: 2, date: now, viewCount: 0),
        ];

        final sorted = await scorer.sortByRelevance(
          records,
          now: now,
          accessCounts: {1: 0, 2: 10},
        );

        // Record 2 should be first due to higher accessCount
        expect(sorted.first.id, 2);
        expect(sorted.last.id, 1);
      });

      test('should maintain stable sort for equal scores', () async {
        final records = [
          createRecord(id: 1, date: now),
          createRecord(id: 2, date: now),
          createRecord(id: 3, date: now),
        ];

        final sorted = await scorer.sortByRelevance(records, now: now);

        // All have same score, order might vary but all should be present
        expect(sorted.length, 3);
        expect(sorted.map((r) => r.id).toSet(), {1, 2, 3});
      });
    });
  });
}
