import 'package:isar/isar.dart';

import '../model/record.dart';

class RecordsRepository {
  final Isar db;
  RecordsRepository(this.db);

  Future<int> add(Record record) async {
    return db.writeTxn(() => db.records.put(record));
  }

  Future<List<Record>> recent({int limit = 50}) async {
    return fetchPage(offset: 0, limit: limit);
  }

  Future<Record?> byId(Id id) {
    return db.records.get(id);
  }

  Future<void> delete(Id id) async {
    await db.writeTxn(() => db.records.delete(id));
  }

  Future<List<Record>> fetchPage({
    required int offset,
    required int limit,
    String? query,
  }) async {
    final trimmed = query?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return db.records
          .where()
          .sortByDateDesc()
          .thenByIdDesc()
          .offset(offset)
          .limit(limit)
          .findAll();
    }

    return db.records
        .filter()
        .group(
          (q) => q
              .titleContains(trimmed, caseSensitive: false)
              .or()
              .textContains(trimmed, caseSensitive: false),
        )
        .sortByDateDesc()
        .thenByIdDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
  }
}
