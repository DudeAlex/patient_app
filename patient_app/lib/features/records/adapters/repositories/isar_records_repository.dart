import 'package:isar/isar.dart';

import '../../application/ports/records_repository.dart';
import '../../domain/entities/record.dart';
import '../../model/attachment.dart';
import '../mappers/record_mapper.dart';
import '../storage/record_isar_model.dart';

/// Isar-backed implementation of the [RecordsRepository] port.
class IsarRecordsRepository implements RecordsRepository {
  IsarRecordsRepository(this._db);

  final Isar _db;

  @override
  Future<RecordEntity> save(RecordEntity record) async {
    final model = mapRecordToStorage(record);
    final id = await _db.writeTxn<int>(() => _db.records.put(model));
    final stored = await _db.records.get(id);
    if (stored == null) {
      throw StateError('Failed to load record $id after save.');
    }
    return mapRecordFromStorage(stored);
  }

  @override
  Future<List<RecordEntity>> recent({int limit = 50}) async {
    final models = await fetchPage(offset: 0, limit: limit);
    return models;
  }

  @override
  Future<RecordEntity?> byId(int id) async {
    final model = await _db.records.get(id);
    return model == null ? null : mapRecordFromStorage(model);
  }

  @override
  Future<void> delete(int id) {
    return _db.writeTxn(() => _db.records.delete(id));
  }

  @override
  Future<List<RecordEntity>> fetchPage({
    required int offset,
    required int limit,
    String? query,
  }) async {
    final trimmed = query?.trim();
    final results = trimmed == null || trimmed.isEmpty
        ? await _db.records
            .where()
            .sortByDateDesc()
            .offset(offset)
            .limit(limit)
            .findAll()
        : await _db.records
            .filter()
            .group(
              (q) => q
                  .titleContains(trimmed, caseSensitive: false)
                  .or()
                  .textContains(trimmed, caseSensitive: false),
            )
            .sortByDateDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
    return results.map(mapRecordFromStorage).toList(growable: false);
  }

  /// Saves a list of attachments linked to a record.
  /// Returns the list of saved attachments with assigned IDs.
  Future<List<Attachment>> saveAttachments(
    List<Attachment> attachments,
  ) async {
    final ids = await _db.writeTxn<List<int>>(
      () => _db.attachments.putAll(attachments),
    );
    final saved = await _db.attachments.getAll(ids);
    return saved.whereType<Attachment>().toList(growable: false);
  }

  /// Fetches all attachments for a given record.
  Future<List<Attachment>> getAttachmentsByRecordId(int recordId) async {
    return _db.attachments
        .filter()
        .recordIdEqualTo(recordId)
        .sortByCreatedAt()
        .findAll();
  }
}
