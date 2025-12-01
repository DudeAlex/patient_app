import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/domain/services/privacy_filter.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

void main() {
  group('PrivacyFilter - Simple Tests', () {
    late PrivacyFilter filter;

    setUp(() {
      filter = PrivacyFilter();
    });

    test('deleted records are excluded', () {
      // Arrange
      final now = DateTime.now();
      final records = [
        RecordEntity(
          id: 1,
          spaceId: 'health',
          type: 'Blood Pressure',
          date: now,
          title: 'Blood Pressure Reading',
          text: 'My blood pressure today was 120/80',
          tags: [],
          createdAt: now,
          updatedAt: now,
        ),
        RecordEntity(
          id: 2,
          spaceId: 'health',
          type: 'Deleted Note',
          date: now,
          title: 'Deleted Information',
          text: 'This record has been deleted',
          tags: [],
          createdAt: now,
          updatedAt: now,
          deletedAt: now, // This record is deleted
        ),
      ];
      
      // Act
      final result = filter.filter(records, 'health');
      
      // Assert
      expect(result.length, equals(1)); // Only 1 record should remain
      expect(result.first.title, equals('Blood Pressure Reading'));
    });

    test('normal records pass through', () {
      // Arrange
      final now = DateTime.now();
      final records = [
        RecordEntity(
          id: 1,
          spaceId: 'health',
          type: 'Blood Pressure',
          date: now,
          title: 'Blood Pressure Reading 1',
          text: 'My blood pressure today was 120/80',
          tags: [],
          createdAt: now,
          updatedAt: now,
        ),
        RecordEntity(
          id: 2,
          spaceId: 'health',
          type: 'Blood Pressure',
          date: now,
          title: 'Blood Pressure Reading 2',
          text: 'My blood pressure today was 130/85',
          tags: [],
          createdAt: now,
          updatedAt: now,
        ),
        RecordEntity(
          id: 3,
          spaceId: 'health',
          type: 'Medication',
          date: now,
          title: 'Medication Log',
          text: 'Took prescribed medication',
          tags: [],
          createdAt: now,
          updatedAt: now,
        ),
      ];
      
      // Act
      final result = filter.filter(records, 'health');
      
      // Assert
      expect(result.length, equals(3)); // All 3 records should pass through
    });

    test('private records are excluded', () {
      // Arrange
      final records = [
        RecordEntity(
          id: 1,
          spaceId: 'health',
          type: 'Blood Pressure',
          date: DateTime.now(),
          title: 'Blood Pressure Reading',
          text: 'My blood pressure today was 120/80',
          tags: ['normal'], // Normal record
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        RecordEntity(
          id: 2,
          spaceId: 'health',
          type: 'Personal Note',
          date: DateTime.now(),
          title: 'Private Information',
          text: 'This is sensitive personal information',
          tags: ['private'], // Private record
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      
      // Act
      final result = filter.filter(records, 'health');
      
      // Assert
      expect(result.length, equals(1)); // Only 1 record should remain
      expect(result.first.title, equals('Blood Pressure Reading'));
    });
  });
}