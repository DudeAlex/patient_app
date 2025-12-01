import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/context/context_truncation_strategy.dart';
import 'package:patient_app/core/ai/chat/context/record_summary_formatter.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

void main() {
  late ContextTruncationStrategy strategy;
  late RecordSummaryFormatter formatter;
  late DateTime now;

  setUp(() {
    strategy = const ContextTruncationStrategy();
    formatter = RecordSummaryFormatter();
    now = DateTime(2024, 1, 15);
  });

  RecordEntity createRecord({
    required int id,
    required String title,
    String? text,
  }) {
    return RecordEntity(
      id: id,
      spaceId: 'health',
      type: 'note',
      date: now,
      title: title,
      text: text,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('ContextTruncationStrategy', () {
    group('truncateToFit', () {
      test('should include all records if within budget and limit', () {
        final records = [
          createRecord(id: 1, title: 'Record 1'),
          createRecord(id: 2, title: 'Record 2'),
          createRecord(id: 3, title: 'Record 3'),
        ];

        final result = strategy.truncateToFit(
          records,
          availableTokens: 10000,
          formatter: formatter,
          maxRecords: 20,
        );

        expect(result.length, 3);
      });

      test('should enforce 20-record hard limit', () {
        final records = List.generate(
          30,
          (i) => createRecord(id: i, title: 'Record $i'),
        );

        final result = strategy.truncateToFit(
          records,
          availableTokens: 100000,
          formatter: formatter,
          maxRecords: 30, // Request 30 but should cap at 20
        );

        expect(result.length, 20);
      });

      test('should respect maxRecords when less than 20', () {
        final records = List.generate(
          15,
          (i) => createRecord(id: i, title: 'Record $i'),
        );

        final result = strategy.truncateToFit(
          records,
          availableTokens: 100000,
          formatter: formatter,
          maxRecords: 10,
        );

        expect(result.length, 10);
      });

      test('should stop when token budget exhausted', () {
        final records = List.generate(
          20,
          (i) => createRecord(id: i, title: 'Record $i', text: 'x' * 100),
        );

        // Very limited budget - should only fit a few records
        final result = strategy.truncateToFit(
          records,
          availableTokens: 100,
          formatter: formatter,
          maxRecords: 20,
        );

        expect(result.length, lessThan(20));
      });

      test('should remove lowest-scoring records first (from end)', () {
        // Records are passed in sorted order (highest score first)
        final records = [
          createRecord(id: 1, title: 'High score record'),
          createRecord(id: 2, title: 'Medium score record'),
          createRecord(id: 3, title: 'Low score record'),
        ];

        // Very tight budget that requires dropping the last record
        final result = strategy.truncateToFit(
          records,
          availableTokens: 15, // Very tight budget
          formatter: formatter,
          maxRecords: 20,
        );

        // Should keep high-scoring records at the start
        expect(result.length, lessThan(3));
        if (result.isNotEmpty) {
          expect(result.first.title, 'High score record');
        }
      });

      test('should handle empty input', () {
        final result = strategy.truncateToFit(
          [],
          availableTokens: 1000,
          formatter: formatter,
          maxRecords: 20,
        );

        expect(result, isEmpty);
      });

      test('should handle single record', () {
        final records = [createRecord(id: 1, title: 'Only record')];

        final result = strategy.truncateToFit(
          records,
          availableTokens: 1000,
          formatter: formatter,
          maxRecords: 20,
        );

        expect(result.length, 1);
        expect(result.first.title, 'Only record');
      });

      test('should handle zero available tokens', () {
        final records = [
          createRecord(id: 1, title: 'Record 1'),
          createRecord(id: 2, title: 'Record 2'),
        ];

        final result = strategy.truncateToFit(
          records,
          availableTokens: 0,
          formatter: formatter,
          maxRecords: 20,
        );

        expect(result, isEmpty);
      });

      test('should maintain order of included records', () {
        final records = [
          createRecord(id: 1, title: 'First'),
          createRecord(id: 2, title: 'Second'),
          createRecord(id: 3, title: 'Third'),
          createRecord(id: 4, title: 'Fourth'),
        ];

        final result = strategy.truncateToFit(
          records,
          availableTokens: 10000,
          formatter: formatter,
          maxRecords: 20,
        );

        expect(result[0].title, 'First');
        expect(result[1].title, 'Second');
        expect(result[2].title, 'Third');
        expect(result[3].title, 'Fourth');
      });

      test('should handle maxRecords = 0', () {
        final records = [createRecord(id: 1, title: 'Record')];

        final result = strategy.truncateToFit(
          records,
          availableTokens: 1000,
          formatter: formatter,
          maxRecords: 0,
        );

        expect(result, isEmpty);
      });

      test('should drop records when budget requires it', () {
        // Create records where later ones are larger
        final records = [
          createRecord(id: 1, title: '1'),
          createRecord(id: 2, title: '2'),
          createRecord(id: 3, title: '3'),
          createRecord(id: 4, title: '4 with long text', text: 'x' * 1000),
        ];

        // Budget allows first 3 records but not the 4th
        // When 4th is encountered, it should drop the 3rd (from end) to try to fit
        final result = strategy.truncateToFit(
          records,
          availableTokens: 80,
          formatter: formatter,
          maxRecords: 20,
        );

        // Should keep at least the first records
        expect(result.length, greaterThan(0));
        expect(result.first.title, '1');
      });
    });

    group('truncation statistics', () {
      test('should return correct RecordSummary objects', () {
        final records = [
          createRecord(id: 1, title: 'Test Record', text: 'Content'),
        ];

        final result = strategy.truncateToFit(
          records,
          availableTokens: 1000,
          formatter: formatter,
          maxRecords: 20,
        );

        expect(result.length, 1);
        expect(result.first.title, 'Test Record');
        expect(result.first.type, 'note');
        expect(result.first.summary, isNotEmpty);
      });

      test('should truncate note summaries correctly', () {
        final records = [
          createRecord(
            id: 1,
            title: 'Record',
            text: 'x' * 200, // Long text
          ),
        ];

        final result = strategy.truncateToFit(
          records,
          availableTokens: 1000,
          formatter: formatter,
          maxRecords: 20,
        );

        // Summary should be truncated to 100 chars max
        expect(result.first.summary, isNotNull);
        expect(result.first.summary!.length, 100); // Exactly 100 with ellipsis
        expect(result.first.summary, endsWith('...'));
      });
    });

    group('edge cases', () {
      test('should handle exact budget fit', () {
        final records = [createRecord(id: 1, title: 'Test')];

        // Calculate exact tokens needed
        final summary = formatter.format(records.first);
        final exactTokens = formatter.estimateTokens(summary);

        final result = strategy.truncateToFit(
          records,
          availableTokens: exactTokens,
          formatter: formatter,
          maxRecords: 20,
        );

        expect(result.length, 1);
      });

      test('should handle very large maxRecords value', () {
        final records = List.generate(
          10,
          (i) => createRecord(id: i, title: 'Record $i'),
        );

        final result = strategy.truncateToFit(
          records,
          availableTokens: 10000,
          formatter: formatter,
          maxRecords: 1000, // Should cap at 20
        );

        expect(result.length, 10); // Only 10 records provided
      });
    });
  });
}
