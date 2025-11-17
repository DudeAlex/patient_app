import '../../domain/entities/record.dart';

/// Repository port exposing record persistence operations to the application
/// layer. Implementations live in the adapters layer (e.g., Isar).
abstract class RecordsRepository {
  Future<RecordEntity> save(RecordEntity record);

  Future<List<RecordEntity>> recent({int limit = 50});

  Future<RecordEntity?> byId(int id);

  Future<void> delete(int id);

  Future<List<RecordEntity>> fetchPage({
    required int offset,
    required int limit,
    String? query,
    String? spaceId,
  });
}
