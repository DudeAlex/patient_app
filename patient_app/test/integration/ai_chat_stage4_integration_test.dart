import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/context/record_summary_formatter.dart';
import 'package:patient_app/core/ai/chat/context/space_context_builder.dart';
import 'package:patient_app/core/ai/chat/context/context_filter_engine.dart';
import 'package:patient_app/core/ai/chat/context/record_relevance_scorer.dart';
import 'package:patient_app/core/ai/chat/context/context_truncation_strategy.dart';
import 'package:patient_app/core/ai/chat/context/token_budget_allocator.dart';
import 'package:patient_app/core/ai/chat/models/date_range.dart';
import 'package:patient_app/core/application/services/space_manager.dart';
import 'package:patient_app/core/application/ports/space_repository.dart';
import 'package:patient_app/core/domain/entities/space.dart';
import 'package:patient_app/core/domain/value_objects/space_gradient.dart';
import 'package:patient_app/core/ai/chat/models/record_summary.dart';
import 'package:patient_app/features/records/application/ports/records_repository.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';
import 'package:patient_app/features/spaces/domain/space_registry.dart';
import 'package:flutter/material.dart';
import 'package:patient_app/features/records/data/records_service.dart';

class _FakeSpaceRepo implements SpaceRepository {
  _FakeSpaceRepo(this.space);
  final Space space;
  @override
  Future<List<String>> getActiveSpaceIds() async => [space.id];
  @override
  Future<String> getCurrentSpaceId() async => space.id;
  @override
  Future<void> setActiveSpaceIds(List<String> ids) async {}
  @override
  Future<void> setCurrentSpaceId(String id) async {}
  @override
  Future<Map<String, Space>> getCustomSpaces() async => {};
  @override
  Future<void> deleteCustomSpace(String spaceId) async {}
  @override
  Future<void> saveCustomSpace(Space space) async {}
  @override
  Future<bool> spaceExists(String spaceId) async => spaceId == space.id;
  @override
  Future<bool> hasCompletedOnboarding() async => true;
  @override
  Future<void> setOnboardingComplete() async {}
}

class _FakeSpaceRegistry extends SpaceRegistry {
  _FakeSpaceRegistry(this.space);
  final Space space;

  @override
  Space? getDefaultSpace(String id) => space.id == id ? space : null;
}

class _FakeSpaceManager extends SpaceManager {
  _FakeSpaceManager(Space space)
      : _space = space,
        super(
          _FakeSpaceRepo(space),
          _FakeSpaceRegistry(space),
        );
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
      _records.cast<RecordEntity?>().firstWhere((r) => r?.id == id, orElse: () => null);
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
      gradient: SpaceGradient(
        startColor: Colors.white,
        endColor: Colors.black,
      ),
      description: 'Health space',
      categories: const ['Visit', 'Lab'],
    );

RecordEntity _record(
  int id, {
  String spaceId = 'health',
  required DateTime date,
  int viewCount = 0,
}) {
  return RecordEntity(
    id: id,
    spaceId: spaceId,
    type: 'visit',
    date: date,
    title: 'Record $id',
    text: 'Note $id ' * 5,
    tags: ['t$id'],
    createdAt: date,
    updatedAt: date,
    viewCount: viewCount,
  );
}

void main() {
  test('Stage 4 integration: date filtering, relevance scoring, and token optimization', () async {
    // Create 50 records with various dates
    final now = DateTime(2025, 1, 15);
    final records = <RecordEntity>[
      // 20 records within last 14 days (should be included)
      for (int i = 1; i <= 20; i++)
        _record(
          i,
          date: now.subtract(Duration(days: i)),
          viewCount: i % 5, // Varying access counts
        ),
      // 30 records older than 14 days (should be filtered out)
      for (int i = 21; i <= 50; i++)
        _record(
          i,
          date: now.subtract(Duration(days: 15 + (i - 20))),
          viewCount: 0,
        ),
    ];

    final builder = SpaceContextBuilderImpl(
      recordsServiceFuture: Future.value(_DummyRecordsService(_FakeRecordsRepo(records))),
      recordsRepositoryOverride: _FakeRecordsRepo(records),
      spaceManager: _FakeSpaceManager(_space()),
      filterEngine: ContextFilterEngine(),
      relevanceScorer: _TestRelevanceScorer(now: now),
      tokenBudgetAllocator: TokenBudgetAllocator(totalBudget: 4800),
      truncationStrategy: const ContextTruncationStrategy(),
      formatter: RecordSummaryFormatter(maxNoteLength: 100),
      maxRecords: 20,
      dateRange: DateRange(
        start: now.subtract(const Duration(days: 14)),
        end: now,
      ),
    );

    final context = await builder.build('health');

    // Verify space metadata
    expect(context.spaceId, 'health');
    expect(context.spaceName, 'Health');
    expect(context.description, 'Health space');
    expect(context.categories, containsAll(['Visit', 'Lab']));

    // Verify date filtering: only records from last 14 days
    expect(context.recentRecords.length, lessThanOrEqualTo(20));
    for (final record in context.recentRecords) {
      final recordDate = DateTime.parse(record.date);
      final daysDiff = now.difference(recordDate).inDays;
      expect(daysDiff, lessThanOrEqualTo(14),
          reason: 'Record ${record.title} is ${daysDiff} days old, should be ≤ 14');
    }

    // Verify relevance scoring: more recent records should be first
    if (context.recentRecords.length > 1) {
      final firstDate = DateTime.parse(context.recentRecords.first.date);
      final lastDate = DateTime.parse(context.recentRecords.last.date);
      expect(firstDate.isAfter(lastDate) || firstDate.isAtSameMomentAs(lastDate), isTrue,
          reason: 'Records should be sorted by relevance (most recent first)');
    }

    // Verify token budget optimization: should not exceed max records
    expect(context.recentRecords.length, lessThanOrEqualTo(20),
        reason: 'Should not exceed maxRecords limit');

    // Verify context stats are generated
    expect(context.stats, isNotNull, reason: 'Context stats should be generated');
    expect(context.stats!.recordsFiltered, 50, reason: 'Should have filtered all 50 records');
    expect(context.stats!.recordsIncluded, context.recentRecords.length,
        reason: 'recordsIncluded should match actual included count');
    expect(context.stats!.tokensEstimated, greaterThan(0),
        reason: 'Should estimate token usage');
    expect(context.stats!.tokensAvailable, greaterThan(0),
        reason: 'Should track available tokens');
    expect(context.stats!.assemblyTime.inMilliseconds, greaterThan(0),
        reason: 'Should track assembly time');

    // Verify summaries are truncated
    expect(
      context.recentRecords.every(
        (r) => r.summary == null || r.summary!.length <= RecordSummary.maxSummaryLength,
      ),
      isTrue,
      reason: 'All summaries should be truncated to max length',
    );

    // Verify filters are included
    expect(context.filters, isNotNull, reason: 'Filters should be included');
    expect(context.filters!.maxRecords, 20);
    expect(context.filters!.spaceId, 'health');

    // Verify token allocation is included
    expect(context.tokenAllocation, isNotNull, reason: 'Token allocation should be included');
    expect(context.tokenAllocation!.total, 4800);
    expect(context.tokenAllocation!.response, 1000);
  });

  test('Stage 4 integration: handles empty record set gracefully', () async {
    final now = DateTime(2025, 1, 15);
    final records = <RecordEntity>[];

    final builder = SpaceContextBuilderImpl(
      recordsServiceFuture: Future.value(_DummyRecordsService(_FakeRecordsRepo(records))),
      recordsRepositoryOverride: _FakeRecordsRepo(records),
      spaceManager: _FakeSpaceManager(_space()),
      filterEngine: ContextFilterEngine(),
      relevanceScorer: _TestRelevanceScorer(now: now),
      tokenBudgetAllocator: TokenBudgetAllocator(totalBudget: 4800),
      truncationStrategy: const ContextTruncationStrategy(),
      formatter: RecordSummaryFormatter(maxNoteLength: 100),
      maxRecords: 20,
      dateRange: DateRange(
        start: now.subtract(const Duration(days: 14)),
        end: now,
      ),
    );

    final context = await builder.build('health');

    expect(context.recentRecords, isEmpty);
    expect(context.stats, isNotNull);
    expect(context.stats!.recordsFiltered, 0);
    expect(context.stats!.recordsIncluded, 0);
  });
}

class _DummyRecordsService extends Fake implements RecordsService {
  _DummyRecordsService(this.records);
  @override
  final RecordsRepository records;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestRelevanceScorer extends RecordRelevanceScorer {
  _TestRelevanceScorer({required this.now});
  final DateTime now;

  @override
  Future<List<RecordEntity>> sortByRelevance(
    List<RecordEntity> records, {
    DateTime? now,
    Map<int, int>? accessCounts,
  }) {
    return super.sortByRelevance(
      records,
      now: this.now,
      accessCounts: accessCounts,
    );
  }
}
