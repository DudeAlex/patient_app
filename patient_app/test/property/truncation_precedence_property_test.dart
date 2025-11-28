import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/context/context_truncation_strategy.dart';
import 'package:patient_app/core/ai/chat/context/record_relevance_scorer.dart';
import 'package:patient_app/core/ai/chat/context/record_summary_formatter.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

/// Property 10: Truncation Precedence
/// Validates: Requirements 7.3
///
/// For any set of scored records, when truncating to fit budget,
/// lower-scoring records should be removed first, preserving the
/// highest-scoring (most relevant) records.
void main() {
  test('Property: Lower scores are removed first during truncation', () async {
    final random = Random(42);
    final formatter = RecordSummaryFormatter(maxNoteLength: 100);
    final scorer = RecordRelevanceScorer();
    final strategy = const ContextTruncationStrategy();
    final now = DateTime(2025, 1, 15);

    // Test with various record set sizes
    for (int recordCount in [10, 20, 30, 50]) {
      // Generate records with varying dates and view counts
      final records = List.generate(
        recordCount,
        (i) => _generateRecord(
          i,
          date: now.subtract(Duration(days: random.nextInt(365))),
          viewCount: random.nextInt(20),
        ),
      );

      // Score and sort by relevance
      final sorted = await scorer.sortByRelevance(
        records,
        now: now,
        accessCounts: {for (var r in records) r.id!: r.viewCount ?? 0},
      );

      // Calculate scores for verification
      final scores = sorted.map((r) {
        return scorer.calculateScore(
          r,
          now: now,
          accessCount: r.viewCount ?? 0,
        );
      }).toList();

      // Set a tight budget to force truncation
      final availableTokens = 500; // Small budget to force truncation

      // Truncate to fit budget
      final truncated = strategy.truncateToFit(
        sorted,
        availableTokens: availableTokens,
        formatter: formatter,
        maxRecords: 20,
      );

      // If truncation occurred, verify highest scores were kept
      if (truncated.length < sorted.length) {
        // Get scores of kept records
        final keptRecordTitles = truncated.map((s) => s.title).toSet();
        final keptScores = <double>[];
        final droppedScores = <double>[];

        for (int i = 0; i < sorted.length; i++) {
          if (keptRecordTitles.contains(sorted[i].title)) {
            keptScores.add(scores[i]);
          } else {
            droppedScores.add(scores[i]);
          }
        }

        // Every kept score should be >= every dropped score
        // (with small tolerance for floating point)
        if (keptScores.isNotEmpty && droppedScores.isNotEmpty) {
          final minKeptScore = keptScores.reduce(min);
          final maxDroppedScore = droppedScores.reduce(max);

          expect(
            minKeptScore,
            greaterThanOrEqualTo(maxDroppedScore - 0.01),
            reason: 'Lowest kept score should be >= highest dropped score. '
                'Records: $recordCount, Kept: ${truncated.length}, '
                'Min kept: ${minKeptScore.toStringAsFixed(2)}, '
                'Max dropped: ${maxDroppedScore.toStringAsFixed(2)}',
          );
        }
      }
    }
  });

  test('Property: Truncation preserves descending score order', () async {
    final random = Random(123);
    final formatter = RecordSummaryFormatter(maxNoteLength: 100);
    final scorer = RecordRelevanceScorer();
    final strategy = const ContextTruncationStrategy();
    final now = DateTime(2025, 1, 15);

    // Generate records with varying relevance
    final records = List.generate(
      30,
      (i) => _generateRecord(
        i,
        date: now.subtract(Duration(days: random.nextInt(365))),
        viewCount: random.nextInt(20),
      ),
    );

    // Score and sort by relevance
    final sorted = await scorer.sortByRelevance(
      records,
      now: now,
      accessCounts: {for (var r in records) r.id!: r.viewCount ?? 0},
    );

    // Truncate with limited budget
    final truncated = strategy.truncateToFit(
      sorted,
      availableTokens: 800,
      formatter: formatter,
      maxRecords: 20,
    );

    // Get scores of truncated records in order
    final truncatedScores = <double>[];
    for (final summary in truncated) {
      final record = sorted.firstWhere((r) => r.title == summary.title);
      final score = scorer.calculateScore(
        record,
        now: now,
        accessCount: record.viewCount ?? 0,
      );
      truncatedScores.add(score);
    }

    // Verify scores are in descending order
    for (int i = 0; i < truncatedScores.length - 1; i++) {
      expect(
        truncatedScores[i],
        greaterThanOrEqualTo(truncatedScores[i + 1]),
        reason: 'Truncated records should maintain descending score order. '
            'Score at $i (${truncatedScores[i].toStringAsFixed(2)}) should be >= '
            'score at ${i + 1} (${truncatedScores[i + 1].toStringAsFixed(2)})',
      );
    }
  });

  test('Property: Highest-scoring records are always included', () async {
    final random = Random(456);
    final formatter = RecordSummaryFormatter(maxNoteLength: 100);
    final scorer = RecordRelevanceScorer();
    final strategy = const ContextTruncationStrategy();
    final now = DateTime(2025, 1, 15);

    for (int i = 0; i < 20; i++) {
      // Generate records
      final records = List.generate(
        25,
        (i) => _generateRecord(
          i,
          date: now.subtract(Duration(days: random.nextInt(365))),
          viewCount: random.nextInt(20),
        ),
      );

      // Score and sort
      final sorted = await scorer.sortByRelevance(
        records,
        now: now,
        accessCounts: {for (var r in records) r.id!: r.viewCount ?? 0},
      );

      // Truncate
      final truncated = strategy.truncateToFit(
        sorted,
        availableTokens: 600,
        formatter: formatter,
        maxRecords: 20,
      );

      if (truncated.isNotEmpty) {
        // The first record (highest score) should always be included
        final topRecord = sorted.first;
        final topRecordIncluded = truncated.any((s) => s.title == topRecord.title);

        expect(
          topRecordIncluded,
          isTrue,
          reason: 'Highest-scoring record should always be included unless '
              'it exceeds budget individually',
        );
      }
    }
  });

  test('Property: Truncation respects 20-record limit', () async {
    final random = Random(789);
    final formatter = RecordSummaryFormatter(maxNoteLength: 50);
    final scorer = RecordRelevanceScorer();
    final strategy = const ContextTruncationStrategy();
    final now = DateTime(2025, 1, 15);

    // Generate many records
    final records = List.generate(
      100,
      (i) => _generateRecord(
        i,
        date: now.subtract(Duration(days: random.nextInt(365))),
        viewCount: random.nextInt(20),
      ),
    );

    // Score and sort
    final sorted = await scorer.sortByRelevance(
      records,
      now: now,
      accessCounts: {for (var r in records) r.id!: r.viewCount ?? 0},
    );

    // Truncate with large budget but enforce record limit
    final truncated = strategy.truncateToFit(
      sorted,
      availableTokens: 10000, // Large budget
      formatter: formatter,
      maxRecords: 20,
    );

    // Should not exceed 20 records
    expect(
      truncated.length,
      lessThanOrEqualTo(20),
      reason: 'Truncation should respect 20-record limit even with large budget',
    );
  });

  test('Property: Token budget is never exceeded after truncation', () async {
    final random = Random(321);
    final formatter = RecordSummaryFormatter(maxNoteLength: 100);
    final scorer = RecordRelevanceScorer();
    final strategy = const ContextTruncationStrategy();
    final now = DateTime(2025, 1, 15);

    // Test with various budgets
    for (int budget in [300, 500, 1000, 2000]) {
      final records = List.generate(
        40,
        (i) => _generateRecord(
          i,
          date: now.subtract(Duration(days: random.nextInt(365))),
          viewCount: random.nextInt(20),
        ),
      );

      final sorted = await scorer.sortByRelevance(
        records,
        now: now,
        accessCounts: {for (var r in records) r.id!: r.viewCount ?? 0},
      );

      final truncated = strategy.truncateToFit(
        sorted,
        availableTokens: budget,
        formatter: formatter,
        maxRecords: 20,
      );

      // Calculate total tokens used
      int totalTokens = 0;
      for (final summary in truncated) {
        totalTokens += formatter.estimateTokens(summary);
      }

      expect(
        totalTokens,
        lessThanOrEqualTo(budget),
        reason: 'Total tokens after truncation should not exceed budget. '
            'Budget: $budget, Used: $totalTokens',
      );
    }
  });

  test('Property: Truncation with equal scores maintains order', () async {
    final formatter = RecordSummaryFormatter(maxNoteLength: 100);
    final scorer = RecordRelevanceScorer();
    final strategy = const ContextTruncationStrategy();
    final now = DateTime(2025, 1, 15);
    final sameDate = now.subtract(const Duration(days: 10));

    // Create records with identical scores
    final records = List.generate(
      15,
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

    // Truncate to 10 records
    final truncated = strategy.truncateToFit(
      sorted,
      availableTokens: 10000,
      formatter: formatter,
      maxRecords: 10,
    );

    // Should keep first 10 records from sorted list
    expect(
      truncated.length,
      equals(10),
      reason: 'Should truncate to exactly 10 records',
    );

    // Verify the kept records are the first 10 from sorted
    for (int i = 0; i < truncated.length; i++) {
      expect(
        truncated[i].title,
        equals(sorted[i].title),
        reason: 'Truncation should maintain input order for equal scores',
      );
    }
  });

  test('Property: Empty record list returns empty truncated list', () {
    final formatter = RecordSummaryFormatter(maxNoteLength: 100);
    final strategy = const ContextTruncationStrategy();

    final truncated = strategy.truncateToFit(
      [],
      availableTokens: 1000,
      formatter: formatter,
      maxRecords: 20,
    );

    expect(
      truncated,
      isEmpty,
      reason: 'Empty input should return empty output',
    );
  });

  test('Property: Single record within budget is kept', () {
    final formatter = RecordSummaryFormatter(maxNoteLength: 100);
    final strategy = const ContextTruncationStrategy();
    final now = DateTime(2025, 1, 15);

    final record = _generateRecord(1, date: now, viewCount: 5);

    final truncated = strategy.truncateToFit(
      [record],
      availableTokens: 1000,
      formatter: formatter,
      maxRecords: 20,
    );

    expect(
      truncated.length,
      equals(1),
      reason: 'Single record within budget should be kept',
    );
    expect(
      truncated.first.title,
      equals(record.title),
    );
  });

  test('Property: Records exceeding individual budget are skipped', () {
    final formatter = RecordSummaryFormatter(maxNoteLength: 100);
    final strategy = const ContextTruncationStrategy();
    final now = DateTime(2025, 1, 15);

    // Create records with normal notes
    final record1 = _generateRecord(1, date: now, viewCount: 10);
    final record2 = _generateRecord(2, date: now, viewCount: 5);

    // Use very small budget so first record exceeds it
    final truncated = strategy.truncateToFit(
      [record1, record2],
      availableTokens: 10, // Very small budget (smaller than any single record)
      formatter: formatter,
      maxRecords: 20,
    );

    // With such a small budget, records should be skipped
    expect(
      truncated.length,
      lessThanOrEqualTo(1),
      reason: 'With very small budget, most records should be skipped',
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
