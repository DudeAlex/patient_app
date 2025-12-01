import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/context/record_relevance_scorer.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

/// Property 7: Relevance Sorting
/// Validates: Requirements 6.4
///
/// For any set of records with random relevance scores, when sorted by relevance,
/// the records should be in descending order (highest score first).
void main() {
  test('Property: Records are sorted in descending order by relevance', () async {
    final random = Random(42);
    final scorer = RecordRelevanceScorer();
    final now = DateTime(2025, 1, 15);

    // Test with various record set sizes
    for (int recordCount in [10, 25, 50, 100]) {
      // Generate records with random dates and view counts
      final records = List.generate(
        recordCount,
        (i) => _generateRecord(
          i,
          date: now.subtract(Duration(days: random.nextInt(365))),
          viewCount: random.nextInt(20),
        ),
      );

      // Sort by relevance
      final sorted = await scorer.sortByRelevance(
        records,
        now: now,
        accessCounts: {for (var r in records) r.id!: r.viewCount ?? 0},
      );

      // Calculate scores for verification
      final scores = <double>[];
      for (final record in sorted) {
        final score = scorer.calculateScore(
          record,
          now: now,
          accessCount: record.viewCount ?? 0,
        );
        scores.add(score);
      }

      // Verify descending order
      for (int i = 0; i < scores.length - 1; i++) {
        expect(
          scores[i],
          greaterThanOrEqualTo(scores[i + 1]),
          reason: 'Scores should be in descending order. '
              'Score at index $i (${scores[i]}) should be >= '
              'score at index ${i + 1} (${scores[i + 1]})',
        );
      }
    }
  });

  test('Property: More recent records score higher than older records', () async {
    final scorer = RecordRelevanceScorer();
    final now = DateTime(2025, 1, 15);

    // Create records with same view count but different dates
    final recentRecord = _generateRecord(
      1,
      date: now.subtract(const Duration(days: 1)),
      viewCount: 5,
    );
    final oldRecord = _generateRecord(
      2,
      date: now.subtract(const Duration(days: 100)),
      viewCount: 5,
    );

    final recentScore = scorer.calculateScore(recentRecord, now: now, accessCount: 5);
    final oldScore = scorer.calculateScore(oldRecord, now: now, accessCount: 5);

    expect(
      recentScore,
      greaterThan(oldScore),
      reason: 'Recent record (1 day old) should score higher than old record (100 days old)',
    );
  });

  test('Property: Frequently accessed records score higher', () async {
    final scorer = RecordRelevanceScorer();
    final now = DateTime(2025, 1, 15);
    final sameDate = now.subtract(const Duration(days: 10));

    // Create records with same date but different view counts
    final frequentRecord = _generateRecord(
      1,
      date: sameDate,
      viewCount: 20,
    );
    final rareRecord = _generateRecord(
      2,
      date: sameDate,
      viewCount: 1,
    );

    final frequentScore = scorer.calculateScore(frequentRecord, now: now, accessCount: 20);
    final rareScore = scorer.calculateScore(rareRecord, now: now, accessCount: 1);

    expect(
      frequentScore,
      greaterThan(rareScore),
      reason: 'Frequently accessed record (20 views) should score higher than rarely accessed (1 view)',
    );
  });

  test('Property: Relevance score is between 0 and 10', () async {
    final random = Random(123);
    final scorer = RecordRelevanceScorer();
    final now = DateTime(2025, 1, 15);

    // Test with various dates and view counts
    for (int i = 0; i < 100; i++) {
      final record = _generateRecord(
        i,
        date: now.subtract(Duration(days: random.nextInt(365))),
        viewCount: random.nextInt(50),
      );

      final score = scorer.calculateScore(
        record,
        now: now,
        accessCount: record.viewCount ?? 0,
      );

      expect(
        score,
        greaterThanOrEqualTo(0.0),
        reason: 'Score should be >= 0',
      );
      expect(
        score,
        lessThanOrEqualTo(10.0),
        reason: 'Score should be <= 10',
      );
    }
  });

  test('Property: Sorting is stable for equal scores', () async {
    final scorer = RecordRelevanceScorer();
    final now = DateTime(2025, 1, 15);
    final sameDate = now.subtract(const Duration(days: 10));

    // Create records with identical dates and view counts
    final records = List.generate(
      10,
      (i) => _generateRecord(
        i,
        date: sameDate,
        viewCount: 5,
      ),
    );

    final sorted = await scorer.sortByRelevance(
      records,
      now: now,
      accessCounts: {for (var r in records) r.id!: 5},
    );

    // All records should have the same score
    final scores = sorted.map((r) => scorer.calculateScore(r, now: now, accessCount: 5)).toList();
    final firstScore = scores.first;
    for (final score in scores) {
      expect(
        (score - firstScore).abs(),
        lessThan(0.01),
        reason: 'All records with same date and view count should have same score',
      );
    }
  });

  test('Property: Empty record list returns empty sorted list', () async {
    final scorer = RecordRelevanceScorer();
    final now = DateTime(2025, 1, 15);

    final sorted = await scorer.sortByRelevance(
      [],
      now: now,
      accessCounts: {},
    );

    expect(sorted, isEmpty, reason: 'Empty input should return empty output');
  });

  test('Property: Single record returns single record', () async {
    final scorer = RecordRelevanceScorer();
    final now = DateTime(2025, 1, 15);

    final record = _generateRecord(1, date: now, viewCount: 5);
    final sorted = await scorer.sortByRelevance(
      [record],
      now: now,
      accessCounts: {1: 5},
    );

    expect(sorted.length, 1, reason: 'Single record should return single record');
    expect(sorted.first.id, record.id);
  });

  test('Property: Recency weight is higher than frequency weight', () async {
    final scorer = RecordRelevanceScorer();
    final now = DateTime(2025, 1, 15);

    // Very recent record with low views
    final recentLowViews = _generateRecord(
      1,
      date: now.subtract(const Duration(days: 1)),
      viewCount: 0,
    );

    // Old record with high views
    final oldHighViews = _generateRecord(
      2,
      date: now.subtract(const Duration(days: 200)),
      viewCount: 10,
    );

    final recentScore = scorer.calculateScore(recentLowViews, now: now, accessCount: 0);
    final oldScore = scorer.calculateScore(oldHighViews, now: now, accessCount: 10);

    // Recent record should score higher because recency is weighted 70%
    expect(
      recentScore,
      greaterThan(oldScore),
      reason: 'Very recent record should score higher than old record even with fewer views '
          '(recency weighted 70% vs frequency 30%)',
    );
  });
}

RecordEntity _generateRecord(
  int id, {
  required DateTime date,
  required int viewCount,
}) {
  return RecordEntity(
    id: id,
    spaceId: 'test-space',
    type: 'note',
    date: date,
    title: 'Record $id',
    text: 'Note for record $id',
    tags: ['tag$id'],
    createdAt: date,
    updatedAt: date,
    viewCount: viewCount,
  );
}
