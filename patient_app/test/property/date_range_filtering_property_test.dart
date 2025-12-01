import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/context/context_filter_engine.dart';
import 'package:patient_app/core/ai/chat/models/context_filters.dart';
import 'package:patient_app/core/ai/chat/models/date_range.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

/// Property 5: Date Range Filtering
/// Validates: Requirements 4.2
///
/// For any set of records with random dates, when applying a date range filter,
/// all filtered records should have creation dates within the specified range.
void main() {
  test('Property: All filtered records are within date range', () async {
    final random = Random(42);
    final filterEngine = ContextFilterEngine();

    // Test with various date ranges
    final testCases = [
      DateRange.last7Days(),
      DateRange.last14Days(),
      DateRange.last30Days(),
      DateRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 12, 31),
      ),
      DateRange(
        start: DateTime(2025, 1, 1),
        end: DateTime(2025, 1, 31),
      ),
    ];

    for (final dateRange in testCases) {
      // Generate records with random dates spanning 2 years
      final baseDate = DateTime(2024, 1, 1);
      final records = List.generate(
        100,
        (i) => _generateRecordWithDate(
          i,
          baseDate.add(Duration(days: random.nextInt(730))), // 0-730 days
          spaceId: 'test-space',
        ),
      );

      final filtered = await filterEngine.filterRecords(
        records,
        spaceId: 'test-space',
        dateRange: dateRange,
      );

      // All filtered records should be within the date range
      for (final record in filtered) {
        expect(
          record.date.isAfter(dateRange.start) ||
              record.date.isAtSameMomentAs(dateRange.start),
          isTrue,
          reason: 'Record ${record.id} date ${record.date} '
              'should be after or at range start ${dateRange.start}',
        );

        expect(
          record.date.isBefore(dateRange.end) ||
              record.date.isAtSameMomentAs(dateRange.end),
          isTrue,
          reason: 'Record ${record.id} date ${record.date} '
              'should be before or at range end ${dateRange.end}',
        );
      }
    }
  });

  test('Property: Date range filtering is consistent', () async {
    final random = Random(123);
    final filterEngine = ContextFilterEngine();

    // Generate records with known dates
    final now = DateTime(2025, 1, 15);
    final records = <RecordEntity>[
      // 10 records within last 7 days
      for (int i = 1; i <= 10; i++)
        _generateRecordWithDate(
          i,
          now.subtract(Duration(days: i)),
          spaceId: 'space1',
        ),
      // 10 records between 8-14 days ago
      for (int i = 11; i <= 20; i++)
        _generateRecordWithDate(
          i,
          now.subtract(Duration(days: 7 + (i - 10))),
          spaceId: 'space1',
        ),
      // 10 records older than 14 days
      for (int i = 21; i <= 30; i++)
        _generateRecordWithDate(
          i,
          now.subtract(Duration(days: 14 + (i - 20))),
          spaceId: 'space1',
        ),
    ];

    // Test 7-day filter
    final filtered7 = await filterEngine.filterRecords(
      records,
      spaceId: 'space1',
      dateRange: DateRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
    );
    // Should have records from days 1-7 (records at exactly day 7 boundary might be excluded)
    expect(filtered7.length, greaterThanOrEqualTo(7), 
        reason: 'Should have at least 7 records within last 7 days');
    expect(filtered7.length, lessThanOrEqualTo(10), 
        reason: 'Should have at most 10 records within last 7 days');

    // Test 14-day filter
    final filtered14 = await filterEngine.filterRecords(
      records,
      spaceId: 'space1',
      dateRange: DateRange(
        start: now.subtract(const Duration(days: 14)),
        end: now,
      ),
    );
    expect(filtered14.length, greaterThanOrEqualTo(17), 
        reason: 'Should have at least 17 records within last 14 days');
    expect(filtered14.length, lessThanOrEqualTo(20), 
        reason: 'Should have at most 20 records within last 14 days');

    // Test 30-day filter
    final filtered30 = await filterEngine.filterRecords(
      records,
      spaceId: 'space1',
      dateRange: DateRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      ),
    );
    expect(filtered30.length, greaterThanOrEqualTo(27), 
        reason: 'Should have at least 27 records within last 30 days');
    expect(filtered30.length, lessThanOrEqualTo(30), 
        reason: 'Should have at most all 30 records within last 30 days');
  });

  test('Property: Date range filtering excludes deleted records', () async {
    final now = DateTime(2025, 1, 15);
    final filterEngine = ContextFilterEngine();

    final records = <RecordEntity>[
      // Active records within range
      _generateRecordWithDate(1, now.subtract(const Duration(days: 5)), spaceId: 'space1'),
      _generateRecordWithDate(2, now.subtract(const Duration(days: 3)), spaceId: 'space1'),
      // Deleted records within range (should be excluded)
      _generateRecordWithDate(
        3,
        now.subtract(const Duration(days: 4)),
        spaceId: 'space1',
        deleted: true,
      ),
      _generateRecordWithDate(
        4,
        now.subtract(const Duration(days: 2)),
        spaceId: 'space1',
        deleted: true,
      ),
    ];

    final filtered = await filterEngine.filterRecords(
      records,
      spaceId: 'space1',
      dateRange: DateRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
    );

    // Should only have 2 active records
    expect(filtered.length, 2, reason: 'Should exclude deleted records');
    expect(filtered.every((r) => r.deletedAt == null), isTrue,
        reason: 'All filtered records should be active');
  });

  test('Property: Date range filtering respects space boundaries', () async {
    final now = DateTime(2025, 1, 15);
    final filterEngine = ContextFilterEngine();

    final records = <RecordEntity>[
      // Records in space1
      _generateRecordWithDate(1, now.subtract(const Duration(days: 5)), spaceId: 'space1'),
      _generateRecordWithDate(2, now.subtract(const Duration(days: 3)), spaceId: 'space1'),
      // Records in space2 (should be excluded)
      _generateRecordWithDate(3, now.subtract(const Duration(days: 4)), spaceId: 'space2'),
      _generateRecordWithDate(4, now.subtract(const Duration(days: 2)), spaceId: 'space2'),
    ];

    final filtered = await filterEngine.filterRecords(
      records,
      spaceId: 'space1',
      dateRange: DateRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
    );

    // Should only have 2 records from space1
    expect(filtered.length, 2, reason: 'Should only include records from space1');
    expect(filtered.every((r) => r.spaceId == 'space1'), isTrue,
        reason: 'All filtered records should be from space1');
  });

  test('Property: Empty date range returns no records', () async {
    final now = DateTime(2025, 1, 15);
    final filterEngine = ContextFilterEngine();

    final records = List.generate(
      20,
      (i) => _generateRecordWithDate(
        i,
        now.subtract(Duration(days: i + 1)),
        spaceId: 'space1',
      ),
    );

    // Date range in the future (no records should match)
    final filtered = await filterEngine.filterRecords(
      records,
      spaceId: 'space1',
      dateRange: DateRange(
        start: now.add(const Duration(days: 1)),
        end: now.add(const Duration(days: 7)),
      ),
    );

    expect(filtered, isEmpty, reason: 'Future date range should return no records');
  });
}

RecordEntity _generateRecordWithDate(
  int id,
  DateTime date, {
  required String spaceId,
  bool deleted = false,
}) {
  return RecordEntity(
    id: id,
    spaceId: spaceId,
    type: 'note',
    date: date,
    title: 'Record $id',
    text: 'Note for record $id',
    tags: ['tag$id'],
    createdAt: date,
    updatedAt: date,
    deletedAt: deleted ? date : null,
  );
}
