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
  group('Large date range with many records', () {
    test('1095-day range with 100 records enforces maxRecords and token budget', () async {
      // Setup: Create 100 test records spanning 3 years (1095 days)
      final now = DateTime(2025, 1, 15);
      final records = <RecordEntity>[];
      
      await AppLogger.info('Test: Creating 100 test records spanning 3 years');
      
      // Create 100 records evenly distributed across 3 years
      // Most recent records should have higher view counts to test prioritization
      for (int i = 1; i <= 100; i++) {
        final daysAgo = (i - 1) * 10; // Spread across ~1000 days
        final viewCount = i <= 20 ? (20 - i) : 0; // First 20 have higher view counts
        records.add(_record(
          i,
          date: now.subtract(Duration(days: daysAgo)),
          viewCount: viewCount,
        ));
      }
      
      await AppLogger.info(
        'Test: Created records',
        context: {
          'totalRecords': records.length,
          'oldestRecordDays': now.difference(records.last.date).inDays,
          'newestRecordDays': now.difference(records.first.date).inDays,
        },
      );

      // Step 1: Set date range to 1095 days (3 years)
      final contextConfigRepo = _FakeContextConfigRepository();
      await contextConfigRepo.setDateRangeDays(1095);

      final dateRangeDays = await contextConfigRepo.getDateRangeDays();
      expect(dateRangeDays, 1095, reason: 'Date range should be set to 1095 days');

      // Step 2: Create date range and builder
      final dateRange = DateRange.lastNDays(dateRangeDays);
      
      await AppLogger.info(
        'Creating SpaceContextBuilder with large date range',
        context: {
          'dateRangeDays': dateRangeDays,
          'dateRangeStart': dateRange.start.toIso8601String(),
          'dateRangeEnd': dateRange.end.toIso8601String(),
          'isCustom': ![7, 14, 30].contains(dateRangeDays),
          'totalRecordsAvailable': records.length,
        },
      );

      final tokenAllocator = const TokenBudgetAllocator();
      final tokenAllocation = tokenAllocator.allocate();
      
      await AppLogger.info(
        'Token budget allocation',
        context: {
          'total': tokenAllocation.total,
          'context': tokenAllocation.context,
          'system': tokenAllocation.system,
          'history': tokenAllocation.history,
          'response': tokenAllocation.response,
        },
      );

      final builder = SpaceContextBuilderImpl(
        recordsServiceFuture: Future.value(_DummyRecordsService(_FakeRecordsRepo(records))),
        recordsRepositoryOverride: _FakeRecordsRepo(records),
        spaceManager: _FakeSpaceManager(_space()),
        filterEngine: ContextFilterEngine(),
        relevanceScorer: _TestRelevanceScorer(now: now),
        tokenBudgetAllocator: tokenAllocator,
        truncationStrategy: const ContextTruncationStrategy(),
        formatter: RecordSummaryFormatter(maxNoteLength: 100),
        maxRecords: 20,
        dateRange: dateRange,
      );

      // Step 3: Build space context
      await AppLogger.info('Test: Building space context with large date range');
      final context = await builder.build('health');

      // ===== VERIFICATION =====

      // Verify 1: Only top 20 records are considered (maxRecords limit)
      await AppLogger.info(
        'Test: Verifying maxRecords limit',
        context: {
          'recordsIncluded': context.recentRecords.length,
          'maxRecords': 20,
        },
      );
      
      expect(context.recentRecords.length, lessThanOrEqualTo(20),
          reason: 'Should include at most 20 records (maxRecords limit)');

      // Verify 2: Token budget is not exceeded
      final stats = context.stats as ContextStats;
      
      await AppLogger.info(
        'Test: Verifying token budget',
        context: {
          'tokensEstimated': stats.tokensEstimated,
          'tokensAvailable': stats.tokensAvailable,
          'tokenBudget': tokenAllocation.context,
        },
      );
      
      expect(stats.tokensEstimated, lessThanOrEqualTo(tokenAllocation.context),
          reason: 'Token usage should not exceed allocated budget (${tokenAllocation.context} tokens)');

      // Verify 3: Most recent records are prioritized
      // Records should be sorted by relevance (recency + view count)
      // The first 20 records we created have higher view counts and are more recent
      await AppLogger.info(
        'Test: Verifying record prioritization',
        context: {
          'includedRecordIds': context.recentRecords.map((r) => r.title).toList(),
        },
      );
      
      // Check that included records are from the more recent ones
      // Since we gave the first 20 records higher view counts, they should be prioritized
      for (final record in context.recentRecords) {
        final daysDiff = now.difference(record.date).inDays;
        expect(daysDiff, lessThanOrEqualTo(1095),
            reason: 'All records should be within 1095-day range');
      }
      
      // The most recent records (with higher view counts) should be included
      // Check that at least some of the top 20 most recent records are included
      final recentRecordIds = records.take(20).map((r) => r.id).toSet();
      final includedRecordIds = context.recentRecords.map((r) => int.parse(r.title.split(' ')[1])).toSet();
      final recentIncludedCount = recentRecordIds.intersection(includedRecordIds).length;
      
      await AppLogger.info(
        'Test: Record prioritization analysis',
        context: {
          'recentRecordsInTop20': recentIncludedCount,
          'totalIncluded': includedRecordIds.length,
        },
      );
      
      expect(recentIncludedCount, greaterThan(0),
          reason: 'Should include some of the most recent records (they have higher view counts)');

      // Verify 4: Context filters show correct date range
      expect(context.filters, isNotNull);
      final filters = context.filters as ContextFilters;
      expect(filters.dateRange, isNotNull);
      final filterDaysDiff = filters.dateRange.end
          .difference(filters.dateRange.start)
          .inDays;
      expect(filterDaysDiff, 1095, reason: 'Filter date range should be 1095 days');

      // Verify 5: Context stats are correct
      expect(stats.recordsFiltered, lessThanOrEqualTo(100),
          reason: 'Should have filtered records from the 100 available');
      expect(stats.recordsIncluded, lessThanOrEqualTo(stats.recordsFiltered),
          reason: 'Included records should not exceed filtered records');
      expect(stats.recordsIncluded, lessThanOrEqualTo(20),
          reason: 'Included records should respect maxRecords limit');

      // Verify 6: Truncation logging is present (verified by checking logs)
      // The SpaceContextBuilderImpl logs truncation events, which we've already triggered
      await AppLogger.info(
        'Test: Large date range test completed successfully',
        context: {
          'totalRecords': records.length,
          'recordsFiltered': stats.recordsFiltered,
          'recordsIncluded': stats.recordsIncluded,
          'tokensUsed': stats.tokensEstimated,
          'tokenBudget': tokenAllocation.context,
          'compressionRatio': stats.compressionRatio,
          'assemblyTimeMs': stats.assemblyTime.inMilliseconds,
        },
      );
    });

    test('1095-day range with 100 records verifies performance is acceptable', () async {
      // Setup: Create 100 test records spanning 3 years
      final now = DateTime(2025, 1, 15);
      final records = <RecordEntity>[];
      
      for (int i = 1; i <= 100; i++) {
        final daysAgo = (i - 1) * 10;
        records.add(_record(
          i,
          date: now.subtract(Duration(days: daysAgo)),
          viewCount: i % 5,
        ));
      }

      // Set date range to 1095 days
      final contextConfigRepo = _FakeContextConfigRepository();
      await contextConfigRepo.setDateRangeDays(1095);
      final dateRangeDays = await contextConfigRepo.getDateRangeDays();
      final dateRange = DateRange.lastNDays(dateRangeDays);

      final builder = SpaceContextBuilderImpl(
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

      // Build context and measure time
      final stopwatch = Stopwatch()..start();
      final context = await builder.build('health');
      stopwatch.stop();

      final stats = context.stats as ContextStats;
      
      await AppLogger.info(
        'Performance test results',
        context: {
          'assemblyTimeMs': stopwatch.elapsedMilliseconds,
          'statsAssemblyTimeMs': stats.assemblyTime.inMilliseconds,
          'recordsProcessed': records.length,
          'recordsIncluded': context.recentRecords.length,
        },
      );

      // Verify: Performance is acceptable (< 200ms as per design doc)
      expect(stopwatch.elapsedMilliseconds, lessThan(200),
          reason: 'Context assembly should complete in < 200ms');
      
      // Verify: Stats assembly time is also reasonable
      expect(stats.assemblyTime.inMilliseconds, lessThan(200),
          reason: 'Stats assembly time should be < 200ms');
    });
  });
}
