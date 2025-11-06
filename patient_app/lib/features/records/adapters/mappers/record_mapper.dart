import '../../domain/entities/record.dart';
import '../storage/record_isar_model.dart' as storage;

/// Converts an Isar [storage.Record] into a domain [RecordEntity].
RecordEntity mapRecordFromStorage(storage.Record record) {
  return RecordEntity(
    id: record.id,
    type: record.type,
    date: record.date,
    title: record.title,
    text: record.text,
    tags: List<String>.from(record.tags),
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    deletedAt: record.deletedAt,
  );
}

/// Converts a domain [RecordEntity] into an Isar [storage.Record].
storage.Record mapRecordToStorage(RecordEntity entity) {
  final model = storage.Record()
    ..type = entity.type
    ..date = entity.date
    ..title = entity.title
    ..text = entity.text
    ..tags = List<String>.from(entity.tags)
    ..createdAt = entity.createdAt
    ..updatedAt = entity.updatedAt
    ..deletedAt = entity.deletedAt;

  if (entity.id != null) {
    model.id = entity.id!;
  }

  return model;
}
