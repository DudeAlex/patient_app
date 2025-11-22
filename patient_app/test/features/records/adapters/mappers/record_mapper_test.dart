import 'package:flutter_test/flutter_test.dart';

import 'package:patient_app/features/records/adapters/mappers/record_mapper.dart';
import 'package:patient_app/features/records/adapters/storage/record_isar_model.dart'
    as storage;
import 'package:patient_app/features/records/domain/entities/record.dart';

void main() {
  group('Record mapper', () {
    test('maps storage model to domain entity with defensive copies', () {
      final model = storage.Record()
        ..id = 42
        ..spaceId = 'health'
        ..type = 'visit'
        ..date = DateTime(2025, 10, 1)
        ..title = 'Follow-up'
        ..text = 'Discussed medication adjustments.'
        ..tags = ['visit', 'follow-up']
        ..createdAt = DateTime(2025, 9, 20)
        ..updatedAt = DateTime(2025, 10, 2)
        ..deletedAt = null;

      final entity = mapRecordFromStorage(model);

      expect(entity.id, 42);
      expect(entity.type, 'visit');
      expect(entity.date, DateTime(2025, 10, 1));
      expect(entity.title, 'Follow-up');
      expect(entity.text, 'Discussed medication adjustments.');
      expect(entity.tags, ['visit', 'follow-up']);
      expect(entity.createdAt, DateTime(2025, 9, 20));
      expect(entity.updatedAt, DateTime(2025, 10, 2));
      expect(entity.deletedAt, isNull);

      // Ensure the returned list is unmodifiable so domain code cannot mutate
      // storage state inadvertently.
      expect(() => entity.tags.add('new'), throwsUnsupportedError);
    });

    test('maps domain entity to storage model with cloned collections', () {
      final entity = RecordEntity(
        id: 7,
        type: 'lab',
        date: DateTime(2025, 8, 15),
        title: 'Bloodwork',
        text: 'Cholesterol slightly elevated.',
        tags: const ['lab'],
        createdAt: DateTime(2025, 8, 10),
        updatedAt: DateTime(2025, 8, 16),
        deletedAt: null,
      );

      final model = mapRecordToStorage(entity);

      expect(model.id, 7);
      expect(model.type, 'lab');
      expect(model.date, DateTime(2025, 8, 15));
      expect(model.title, 'Bloodwork');
      expect(model.text, 'Cholesterol slightly elevated.');
      expect(model.tags, ['lab']);
      expect(model.createdAt, DateTime(2025, 8, 10));
      expect(model.updatedAt, DateTime(2025, 8, 16));
      expect(model.deletedAt, isNull);

      // Mutating the model tags should not affect the original entity list.
      model.tags.add('new-tag');
      expect(entity.tags, ['lab']);
    });
  });
}
