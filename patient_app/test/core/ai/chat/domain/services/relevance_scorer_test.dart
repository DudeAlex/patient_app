import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/domain/services/relevance_scorer.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

void main() {
  late RelevanceScorer relevanceScorer;

  setUp(() {
    relevanceScorer = RelevanceScorer();
  });

  group('RelevanceScorer - keywordMatchScore', () {
    test('should return high score when all keywords match', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Blood Pressure',
        date: DateTime.now(),
        title: 'Blood Pressure Checkup',
        text: 'Today my blood pressure was 120/80 which is normal',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final keywords = ['blood', 'pressure', 'checkup'];
      final score = relevanceScorer.keywordMatchScore(record, keywords);

      expect(score, 1.0); // All 3 keywords matched
    });

    test('should return medium score when some keywords match', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Blood Pressure',
        date: DateTime.now(),
        title: 'Blood Pressure Checkup',
        text: 'Today my blood pressure was 120/80 which is normal',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final keywords = ['blood', 'pressure', 'diabetes', 'medication'];
      final score = relevanceScorer.keywordMatchScore(record, keywords);

      expect(score, 0.5); // 2 out of 4 keywords matched
    });

    test('should return low score when no keywords match', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Blood Pressure',
        date: DateTime.now(),
        title: 'Blood Pressure Checkup',
        text: 'Today my blood pressure was 120/80 which is normal',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final keywords = ['finance', 'expenses', 'budget'];
      final score = relevanceScorer.keywordMatchScore(record, keywords);

      expect(score, 0.0); // No keywords matched
    });

    test('should work for multiple languages (Russian)', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Давление',
        date: DateTime.now(),
        title: 'Проверка давления',
        text: 'Сегодня мое давление было 120/80',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final keywords = ['давление', 'проверка'];
      final score = relevanceScorer.keywordMatchScore(record, keywords);

      expect(score, 1.0); // Both keywords matched
    });

    test('should work for multiple languages (Uzbek)', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Bosim',
        date: DateTime.now(),
        title: 'Bosim tekshiruvi',
        text: 'Bugun 120/80 bosim bo\'ldi',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final keywords = ['bosim', 'tekshiruvi'];
      final score = relevanceScorer.keywordMatchScore(record, keywords);

      expect(score, 1.0); // Both keywords matched
    });

    test('should be case-insensitive', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'BLOOD PRESSURE',
        date: DateTime.now(),
        title: 'blood pressure checkup',
        text: 'Today MY BLOOD PRESSURE was 120/80',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final keywords = ['Blood', 'PRESSURE', 'Checkup'];
      final score = relevanceScorer.keywordMatchScore(record, keywords);

      expect(score, 1.0); // All keywords matched (case-insensitive)
    });

    test('should handle empty keywords list', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Blood Pressure',
        date: DateTime.now(),
        title: 'Blood Pressure Checkup',
        text: 'Today my blood pressure was 120/80',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final keywords = <String>[];
      final score = relevanceScorer.keywordMatchScore(record, keywords);

      expect(score, 0.0); // No keywords to match
    });
  });

  group('RelevanceScorer - recencyScore', () {
    test('should return 1.0 for today\'s record', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Checkup',
        date: DateTime.now(),
        title: 'Today\'s Checkup',
        text: 'Recent checkup',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final now = DateTime.now();
      final score = relevanceScorer.recencyScore(record, now);

      expect(score, 1.0); // Today = most recent
    });

    test('should return 0.5 for record 45 days old', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Checkup',
        date: DateTime.now().subtract(const Duration(days: 45)),
        title: 'Old Checkup',
        text: 'Old checkup',
        tags: [],
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now().subtract(const Duration(days: 45)),
      );

      final now = DateTime.now();
      final score = relevanceScorer.recencyScore(record, now);

      // 45 days old: 1.0 - (45/90) = 0.5
      expect(score, closeTo(0.5, 0.01));
    });

    test('should return 0.0 for record older than 90 days', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Checkup',
        date: DateTime.now().subtract(const Duration(days: 100)),
        title: 'Very Old Checkup',
        text: 'Very old checkup',
        tags: [],
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
        updatedAt: DateTime.now().subtract(const Duration(days: 100)),
      );

      final now = DateTime.now();
      final score = relevanceScorer.recencyScore(record, now);

      expect(score, 0.0); // Older than 90 days = 0.0
    });

    test('should handle future dates', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Checkup',
        date: DateTime.now().add(const Duration(days: 1)),
        title: 'Future Checkup',
        text: 'Future checkup',
        tags: [],
        createdAt: DateTime.now().add(const Duration(days: 1)),
        updatedAt: DateTime.now().add(const Duration(days: 1)),
      );

      final now = DateTime.now();
      final score = relevanceScorer.recencyScore(record, now);

      expect(score, 1.0); // Future dates get max score
    });
  });

  group('RelevanceScorer - score', () {
    test('should return combined score with 60% keyword + 40% recency', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Blood Pressure',
        date: DateTime.now(),
        title: 'Blood Pressure Checkup',
        text: 'Today my blood pressure was 120/80',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final keywords = ['blood', 'pressure'];
      final now = DateTime.now();
      
      final score = relevanceScorer.score(
        record: record,
        keywords: keywords,
        now: now,
      );

      // Today's record (recency = 1.0) + perfect keyword match (keyword = 1.0)
      // Combined: (1.0 * 0.6) + (1.0 * 0.4) = 1.0
      expect(score, closeTo(1.0, 0.01));
    });

    test('should return 0.0 when no keywords provided', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Blood Pressure',
        date: DateTime.now(),
        title: 'Blood Pressure Checkup',
        text: 'Today my blood pressure was 120/80',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final keywords = <String>[];
      final now = DateTime.now();
      
      final score = relevanceScorer.score(
        record: record,
        keywords: keywords,
        now: now,
      );

      expect(score, 0.0); // No keywords = 0.0 score
    });

    test('should handle keyword vs recency trade-offs', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Checkup',
        date: DateTime.now().subtract(const Duration(days: 45)), // 45 days old = 0.5 recency
        title: 'Checkup',
        text: 'No matching keywords here',
        tags: [],
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now().subtract(const Duration(days: 45)),
      );

      final keywords = ['blood', 'pressure']; // No match = 0.0 keyword
      final now = DateTime.now();
      
      final score = relevanceScorer.score(
        record: record,
        keywords: keywords,
        now: now,
      );

      // No keyword match (0.0) + 45-day old recency (0.5)
      // Combined: (0.0 * 0.6) + (0.5 * 0.4) = 0.2
      expect(score, closeTo(0.2, 0.01));
    });
  });

  group('RelevanceScorer - scoreRecords', () {
    test('should score multiple records and sort by relevance', () async {
      final records = [
        RecordEntity( // Perfect match, recent = high score
          id: 1,
          spaceId: 'health',
          type: 'Blood Pressure',
          date: DateTime.now(),
          title: 'Blood Pressure Checkup',
          text: 'Today my blood pressure was 120/80',
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        RecordEntity( // No keyword match, recent = medium score
          id: 2,
          spaceId: 'health',
          type: 'Diabetes',
          date: DateTime.now(),
          title: 'Diabetes Checkup',
          text: 'Today my sugar was checked',
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        RecordEntity( // Perfect match, old = medium score
          id: 3,
          spaceId: 'health',
          type: 'Blood Pressure',
          date: DateTime.now().subtract(const Duration(days: 60)),
          title: 'Blood Pressure Checkup',
          text: 'Today my blood pressure was 120/80',
          tags: [],
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          updatedAt: DateTime.now().subtract(const Duration(days: 60)),
        ),
      ];

      final keywords = ['blood', 'pressure'];
      final now = DateTime.now();
      
      final scoredRecords = await relevanceScorer.scoreRecords(
        records: records,
        keywords: keywords,
        now: now,
      );

      // Should be sorted by relevance score (descending)
      expect(scoredRecords.length, 3);
      expect(scoredRecords[0].record.id, 1); // Highest relevance
      expect(scoredRecords[1].record.id, 3); // Medium relevance
      expect(scoredRecords[2].record.id, 2); // Lowest relevance
    });

    test('should handle tie-breaking with recency and viewCount', () async {
      final records = [
        RecordEntity( // Same keywords, same date, higher view count
          id: 1,
          spaceId: 'health',
          type: 'Blood Pressure',
          date: DateTime.now(),
          title: 'Blood Pressure Checkup',
          text: 'Today my blood pressure was 120/80',
          tags: [],
          viewCount: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        RecordEntity( // Same keywords, same date, lower view count
          id: 2,
          spaceId: 'health',
          type: 'Blood Pressure',
          date: DateTime.now(),
          title: 'Blood Pressure Checkup',
          text: 'Today my blood pressure was 120/80',
          tags: [],
          viewCount: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final keywords = ['blood', 'pressure'];
      final now = DateTime.now();
      
      final scoredRecords = await relevanceScorer.scoreRecords(
        records: records,
        keywords: keywords,
        now: now,
      );

      // Should be sorted by view count (higher first) since relevance and recency are equal
      expect(scoredRecords[0].record.id, 1); // Higher view count
      expect(scoredRecords[1].record.id, 2); // Lower view count
    });

    test('should return empty list when no records provided', () async {
      final records = <RecordEntity>[];
      final keywords = ['blood', 'pressure'];
      final now = DateTime.now();
      
      final scoredRecords = await relevanceScorer.scoreRecords(
        records: records,
        keywords: keywords,
        now: now,
      );

      expect(scoredRecords, isEmpty);
    });
  });

  group('RelevanceScorer - containsKeyword', () {
    test('should find keyword in text (case-insensitive)', () {
      final result = relevanceScorer.containsKeyword('Blood Pressure Checkup', 'blood');
      expect(result, true);
    });

    test('should not find non-existent keyword', () {
      final result = relevanceScorer.containsKeyword('Blood Pressure Checkup', 'diabetes');
      expect(result, false);
    });

    test('should handle empty text', () {
      final result = relevanceScorer.containsKeyword('', 'blood');
      expect(result, false);
    });

    test('should handle empty keyword', () {
      final result = relevanceScorer.containsKeyword('Blood Pressure Checkup', '');
      expect(result, true); // Empty string is found in any string
    });
  });
}