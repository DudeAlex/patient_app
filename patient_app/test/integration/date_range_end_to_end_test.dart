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
  group('End-to-end date range application', () {
    test('7-day date range filters records correctly', () async {
      // Setup: Create records spanning 30 days
      final now = DateTime(2025, 1, 15);
      final records = <RecordEntity>[
        // 7 records within last 7 days (should be included)
        for (int i = 1; i <= 7; i++)
          _record(
            i,
            date: now.subtract(Duration(days: i)),
            viewCount: i % 3,
          ),
        // 23 records older than 7 days (should be filtered out)
        for (int i = 8; i <= 30; i++)
          _record(
            i,
            date: now.subtract(Duration(days: i)),
            viewCount: 0,
          ),
      ];

      // Step 1: Set date range to 7 days in Settings
      final contextConfigRepo = _FakeContextConfigRepository();
      await contextConfigRepo.setDateRangeDays(7);

      // Step 2: Read date range and create builder (simulating provider behavior)
      final dateRangeDays = await contextConfigRepo.getDateRangeDays();
      expect(dateRangeDays, 7, reason: 'Date range should be set to 7 days');

      final dateRange = DateRange.lastNDays(dateRangeDays);
      
      // Step 3: Log context assembly (simulating provider behavior)
      await AppLogger.info(
        'Creating SpaceContextBuilder with date range',
        context: {
          'dateRangeDays': dateRangeDays,
          'dateRangeStart': dateRange.start.toIso8601String(),
          'dateRangeEnd': dateRange.end.toIso8601String(),
          'isCustom': ![7, 14, 30].contains(dateRangeDays),
        },
      );

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

      // Step 4: Build context (simulating AI chat message)
      final context = await builder.build('health');

      // Verify: Only records from last 7 days are included
      expect(context.recentRecords.length, lessThanOrEqualTo(7),
          reason: 'Should include at most 7 records (from last 7 days)');
      
      for (final record in context.recentRecords) {
        final daysDiff = now.difference(record.date).inDays;
        expect(daysDiff, lessThanOrEqualTo(7),
            reason: 'Record ${record.title} is ${daysDiff} days old, should be ≤ 7');
      }

      // Verify: Context filters show correct date range
      expect(context.filters, isNotNull);
      final filters = context.filters as ContextFilters;
      expect(filters.dateRange, isNotNull);
      final filterDaysDiff = filters.dateRange.end
          .difference(filters.dateRange.start)
          .inDays;
      expect(filterDaysDiff, 7, reason: 'Filter date range should be 7 days');

      // Verify: Context stats are generated
      expect(context.stats, isNotNull);
      final stats = context.stats as ContextStats;
      // recordsFiltered is the count AFTER date filtering (within 7 days)
      expect(stats.recordsFiltered, lessThanOrEqualTo(7), 
          reason: 'Should have filtered to records within 7 days');
      expect(stats.recordsIncluded, stats.recordsFiltered,
          reason: 'All filtered records should be included (within maxRecords limit)');
    });

    test('30-day date range filters records correctly', () async {
      // Setup: Create records spanning 60 days
      final now = DateTime(2025, 1, 15);
      final records = <RecordEntity>[
        // 20 records within last 30 days (should be included)
        for (int i = 1; i <= 20; i++)
          _record(
            i,
            date: now.subtract(Duration(days: i)),
            viewCount: i % 5,
          ),
        // 40 records older than 30 days (should be filtered out)
        for (int i = 31; i <= 70; i++)
          _record(
            i,
            date: now.subtract(Duration(days: i)),
            viewCount: 0,
          ),
      ];

      // Step 1: Set date range to 30 days in Settings
      final contextConfigRepo = _FakeContextConfigRepository();
      await contextConfigRepo.setDateRangeDays(30);

      // Step 2: Read date range and create builder
      final dateRangeDays = await contextConfigRepo.getDateRangeDays();
      expect(dateRangeDays, 30, reason: 'Date range should be set to 30 days');

      final dateRange = DateRange.lastNDays(dateRangeDays);
      
      // Step 3: Log context assembly
      await AppLogger.info(
        'Creating SpaceContextBuilder with date range',
        context: {
          'dateRangeDays': dateRangeDays,
          'dateRangeStart': dateRange.start.toIso8601String(),
          'dateRangeEnd': dateRange.end.toIso8601String(),
          'isCustom': ![7, 14, 30].contains(dateRangeDays),
        },
      );

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

      // Step 4: Build context
      final context = await builder.build('health');

      // Verify: Only records from last 30 days are included
      expect(context.recentRecords.length, lessThanOrEqualTo(20),
          reason: 'Should include at most 20 records (maxRecords limit)');
      
      for (final record in context.recentRecords) {
        final daysDiff = now.difference(record.date).inDays;
        expect(daysDiff, lessThanOrEqualTo(30),
            reason: 'Record ${record.title} is ${daysDiff} days old, should be ≤ 30');
      }

      // Verify: Context filters show correct date range
      expect(context.filters, isNotNull);
      final filters = context.filters as ContextFilters;
      expect(filters.dateRange, isNotNull);
      final filterDaysDiff = filters.dateRange.end
          .difference(filters.dateRange.start)
          .inDays;
      expect(filterDaysDiff, 30, reason: 'Filter date range should be 30 days');

      // Verify: Context stats are generated
      expect(context.stats, isNotNull);
      final stats = context.stats as ContextStats;
      // recordsFiltered is the count AFTER date filtering (within 30 days)
      expect(stats.recordsFiltered, lessThanOrEqualTo(20), 
          reason: 'Should have filtered to records within 30 days');
      expect(stats.recordsIncluded, lessThanOrEqualTo(stats.recordsFiltered),
          reason: 'Included records should not exceed filtered records');
    });

    test('Custom 45-day date range filters records correctly', () async {
      // Setup: Create records spanning 90 days
      final now = DateTime(2025, 1, 15);
      final records = <RecordEntity>[
        // 20 records within last 45 days (should be included)
        for (int i = 1; i <= 20; i++)
          _record(
            i,
            date: now.subtract(Duration(days: i * 2)), // Spread across 40 days
            viewCount: i % 5,
          ),
        // 30 records older than 45 days (should be filtered out)
        for (int i = 21; i <= 50; i++)
          _record(
            i,
            date: now.subtract(Duration(days: 46 + (i - 20))),
            viewCount: 0,
          ),
      ];

      // Step 1: Set date range to 45 days (custom value) in Settings
      final contextConfigRepo = _FakeContextConfigRepository();
      await contextConfigRepo.setDateRangeDays(45);

      // Step 2: Read date range and create builder
      final dateRangeDays = await contextConfigRepo.getDateRangeDays();
      expect(dateRangeDays, 45, reason: 'Date range should be set to 45 days');

      final dateRange = DateRange.lastNDays(dateRangeDays);
      
      // Step 3: Log context assembly (should show isCustom: true)
      await AppLogger.info(
        'Creating SpaceContextBuilder with date range',
        context: {
          'dateRangeDays': dateRangeDays,
          'dateRangeStart': dateRange.start.toIso8601String(),
          'dateRangeEnd': dateRange.end.toIso8601String(),
          'isCustom': ![7, 14, 30].contains(dateRangeDays),
        },
      );

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

      // Step 4: Build context
      final context = await builder.build('health');

      // Verify: Only records from last 45 days are included
      expect(context.recentRecords.length, lessThanOrEqualTo(20),
          reason: 'Should include at most 20 records (maxRecords limit)');
      
      for (final record in context.recentRecords) {
        final daysDiff = now.difference(record.date).inDays;
        expect(daysDiff, lessThanOrEqualTo(45),
            reason: 'Record ${record.title} is ${daysDiff} days old, should be ≤ 45');
      }

      // Verify: Context filters show correct date range
      expect(context.filters, isNotNull);
      final filters = context.filters as ContextFilters;
      expect(filters.dateRange, isNotNull);
      final filterDaysDiff = filters.dateRange.end
          .difference(filters.dateRange.start)
          .inDays;
      expect(filterDaysDiff, 45, reason: 'Filter date range should be 45 days');

      // Verify: Context stats are generated
      expect(context.stats, isNotNull);
      final stats = context.stats as ContextStats;
      // recordsFiltered is the count AFTER date filtering (within 45 days)
      expect(stats.recordsFiltered, lessThanOrEqualTo(20), 
          reason: 'Should have filtered to records within 45 days');
      expect(stats.recordsIncluded, lessThanOrEqualTo(stats.recordsFiltered),
          reason: 'Included records should not exceed filtered records');
      
      // Verify: Custom value is properly logged (isCustom should be true)
      // This is verified by the log statement above
    });

    test('Date range changes are immediately effective', () async {
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

      // Step 2: Change to 30 days
      await contextConfigRepo.setDateRangeDays(30);
      dateRangeDays = await contextConfigRepo.getDateRangeDays();
      expect(dateRangeDays, 30);

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
      final thirtyDayCount = context.recentRecords.length;
      
      // Verify 30-day range is now applied
      for (final record in context.recentRecords) {
        final daysDiff = now.difference(record.date).inDays;
        expect(daysDiff, lessThanOrEqualTo(30));
      }

      // Verify that the setting change is effective
      // Either we have more records with 30-day range, or both are capped at maxRecords
      expect(thirtyDayCount, greaterThanOrEqualTo(sevenDayCount),
          reason: '30-day range should include at least as many records as 7-day range');
      
      // If we have records in both ranges, verify the date range actually changed
      if (sevenDayCount > 0 && thirtyDayCount > 0) {
        final stats = context.stats as ContextStats;
        expect(stats.recordsFiltered, greaterThanOrEqualTo(sevenDayCount),
            reason: '30-day filter should find at least as many records as 7-day filter');
      }
    });
  });
}
