import 'package:flutter_test/flutter_test.dart';

import 'package:patient_app/features/records/domain/entities/record.dart';

void main() {
  group('RecordEntity invariants', () {
    test('trims title/type and freezes tags list', () {
      final entity = _buildRecord(
        type: '  visit ',
        title: '  Follow-up  ',
        tags: ['visit', 'checkup'],
      );

      expect(entity.type, 'visit');
      expect(entity.title, 'Follow-up');
      expect(entity.tags, ['visit', 'checkup']);
      expect(() => entity.tags.add('new'), throwsUnsupportedError);
    });

    test('throws when title is blank', () {
      expect(
        () => _buildRecord(title: '   '),
        throwsArgumentError,
      );
    });

    test('throws when type is blank', () {
      expect(
        () => _buildRecord(type: ''),
        throwsArgumentError,
      );
    });

    test('throws when updatedAt precedes createdAt', () {
      final created = DateTime(2025, 1, 10, 12);
      final updated = DateTime(2025, 1, 9, 12);

      expect(
        () => _buildRecord(createdAt: created, updatedAt: updated),
        throwsArgumentError,
      );
    });

    test('throws when deletedAt precedes updatedAt', () {
      final updated = DateTime(2025, 1, 10, 12);
      final deleted = DateTime(2025, 1, 9, 12);

      expect(
        () => _buildRecord(updatedAt: updated, deletedAt: deleted),
        throwsArgumentError,
      );
    });
  });
}

RecordEntity _buildRecord({
  String type = 'note',
  String title = 'Baseline title',
  List<String>? tags,
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? deletedAt,
}) {
  final created = createdAt ?? DateTime(2025, 1, 1, 12);
  final updated = updatedAt ?? created.add(const Duration(hours: 1));
  return RecordEntity(
    type: type,
    date: DateTime(2025, 1, 1),
    title: title,
    text: 'Notes',
    tags: tags,
    createdAt: created,
    updatedAt: updated,
    deletedAt: deletedAt,
  );
}
