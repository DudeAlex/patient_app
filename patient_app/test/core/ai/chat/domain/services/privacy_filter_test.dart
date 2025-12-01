import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/domain/services/privacy_filter.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

void main() {
  late PrivacyFilter privacyFilter;

  setUp(() {
    privacyFilter = PrivacyFilter();
  });

  group('PrivacyFilter - isAllowed', () {
    test('should allow valid record from same space', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Checkup',
        date: DateTime.now(),
        title: 'Regular Checkup',
        text: 'Everything looks good',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = privacyFilter.isAllowed(record, 'health');
      expect(result, true);
    });

    test('should exclude deleted records', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Checkup',
        date: DateTime.now(),
        title: 'Regular Checkup',
        text: 'Everything looks good',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deletedAt: DateTime.now(), // Marked as deleted
      );

      final result = privacyFilter.isAllowed(record, 'health');
      expect(result, false);
    });

    test('should exclude records with private tags', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Checkup',
        date: DateTime.now(),
        title: 'Regular Checkup',
        text: 'Everything looks good',
        tags: ['private'], // Contains private tag
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = privacyFilter.isAllowed(record, 'health');
      expect(result, false);
    });

    test('should exclude records with confidential tags', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Checkup',
        date: DateTime.now(),
        title: 'Regular Checkup',
        text: 'Everything looks good',
        tags: ['confidential'], // Contains confidential tag
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = privacyFilter.isAllowed(record, 'health');
      expect(result, false);
    });

    test('should exclude records with sensitive tags', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Checkup',
        date: DateTime.now(),
        title: 'Regular Checkup',
        text: 'Everything looks good',
        tags: ['sensitive'], // Contains sensitive tag
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = privacyFilter.isAllowed(record, 'health');
      expect(result, false);
    });

    test('should exclude records with personal tags', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Checkup',
        date: DateTime.now(),
        title: 'Regular Checkup',
        text: 'Everything looks good',
        tags: ['personal'], // Contains personal tag
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = privacyFilter.isAllowed(record, 'health');
      expect(result, false);
    });

    test('should exclude records from different space', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'finance', // Different space
        type: 'Expense',
        date: DateTime.now(),
        title: 'Grocery Expense',
        text: 'Bought groceries',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = privacyFilter.isAllowed(record, 'health'); // Active space is health
      expect(result, false);
    });

    test('should exclude records with mixed case private tags', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Checkup',
        date: DateTime.now(),
        title: 'Regular Checkup',
        text: 'Everything looks good',
        tags: ['PRIVATE'], // Mixed case private tag
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = privacyFilter.isAllowed(record, 'health');
      expect(result, false);
    });

    test('should allow record with non-private tags', () {
      final record = RecordEntity(
        id: 1,
        spaceId: 'health',
        type: 'Checkup',
        date: DateTime.now(),
        title: 'Regular Checkup',
        text: 'Everything looks good',
        tags: ['medical', 'routine', 'doctor'], // Non-private tags
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = privacyFilter.isAllowed(record, 'health');
      expect(result, true);
    });
  });

  group('PrivacyFilter - filter', () {
    test('should filter out private and deleted records', () {
      final records = [
        RecordEntity( // Valid record - should be included
          id: 1,
          spaceId: 'health',
          type: 'Checkup',
          date: DateTime.now(),
          title: 'Regular Checkup',
          text: 'Everything looks good',
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        RecordEntity( // Deleted record - should be excluded
          id: 2,
          spaceId: 'health',
          type: 'Checkup',
          date: DateTime.now(),
          title: 'Deleted Checkup',
          text: 'This was deleted',
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deletedAt: DateTime.now(),
        ),
        RecordEntity( // Private record - should be excluded
          id: 3,
          spaceId: 'health',
          type: 'Checkup',
          date: DateTime.now(),
          title: 'Private Checkup',
          text: 'This is private',
          tags: ['private'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        RecordEntity( // Wrong space - should be excluded
          id: 4,
          spaceId: 'finance', // Different space
          type: 'Expense',
          date: DateTime.now(),
          title: 'Grocery Expense',
          text: 'Bought groceries',
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        RecordEntity( // Valid record - should be included
          id: 5,
          spaceId: 'health',
          type: 'Lab Results',
          date: DateTime.now(),
          title: 'Lab Results',
          text: 'Results came back normal',
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final filteredRecords = privacyFilter.filter(records, 'health');

      expect(filteredRecords.length, 2); // Only 2 valid records should remain
      expect(filteredRecords[0].id, 1); // First valid record
      expect(filteredRecords[1].id, 5); // Second valid record
    });

    test('should return empty list when all records are filtered out', () {
      final records = [
        RecordEntity( // Deleted record
          id: 1,
          spaceId: 'health',
          type: 'Checkup',
          date: DateTime.now(),
          title: 'Deleted Checkup',
          text: 'This was deleted',
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deletedAt: DateTime.now(),
        ),
        RecordEntity( // Private record
          id: 2,
          spaceId: 'health',
          type: 'Checkup',
          date: DateTime.now(),
          title: 'Private Checkup',
          text: 'This is private',
          tags: ['private'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final filteredRecords = privacyFilter.filter(records, 'health');

      expect(filteredRecords, isEmpty);
    });

    test('should return all records when none are filtered out', () {
      final records = [
        RecordEntity( // Valid record 1
          id: 1,
          spaceId: 'health',
          type: 'Checkup',
          date: DateTime.now(),
          title: 'Regular Checkup',
          text: 'Everything looks good',
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        RecordEntity( // Valid record 2
          id: 2,
          spaceId: 'health',
          type: 'Lab Results',
          date: DateTime.now(),
          title: 'Lab Results',
          text: 'Results came back normal',
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final filteredRecords = privacyFilter.filter(records, 'health');

      expect(filteredRecords.length, 2);
      expect(filteredRecords[0].id, 1);
      expect(filteredRecords[1].id, 2);
    });

    test('should handle empty list', () {
      final records = <RecordEntity>[];

      final filteredRecords = privacyFilter.filter(records, 'health');

      expect(filteredRecords, isEmpty);
    });
  });
}