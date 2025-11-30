import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as path;
import 'package:patient_app/features/records/domain/entities/record.dart';
import 'package:patient_app/features/records/adapters/storage/record_isar_model.dart'
    as storage;

class DatabaseService {
  final String dbPath;
  late Isar _isar;

  DatabaseService(this.dbPath);

  /// Opens database connection
  Future<void> open() async {
    final dir = path.dirname(dbPath);
    if (!await Directory(dir).exists()) {
      await Directory(dir).create(recursive: true);
    }

    _isar = await Isar.open(
      [storage.RecordSchema],
      directory: dir,
      name: path.basename(dbPath),
    );
  }

  /// Closes database connection
  Future<void> close() async {
    await _isar.close();
  }

  /// Inserts records in batch
  Future<int> insertRecords(List<RecordEntity> records) async {
    final storageRecords = records
        .map((entity) => _toStorageRecord(entity))
        .toList();
    await _isar.writeTxn(() async {
      await _isar.records.putAll(storageRecords);
    });
    return storageRecords.length;
  }

  /// Gets all records
  Future<List<RecordEntity>> getAllRecords() async {
    final storageRecords = await _isar.records.where().findAll();
    return storageRecords.map((record) => _fromStorageRecord(record)).toList();
  }

  /// Gets records by space
  Future<List<RecordEntity>> getRecordsBySpace(String spaceId) async {
    final storageRecords = await _isar.records
        .filter()
        .spaceIdEqualTo(spaceId)
        .findAll();
    return storageRecords.map((record) => _fromStorageRecord(record)).toList();
  }

  /// Updates a record
  Future<void> updateRecord(RecordEntity record) async {
    final storageRecord = _toStorageRecord(record);
    await _isar.writeTxn(() async {
      await _isar.records.put(storageRecord);
    });
  }

  /// Deletes records by IDs
  Future<void> deleteRecords(List<int> recordIds) async {
    await _isar.writeTxn(() async {
      await _isar.records.deleteAll(recordIds);
    });
  }

  /// Deletes all records
  Future<int> deleteAllRecords() async {
    final count = await _isar.records.where().count();
    await _isar.writeTxn(() async {
      await _isar.records.where().deleteAll();
    });
    return count;
  }

  /// Gets record count
  Future<int> getRecordCount() async {
    return await _isar.records.where().count();
  }

  /// Helper method to convert domain RecordEntity to storage Record
  storage.Record _toStorageRecord(RecordEntity entity) {
    return storage.Record()
      ..id = entity.id ?? Isar.autoIncrement
      ..spaceId = entity.spaceId
      ..type = entity.type
      ..date = entity.date
      ..title = entity.title
      ..text = entity.text
      ..tags = entity.tags.toList()
      ..viewCount = entity.viewCount
      ..createdAt = entity.createdAt
      ..updatedAt = entity.updatedAt
      ..deletedAt = entity.deletedAt;
  }

  /// Helper method to convert storage Record to domain RecordEntity
  RecordEntity _fromStorageRecord(storage.Record record) {
    return RecordEntity(
      id: record.id != Isar.autoIncrement ? record.id : null,
      spaceId: record.spaceId,
      type: record.type,
      date: record.date,
      title: record.title,
      text: record.text,
      tags: record.tags,
      viewCount: record.viewCount,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
      deletedAt: record.deletedAt,
    );
  }
}
