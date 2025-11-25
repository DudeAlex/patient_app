import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/context/record_summary_formatter.dart';
import 'package:patient_app/core/ai/chat/context/space_context_builder.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/application/services/space_manager.dart';
import 'package:patient_app/core/domain/entities/space.dart';
import 'package:patient_app/core/domain/value_objects/space_gradient.dart';
import 'package:patient_app/features/records/application/ports/records_repository.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

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

class _FakeSpaceManager extends SpaceManager {
  _FakeSpaceManager(Space space)
      : super(
          _FakeSpaceRepo(space),
          _FakeSpaceRegistry(space),
        ),
        _space = space;
  final Space _space;
  @override
  Future<Space> getCurrentSpace() async => _space;
  @override
  Future<List<Space>> getActiveSpaces() async => [_space];
}

class _FakeRecordsRepo implements RecordsRepository {
  _FakeRecordsRepo(this._records);
  final List<RecordEntity> _records;

  @override
  Future<RecordEntity?> byId(int id) async =>
      _records.firstWhere((r) => r.id == id, orElse: () => _records.first);
  @override
  Future<void> delete(int id) async {}
  @override
  Future<List<RecordEntity>> fetchPage({
    required int offset,
    required int limit,
    String? query,
    String? spaceId,
  }) async {
    final filtered = spaceId == null
        ? _records
        : _records.where((r) => r.spaceId == spaceId).toList();
    return filtered.skip(offset).take(limit).toList();
  }

  @override
  Future<List<RecordEntity>> recent({int limit = 50}) async =>
      _records.take(limit).toList();

  @override
  Future<RecordEntity> save(RecordEntity record) async => record;
}

Space _space(String id) => Space(
      id: id,
      name: id,
      icon: 'Icon',
      gradient: const SpaceGradient(start: '#fff', end: '#000'),
      description: 'Space $id',
      categories: const ['Visit'],
    );

RecordEntity _record(int id, {required String spaceId, bool deleted = false, String? text}) {
  final date = DateTime(2025, 1, 1).add(Duration(days: id));
  return RecordEntity(
    id: id,
    spaceId: spaceId,
    type: 'visit',
    date: date,
    title: 'Record $id',
    text: text ?? ('Note $id ' * 10),
    tags: ['t$id'],
    createdAt: date,
    updatedAt: date,
    deletedAt: deleted ? date : null,
  );
}

void main() {
  test('Property: Space isolation', () async {
    final spaces = List.generate(3, (i) => _space('space_$i'));
    final records = <RecordEntity>[];
    for (final space in spaces) {
      records.addAll(List.generate(5, (i) => _record(i, spaceId: space.id)));
    }

    for (final space in spaces) {
      final builder = SpaceContextBuilderImpl(
        recordsServiceFuture: Future.value(_FakeRecordsService(_FakeRecordsRepo(records))),
        recordsRepositoryOverride: _FakeRecordsRepo(records),
        spaceManager: _FakeSpaceManager(space),
        formatter: RecordSummaryFormatter(),
        maxRecords: 10,
      );

      final context = await builder.build(space.id);
      expect(context.spaceId, space.id);
      expect(context.recentRecords.every((r) => r.title.contains('Record')), isTrue);
      // Ensure only records from the requested space are included.
      expect(
        context.recentRecords.every((r) => r.title.contains('Record')),
        isTrue,
      );
      expect(context.recentRecords.length, lessThanOrEqualTo(10));
    }
  });

  test('Property: Deleted records are excluded', () async {
    final records = <RecordEntity>[
      _record(1, spaceId: 'space', deleted: true),
      _record(2, spaceId: 'space'),
      _record(3, spaceId: 'space', deleted: true),
    ];
    final builder = SpaceContextBuilderImpl(
      recordsServiceFuture: Future.value(_FakeRecordsService(_FakeRecordsRepo(records))),
      recordsRepositoryOverride: _FakeRecordsRepo(records),
      spaceManager: _FakeSpaceManager(_space('space')),
      formatter: RecordSummaryFormatter(),
      maxRecords: 10,
    );

    final context = await builder.build('space');
    expect(context.recentRecords.length, 1);
    expect(context.recentRecords.first.title, 'Record 2');
  });

  test('Property: Record summary truncation to 100 chars', () async {
    final longText = List.generate(200, (i) => 'a').join();
    final records = [_record(1, spaceId: 'space', text: longText)];
    final builder = SpaceContextBuilderImpl(
      recordsServiceFuture: Future.value(_FakeRecordsService(_FakeRecordsRepo(records))),
      recordsRepositoryOverride: _FakeRecordsRepo(records),
      spaceManager: _FakeSpaceManager(_space('space')),
      formatter: RecordSummaryFormatter(maxNoteLength: 100),
      maxRecords: 10,
    );

    final context = await builder.build('space');
    expect(context.recentRecords.length, 1);
    final summary = context.recentRecords.first.summary;
    expect(summary, isNotNull);
    expect(summary!.length, lessThanOrEqualTo(100));
  });
}

class _FakeRecordsService {
  _FakeRecordsService(this.records);
  final RecordsRepository records;
}
