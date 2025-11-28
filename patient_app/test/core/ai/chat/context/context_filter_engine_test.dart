import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/context/context_filter_engine.dart';
import 'package:patient_app/core/ai/chat/models/date_range.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

void main() {
  late ContextFilterEngine engine;
  late DateTime now;

  setUp(() {
    engine = ContextFilterEngine();
    now = DateTime(2024, 1, 15); // Fixed reference date
  });

  RecordEntity createRecord({
    required int id,
    required String spaceId,
    required DateTime date,
    DateTime? deletedAt,
  }) {
    return RecordEntity(
      id: id,
      spaceId: spaceId,
      type: 'note',
      date: date,
      title: 'Test Record $id',
      text: 'Content',
      createdAt: date,
      updatedAt: date,
      deletedAt: deletedAt,
    );
  }

  group('ContextFilterEngine', () {
    test('should filter records by spaceId', () async {
      final records = [
        createRecord(id: 1, spaceId: 'target_space', date: now),
        createRecord(id: 2, spaceId: 'other_space', date: now),
        createRecord(id: 3, spaceId: 'target_space', date: now),
      ];

      final result = await engine.filterRecords(
        records,
        spaceId: 'target_space',
        dateRange: DateRange(start: now.subtract(const Duration(days: 7)), end: now.add(const Duration(days: 7))),
      );

      expect(result.length, 2);
      expect(result.map((r) => r.id), containsAll([1, 3]));
    });

    test('should exclude deleted records', () async {
      final records = [
        createRecord(id: 1, spaceId: 'space', date: now),
        createRecord(id: 2, spaceId: 'space', date: now, deletedAt: now),
        createRecord(id: 3, spaceId: 'space', date: now),
      ];

      final result = await engine.filterRecords(
        records,
        spaceId: 'space',
        dateRange: DateRange(start: now.subtract(const Duration(days: 7)), end: now.add(const Duration(days: 7))),
      );

      expect(result.length, 2);
      expect(result.map((r) => r.id), containsAll([1, 3]));
    });

    test('should filter records outside date range', () async {
      final rangeStart = now.subtract(const Duration(days: 5));
      final rangeEnd = now.add(const Duration(days: 5));
      final range = DateRange(start: rangeStart, end: rangeEnd);

      final records = [
        createRecord(id: 1, spaceId: 'space', date: now), // Inside
        createRecord(id: 2, spaceId: 'space', date: rangeStart.subtract(const Duration(days: 1))), // Before
        createRecord(id: 3, spaceId: 'space', date: rangeEnd.add(const Duration(days: 1))), // After
        createRecord(id: 4, spaceId: 'space', date: rangeStart), // On start edge (inclusive check depends on implementation, usually inclusive)
        createRecord(id: 5, spaceId: 'space', date: rangeEnd), // On end edge
      ];

      // Note: Implementation uses isBefore/isAfter which are exclusive of the exact moment if strictly compared, 
      // but usually date ranges are inclusive. Let's check implementation:
      // if (record.date.isBefore(dateRange.start)) -> Strict before
      // if (record.date.isAfter(dateRange.end)) -> Strict after
      // So edges should be INCLUDED.

      final result = await engine.filterRecords(
        records,
        spaceId: 'space',
        dateRange: range,
      );

      expect(result.length, 3);
      expect(result.map((r) => r.id), containsAll([1, 4, 5]));
    });

    test('should apply all filters simultaneously', () async {
      final records = [
        createRecord(id: 1, spaceId: 'target', date: now), // Valid
        createRecord(id: 2, spaceId: 'other', date: now), // Wrong space
        createRecord(id: 3, spaceId: 'target', date: now, deletedAt: now), // Deleted
        createRecord(id: 4, spaceId: 'target', date: now.subtract(const Duration(days: 100))), // Too old
      ];

      final result = await engine.filterRecords(
        records,
        spaceId: 'target',
        dateRange: DateRange(start: now.subtract(const Duration(days: 7)), end: now.add(const Duration(days: 7))),
      );

      expect(result.length, 1);
      expect(result.first.id, 1);
    });
  });
}
