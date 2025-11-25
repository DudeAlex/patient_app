import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/context/record_summary_formatter.dart';
import 'package:patient_app/core/ai/chat/context/space_context_builder.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/application/services/space_manager.dart';
import 'package:patient_app/core/domain/entities/space.dart';
import 'package:patient_app/core/domain/value_objects/space_gradient.dart';
import 'package:patient_app/features/records/application/ports/records_repository.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

class _FakeSpaceManager extends SpaceManager {
  _FakeSpaceManager(this._space) : super(_FakeSpaceRepo(_space), _FakeSpaceRegistry(_space));
  final Space _space;

  @override
  Future<Space> getCurrentSpace() async => _space;

  @override
  Future<List<Space>> getActiveSpaces() async => [_space];
}

class _FakeSpaceRepo implements SpaceRepository {
  _FakeSpaceRepo(this.space);
  final Space space;
  @override
  Future<List<String>> getActiveSpaceIds() async => [space.id];

  @override
  Future<String?> getCurrentSpaceId() async => space.id;

  @override
  Future<void> setActiveSpaceIds(List<String> ids) async {}

  @override
  Future<void> setCurrentSpaceId(String id) async {}
}

class _FakeSpaceRegistry extends SpaceRegistry {
  _FakeSpaceRegistry(this.space);
  final Space space;

  @override
  Space? getDefaultSpace(String id) => space.id == id ? space : null;
}

class _FakeRecordsService {
  _FakeRecordsService(this.records);
  final RecordsRepository records;
}

class _FakeRecordsRepo implements RecordsRepository {
  _FakeRecordsRepo(this._records);
  final List<RecordEntity> _records;

  @override
  Future<RecordEntity?> byId(int id) async => _records.firstWhere((r) => r.id == id);

  @override
  Future<void> delete(int id) async {}

  @override
  Future<List<RecordEntity>> fetchPage(
      {required int offset, required int limit, String? query, String? spaceId}) async {
    return _records.skip(offset).take(limit).toList();
  }

  @override
  Future<List<RecordEntity>> recent({int limit = 50}) async {
    return _records.take(limit).toList();
  }

  @override
  Future<RecordEntity> save(RecordEntity record) async => record;
}

Space _space() => Space(
      id: 'health',
      name: 'Health',
      icon: 'Heart',
      gradient: const SpaceGradient(start: '#fff', end: '#000'),
      description: 'Health space',
      categories: const ['Visits', 'Labs'],
    );

RecordEntity _record(int id, {String spaceId = 'health', DateTime? date, bool deleted = false}) {
  final now = DateTime(2025, 1, 1).add(Duration(days: id));
  return RecordEntity(
    id: id,
    spaceId: spaceId,
    type: 'visit',
    date: date ?? now,
    title: 'Record $id',
    text: 'Note $id',
    tags: ['t$id'],
    createdAt: now,
    updatedAt: now,
    deletedAt: deleted ? now : null,
  );
}

void main() {
  test('builds context with space metadata and last 10 records only', () async {
    final records = List.generate(15, (i) => _record(i + 1));
    // Add other-space and deleted records to ensure filtering.
    records.add(_record(100, spaceId: 'other'));
    records.add(_record(200, deleted: true));

    final builder = SpaceContextBuilderImpl(
      recordsServiceFuture: Future.value(_FakeRecordsService(_FakeRecordsRepo(records))),
      spaceManager: _FakeSpaceManager(_space()),
      formatter: RecordSummaryFormatter(maxNoteLength: 50),
      maxRecords: 10,
    );

    final context = await builder.build('health');

    expect(context.spaceId, 'health');
    expect(context.spaceName, 'Health');
    expect(context.description, 'Health space');
    expect(context.categories, containsAll(['Visits', 'Labs']));
    expect(context.recentRecords.length, 10);
    // Should be newest first by date.
    expect(context.recentRecords.first.title, 'Record 15');
    // Deleted/other space excluded.
    expect(context.recentRecords.any((r) => r.title == 'Record 200'), isFalse);
    expect(context.recentRecords.any((r) => r.title == 'Record 100'), isFalse);
    // Summaries respect truncation length.
    expect(
      context.recentRecords.first.summary == null ||
          context.recentRecords.first.summary!.length <= RecordSummary.maxSummaryLength,
      isTrue,
    );
  });
}
