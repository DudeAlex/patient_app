import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/context/record_summary_formatter.dart';
import 'package:patient_app/core/ai/chat/context/space_context_builder.dart';
import 'package:patient_app/core/ai/chat/context/context_filter_engine.dart';
import 'package:patient_app/core/ai/chat/context/record_relevance_scorer.dart';
import 'package:patient_app/core/ai/chat/context/context_truncation_strategy.dart';
import 'package:patient_app/core/ai/chat/context/token_budget_allocator.dart';
import 'package:patient_app/core/ai/chat/models/date_range.dart';
import 'package:patient_app/core/ai/chat/models/context_filters.dart';
import 'package:patient_app/core/ai/chat/models/context_stats.dart';
import 'package:patient_app/core/ai/chat/repositories/context_config_repository.dart';
import 'package:patient_app/core/application/services/space_manager.dart';
import 'package:patient_app/core/application/ports/space_repository.dart';
import 'package:patient_app/core/domain/entities/space.dart';
import 'package:patient_app/core/domain/value_objects/space_gradient.dart';
import 'package:patient_app/features/records/application/ports/records_repository.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';
import 'package:patient_app/features/spaces/domain/space_registry.dart';
import 'package:flutter/material.dart';
import 'package:patient_app/features/records/data/records_service.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';

/// Fake implementation of ContextConfigRepository for testing
class _FakeContextConfigRepository implements ContextConfigRepository {
  int _dateRangeDays = 14;

  @override
  Future<int> getDateRangeDays() async {
    await AppLogger.info(
      'Read date range setting from repository',
      context: {
        'dateRangeDays': _dateRangeDays,
        'isCustom': ![7, 14, 30].contains(_dateRangeDays),
        'source': 'FakeRepository',
      },
    );
    return _dateRangeDays;
  }

  @override
  Future<void> setDateRangeDays(int days) async {
    if (days < 1 || days > 1095) {
      throw ArgumentError.value(
        days,
        'days',
        'Date range must be between 1 and 1095 days (approximately 3 years)',
      );
    }
    final previousValue = _dateRangeDays;
    _dateRangeDays = days;
    
    await AppLogger.info(
      'Date range setting saved',
      context: {
        'dateRangeDays': days,
        'previousValue': previousValue,
        'isCustom': ![7, 14, 30].contains(days),
      },
    );
  }
}

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
  group('Date range setting changes', () {
    test('Changing from 7 days to 1095 days is immediately effective', () async {
      // Setup: Create records spanning 60 days
      final now = DateTime(2025, 1, 15);
      final records = <RecordEntity>[
        for (int i = 1; i <= 60; i++)
          _record(
            i,
            date: now.subtract(Duration(days: i)),
            viewCount: i % 5,
          ),
      ];

      final contextConfigRepo = _FakeContextConfigRepository();

      // Step 1: Set date range to 7 days
      await contextConfigRepo.setDateRangeDays(7);
      var dateRangeDays = await contextConfigRepo.getDateRangeDays();
      expect(dateRangeDays, 7);

      var dateRange = DateRange.lastNDays(dateRangeDays);
      var builder = SpaceContextBuilderImpl(
        recordsServiceFuture: Future.value(_DummyRecordsService(_FakeRecordsRepo(records))),
        recordsRepositoryOverride: _FakeRecordsRepo(records),
        spaceManager: _FakeSpaceManager(_space()),
        filterEngine: ContextFilterEngine(),
        relevanceScorer: _TestRelevanceScorer(now: now),
        tokenBudgetAllocator: const TokenBudgetAllocator(),
        truncationStrategy: const ContextTruncationStrategy(),
        formatter: RecordSummaryFormatter(maxNoteLength: 100),
        maxRecords: 20,
        dateRange: dateRange,
      );

      var context = await builder.build('health');
      final sevenDayCount = context.recentRecords.length;
      
      // Verify 7-day range
      for (final record in context.recentRecords) {
        final daysDiff = now.difference(record.date).inDays;
        expect(daysDiff, lessThanOrEqualTo(7));
      }

      // Step 2: Change to 1095 days
      await contextConfigRepo.setDateRangeDays(1095);
      dateRangeDays = await contextConfigRepo.getDateRangeDays();
      expect(dateRangeDays, 1095);

      dateRange = DateRange.lastNDays(dateRangeDays);
      builder = SpaceContextBuilderImpl(
        recordsServiceFuture: Future.value(_DummyRecordsService(_FakeRecordsRepo(records))),
        recordsRepositoryOverride: _FakeRecordsRepo(records),
        spaceManager: _FakeSpaceManager(_space()),
        filterEngine: ContextFilterEngine(),
        relevanceScorer: _TestRelevanceScorer(now: now),
        tokenBudgetAllocator: const TokenBudgetAllocator(),
        truncationStrategy: const ContextTruncationStrategy(),
        formatter: RecordSummaryFormatter(maxNoteLength: 100),
        maxRecords: 20,
        dateRange: dateRange,
      );

      context = await builder.build('health');
      final maxDayCount = context.recentRecords.length;
      
      // Verify 30-day range is now applied
      for (final record in context.recentRecords) {
        final daysDiff = now.difference(record.date).inDays;
        expect(daysDiff, lessThanOrEqualTo(1095));
      }

      // Verify that the setting change is effective
      // Either we have more records with 30-day range, or both are capped at maxRecords
      expect(maxDayCount, greaterThanOrEqualTo(sevenDayCount),
          reason: '30-day range should include at least as many records as 7-day range');
      
      // If we have records in both ranges, verify the date range actually changed
      if (sevenDayCount > 0 && maxDayCount > 0) {
        final stats = context.stats as ContextStats;
        expect(stats.recordsFiltered, greaterThanOrEqualTo(sevenDayCount),
            reason: '30-day filter should find at least as many records as 7-day filter');
      }
    });
  });
}

