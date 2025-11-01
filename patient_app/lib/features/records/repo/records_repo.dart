import 'package:isar/isar.dart';

import '../model/record.dart';

class RecordsRepository {
  final Isar db;
  RecordsRepository(this.db);

  Future<int> add(Record record) async {
    return db.writeTxn(() => db.records.put(record));
  }

  Future<List<Record>> recent({int limit = 50}) async {
    return db.records.where().sortByDateDesc().limit(limit).findAll();
  }

  Future<Record?> byId(Id id) {
    return db.records.get(id);
  }

  Future<void> delete(Id id) async {
    await db.writeTxn(() => db.records.delete(id));
  }
}
