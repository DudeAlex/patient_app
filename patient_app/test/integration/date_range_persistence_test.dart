import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/context/record_summary_formatter.dart';
import 'package:patient_app/core/ai/chat/context/space_context_builder.dart';
import 'package:patient_app/core/ai/chat/context/context_filter_engine.dart';
import 'package:patient_app/core/ai/chat/context/record_relevance_scorer.dart';
import 'package:patient_app/core/ai/chat/context/context_truncation_strategy.dart';
import 'package:patient_app/core/ai/chat/context/token_budget_allocator.dart';
import 'package:patient_app/core/ai/chat/models/date_range.dart';
import 'package:patient_app/core/ai/chat/models/context_filters.dart';
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

/// Fake implementation of ContextConfigRepository that simulates persistence
/// This simulates SharedPreferences behavior where values persist across "restarts"
class _PersistentFakeContextConfigRepository implements ContextConfigRepository {
  // Simulates persistent storage (like SharedPreferences)
  static int? _persistedValue;
  
  @override
  Future<int> getDateRangeDays() async {
    final value = _persistedValue ?? 14; // Default to 14 if not set
    await AppLogger.info(
      'Read date range setting from repository',
      context: {
        'dateRangeDays': value,
        'isCustom': ![7, 14, 30].contains(value),
        'source': 'PersistentFakeRepository',
        'isPersisted': _persistedValue != null,
      },
    );
    return value;
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
    final previousValue = _persistedValue;
    _persistedValue = days;
    
    await AppLogger.info(
      'Date range setting saved to persistent storage',
      context: {
        'dateRangeDays': days,
        'previousValue': previousValue,
        'isCustom': ![7, 14, 30].contains(days),
      },
    );
  }
  
  /// Simulates clearing app data (for test cleanup)
  static void clearPersistence() {
    _persistedValue = null;
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
  group('Date range setting persistence', () {
    setUp(() {
      // Clear persistence before each test
      _PersistentFakeContextConfigRepository.clearPersistence();
    });

    tearDown(() {
      // Clean up after each test
      _PersistentFakeContextConfigRepository.clearPersistence();
    });

    test('Custom date range (90 days) persists across app restart', () async {
      // Setup: Create records spanning 180 days
      final now = DateTime(2025, 1, 15);
      final records = <RecordEntity>[
        // 30 records within last 90 days (should be included)
        for (int i = 1; i <= 30; i++)
          _record(
            i,
            date: now.subtract(Duration(days: i * 3)), // Spread across 90 days
            viewCount: i % 5,
          ),
        // 30 records older than 90 days (should be filtered out)
        for (int i = 31; i <= 60; i++)
          _record(
            i,
            date: now.subtract(Duration(days: 91 + (i - 30))),
            viewCount: 0,
          ),
      ];

      // Step 1: Set date range to custom value (90 days) in Settings
      await AppLogger.info('Test: Setting custom date range to 90 days');
      final contextConfigRepo = _PersistentFakeContextConfigRepository();
      await contextConfigRepo.setDateRangeDays(90);

      // Verify setting was saved
      var dateRangeDays = await contextConfigRepo.getDateRangeDays();
      expect(dateRangeDays, 90, reason: 'Date range should be set to 90 days');

      // Step 2: Build context with the setting (before "restart")
      await AppLogger.info('Test: Building context before restart');
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
      final recordCountBeforeRestart = context.recentRecords.length;

      // Verify records are filtered by 90-day range
      for (final record in context.recentRecords) {
        final daysDiff = now.difference(record.date).inDays;
        expect(daysDiff, lessThanOrEqualTo(90),
            reason: 'Record ${record.title} is ${daysDiff} days old, should be ≤ 90');
      }

      // Step 3: Simulate app restart by creating a new repository instance
      await AppLogger.info('Test: Simulating app restart');
      final contextConfigRepoAfterRestart = _PersistentFakeContextConfigRepository();

      // Step 4: Read date range setting after "restart"
      await AppLogger.info('Test: Reading date range after restart');
      dateRangeDays = await contextConfigRepoAfterRestart.getDateRangeDays();
      
      // Verify: Setting persisted across restart
      expect(dateRangeDays, 90, 
          reason: 'Date range should persist as 90 days after restart');

      // Step 5: Build context again with persisted setting
      await AppLogger.info('Test: Building context after restart');
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

      // Verify: 90-day range is still applied after restart
      expect(context.recentRecords.length, recordCountBeforeRestart,
          reason: 'Should have same number of records after restart');

      for (final record in context.recentRecords) {
        final daysDiff = now.difference(record.date).inDays;
        expect(daysDiff, lessThanOrEqualTo(90),
            reason: 'Record ${record.title} is ${daysDiff} days old, should be ≤ 90 after restart');
      }

      // Verify: Context filters show correct date range after restart
      expect(context.filters, isNotNull);
      final filters = context.filters as ContextFilters;
      expect(filters.dateRange, isNotNull);
      final filterDaysDiff = filters.dateRange.end
          .difference(filters.dateRange.start)
          .inDays;
      expect(filterDaysDiff, 90, 
          reason: 'Filter date range should be 90 days after restart');

      await AppLogger.info('Test: Persistence test completed successfully');
    });

    test('Preset date range (7 days) persists across app restart', () async {
      // Setup: Create records spanning 30 days
      final now = DateTime(2025, 1, 15);
      final records = <RecordEntity>[
        for (int i = 1; i <= 30; i++)
          _record(
            i,
            date: now.subtract(Duration(days: i)),
            viewCount: i % 3,
          ),
      ];

      // Step 1: Set date range to preset value (7 days)
      await AppLogger.info('Test: Setting preset date range to 7 days');
      final contextConfigRepo = _PersistentFakeContextConfigRepository();
      await contextConfigRepo.setDateRangeDays(7);

      var dateRangeDays = await contextConfigRepo.getDateRangeDays();
      expect(dateRangeDays, 7);

      // Step 2: Build context before restart
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
      final recordCountBeforeRestart = context.recentRecords.length;

      // Step 3: Simulate restart
      await AppLogger.info('Test: Simulating app restart');
      final contextConfigRepoAfterRestart = _PersistentFakeContextConfigRepository();

      // Step 4: Read setting after restart
      dateRangeDays = await contextConfigRepoAfterRestart.getDateRangeDays();
      expect(dateRangeDays, 7, 
          reason: 'Preset date range should persist as 7 days after restart');

      // Step 5: Build context after restart
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

      // Verify: Same behavior after restart
      expect(context.recentRecords.length, recordCountBeforeRestart);
      
      for (final record in context.recentRecords) {
        final daysDiff = now.difference(record.date).inDays;
        expect(daysDiff, lessThanOrEqualTo(7));
      }

      await AppLogger.info('Test: Preset persistence test completed successfully');
    });

    test('Default value (14 days) is used when no setting exists after restart', () async {
      // Setup: Create records spanning 30 days
      final now = DateTime(2025, 1, 15);
      final records = <RecordEntity>[
        for (int i = 1; i <= 30; i++)
          _record(
            i,
            date: now.subtract(Duration(days: i)),
            viewCount: i % 3,
          ),
      ];

      // Step 1: Create repository without setting any value (simulates fresh install)
      await AppLogger.info('Test: Creating repository without setting value');
      final contextConfigRepo = _PersistentFakeContextConfigRepository();

      // Step 2: Read date range (should get default)
      var dateRangeDays = await contextConfigRepo.getDateRangeDays();
      expect(dateRangeDays, 14, 
          reason: 'Should use default value (14 days) when no setting exists');

      // Step 3: Build context with default
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

      // Verify: 14-day range is applied
      for (final record in context.recentRecords) {
        final daysDiff = now.difference(record.date).inDays;
        expect(daysDiff, lessThanOrEqualTo(14));
      }

      // Step 4: Simulate restart
      await AppLogger.info('Test: Simulating restart without persisted value');
      final contextConfigRepoAfterRestart = _PersistentFakeContextConfigRepository();

      // Step 5: Read setting after restart (should still be default)
      dateRangeDays = await contextConfigRepoAfterRestart.getDateRangeDays();
      expect(dateRangeDays, 14, 
          reason: 'Should still use default value (14 days) after restart');

      await AppLogger.info('Test: Default value persistence test completed successfully');
    });
  });
}
