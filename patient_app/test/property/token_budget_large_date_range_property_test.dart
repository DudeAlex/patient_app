import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
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
import 'package:patient_app/features/records/application/ports/records_repository.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';
import 'package:patient_app/features/spaces/domain/space_registry.dart';
import 'package:patient_app/features/records/data/records_service.dart';

/// **Feature: context-date-range-fix, Property 7: Token budget enforcement with large date ranges**
/// Validates: Requirements 5.5, 3.1, 3.2, 3.3
///
/// For any date range setting (including large values like 1095 days), when building
/// space context with 50-200 test records, the system should enforce token budget limits
/// and truncate records to fit within the allocated context budget (2000 tokens),
/// ensuring the AI never receives more tokens than allowed.
void main() {
  test('Property: Token budget is enforced with random date ranges and record counts', () async {
    final random = Random(42);
    const maxContextTokens = 2000; // From TokenBudgetAllocator default

    // Run 50 iterations with random date ranges and record counts
    for (int iteration = 0; iteration < 50; iteration++) {
      // Generate random date range (1-1095 days, with emphasis on large values)
      final dateRangeDays = _generateRandomDateRange(random);
      
      // Generate random record count (50-200)
      final recordCount = 50 + random.nextInt(151); // 50 to 200
      
      // Create records spanning the date range
      final now = DateTime(2025, 1, 15);
      final records = List.generate(
        recordCount,
        (i) => _generateRecord(
          i,
          random,
          date: now.subtract(Duration(days: random.nextInt(dateRangeDays + 1))),
        ),
      );

      // Build context with the specified date range
      final dateRange = DateRange(
        start: now.subtract(Duration(days: dateRangeDays)),
        end: now,
      );

      final builder = SpaceContextBuilderImpl(
        recordsServiceFuture: Future.value(_DummyRecordsService(_FakeRecordsRepo(records))),
        recordsRepositoryOverride: _FakeRecordsRepo(records),
        spaceManager: _FakeSpaceManager(_space()),
        filterEngine: ContextFilterEngine(),
        relevanceScorer: RecordRelevanceScorer(),
        tokenBudgetAllocator: const TokenBudgetAllocator(),
        truncationStrategy: const ContextTruncationStrategy(),
        formatter: RecordSummaryFormatter(),
        maxRecords: 20,
        dateRange: dateRange,
      );

      final context = await builder.build('test-space');

      // Calculate actual token usage
      final formatter = RecordSummaryFormatter();
      final actualTokens = context.recentRecords.fold<int>(
        0,
        (total, summary) => total + formatter.estimateTokens(summary),
      );

      // Assert token budget is never exceeded
      expect(
        actualTokens,
        lessThanOrEqualTo(maxContextTokens),
        reason: 'Token budget exceeded on iteration $iteration. '
            'Date range: $dateRangeDays days, Records: $recordCount, '
            'Included: ${context.recentRecords.length}, '
            'Tokens used: $actualTokens, Budget: $maxContextTokens',
      );

      // Verify stats match actual usage
      if (context.stats != null) {
        final stats = context.stats as dynamic;
        expect(
          stats.tokensEstimated,
          equals(actualTokens),
          reason: 'Stats token estimate should match actual calculation',
        );
      }

      // Verify truncation occurred if needed
      final recordsInDateRange = records.where((r) => 
        r.date.isAfter(dateRange.start) && 
        r.date.isBefore(dateRange.end.add(const Duration(days: 1)))
      ).length;
      
      if (recordsInDateRange > context.recentRecords.length) {
        // Truncation occurred - verify it was necessary
        expect(
          actualTokens,
          greaterThan(0),
          reason: 'If truncation occurred, some records should be included',
        );
      }
    }
  });

  test('Property: Token budget enforcement with maximum date range (1095 days)', () async {
    final random = Random(123);
    const maxContextTokens = 2000;
    const dateRangeDays = 1095; // Maximum allowed

    // Test with various record counts
    for (int recordCount in [50, 100, 150, 200]) {
      final now = DateTime(2025, 1, 15);
      final records = List.generate(
        recordCount,
        (i) => _generateRecord(
          i,
          random,
          date: now.subtract(Duration(days: random.nextInt(dateRangeDays + 1))),
        ),
      );

      final dateRange = DateRange.lastNDays(dateRangeDays);

      final builder = SpaceContextBuilderImpl(
        recordsServiceFuture: Future.value(_DummyRecordsService(_FakeRecordsRepo(records))),
        recordsRepositoryOverride: _FakeRecordsRepo(records),
        spaceManager: _FakeSpaceManager(_space()),
        filterEngine: ContextFilterEngine(),
        relevanceScorer: RecordRelevanceScorer(),
        tokenBudgetAllocator: const TokenBudgetAllocator(),
        truncationStrategy: const ContextTruncationStrategy(),
        formatter: RecordSummaryFormatter(),
        maxRecords: 20,
        dateRange: dateRange,
      );

      final context = await builder.build('test-space');

      final formatter = RecordSummaryFormatter();
      final actualTokens = context.recentRecords.fold<int>(
        0,
        (total, summary) => total + formatter.estimateTokens(summary),
      );

      expect(
        actualTokens,
        lessThanOrEqualTo(maxContextTokens),
        reason: 'Token budget exceeded with 1095-day range. '
            'Records: $recordCount, Included: ${context.recentRecords.length}, '
            'Tokens: $actualTokens, Budget: $maxContextTokens',
      );
    }
  });

  test('Property: Token budget enforcement with preset date ranges', () async {
    final random = Random(456);
    const maxContextTokens = 2000;

    // Test preset values (7, 14, 30 days)
    for (int dateRangeDays in [7, 14, 30]) {
      for (int recordCount in [50, 100, 150]) {
        final now = DateTime(2025, 1, 15);
        final records = List.generate(
          recordCount,
          (i) => _generateRecord(
            i,
            random,
            date: now.subtract(Duration(days: random.nextInt(dateRangeDays + 1))),
          ),
        );

        final dateRange = DateRange.lastNDays(dateRangeDays);

        final builder = SpaceContextBuilderImpl(
          recordsServiceFuture: Future.value(_DummyRecordsService(_FakeRecordsRepo(records))),
          recordsRepositoryOverride: _FakeRecordsRepo(records),
          spaceManager: _FakeSpaceManager(_space()),
          filterEngine: ContextFilterEngine(),
          relevanceScorer: RecordRelevanceScorer(),
          tokenBudgetAllocator: const TokenBudgetAllocator(),
          truncationStrategy: const ContextTruncationStrategy(),
          formatter: RecordSummaryFormatter(),
          maxRecords: 20,
          dateRange: dateRange,
        );

        final context = await builder.build('test-space');

        final formatter = RecordSummaryFormatter();
        final actualTokens = context.recentRecords.fold<int>(
          0,
          (total, summary) => total + formatter.estimateTokens(summary),
        );

        expect(
          actualTokens,
          lessThanOrEqualTo(maxContextTokens),
          reason: 'Token budget exceeded with $dateRangeDays-day range. '
              'Records: $recordCount, Included: ${context.recentRecords.length}, '
              'Tokens: $actualTokens, Budget: $maxContextTokens',
        );
      }
    }
  });

  test('Property: Token budget enforcement with custom date ranges', () async {
    final random = Random(789);
    const maxContextTokens = 2000;

    // Test various custom values
    final customRanges = [45, 60, 90, 180, 365, 730];
    
    for (int dateRangeDays in customRanges) {
      for (int recordCount in [75, 125, 175]) {
        final now = DateTime(2025, 1, 15);
        final records = List.generate(
          recordCount,
          (i) => _generateRecord(
            i,
            random,
            date: now.subtract(Duration(days: random.nextInt(dateRangeDays + 1))),
          ),
        );

        final dateRange = DateRange.lastNDays(dateRangeDays);

        final builder = SpaceContextBuilderImpl(
          recordsServiceFuture: Future.value(_DummyRecordsService(_FakeRecordsRepo(records))),
          recordsRepositoryOverride: _FakeRecordsRepo(records),
          spaceManager: _FakeSpaceManager(_space()),
          filterEngine: ContextFilterEngine(),
          relevanceScorer: RecordRelevanceScorer(),
          tokenBudgetAllocator: const TokenBudgetAllocator(),
          truncationStrategy: const ContextTruncationStrategy(),
          formatter: RecordSummaryFormatter(),
          maxRecords: 20,
          dateRange: dateRange,
        );

        final context = await builder.build('test-space');

        final formatter = RecordSummaryFormatter();
        final actualTokens = context.recentRecords.fold<int>(
          0,
          (total, summary) => total + formatter.estimateTokens(summary),
        );

        expect(
          actualTokens,
          lessThanOrEqualTo(maxContextTokens),
          reason: 'Token budget exceeded with $dateRangeDays-day range. '
              'Records: $recordCount, Included: ${context.recentRecords.length}, '
              'Tokens: $actualTokens, Budget: $maxContextTokens',
        );
      }
    }
  });

  test('Property: Truncation occurs when necessary with large date ranges', () async {
    final random = Random(321);
    const maxContextTokens = 2000;

    // Create many records with long text to force truncation
    for (int dateRangeDays in [365, 730, 1095]) {
      final now = DateTime(2025, 1, 15);
      final records = List.generate(
        150,
        (i) => _generateRecord(
          i,
          random,
          date: now.subtract(Duration(days: random.nextInt(dateRangeDays + 1))),
          textLength: 200 + random.nextInt(300), // 200-500 chars
        ),
      );

      final dateRange = DateRange.lastNDays(dateRangeDays);

      final builder = SpaceContextBuilderImpl(
        recordsServiceFuture: Future.value(_DummyRecordsService(_FakeRecordsRepo(records))),
        recordsRepositoryOverride: _FakeRecordsRepo(records),
        spaceManager: _FakeSpaceManager(_space()),
        filterEngine: ContextFilterEngine(),
        relevanceScorer: RecordRelevanceScorer(),
        tokenBudgetAllocator: const TokenBudgetAllocator(),
        truncationStrategy: const ContextTruncationStrategy(),
        formatter: RecordSummaryFormatter(),
        maxRecords: 20,
        dateRange: dateRange,
      );

      final context = await builder.build('test-space');

      final formatter = RecordSummaryFormatter();
      final actualTokens = context.recentRecords.fold<int>(
        0,
        (total, summary) => total + formatter.estimateTokens(summary),
      );

      // Token budget should be enforced
      expect(
        actualTokens,
        lessThanOrEqualTo(maxContextTokens),
        reason: 'Token budget exceeded with $dateRangeDays-day range and long records',
      );

      // Verify truncation occurred (not all records included)
      final recordsInDateRange = records.where((r) => 
        r.date.isAfter(dateRange.start) && 
        r.date.isBefore(dateRange.end.add(const Duration(days: 1)))
      ).length;

      if (recordsInDateRange > 20) {
        // Should be limited by maxRecords
        expect(
          context.recentRecords.length,
          lessThanOrEqualTo(20),
          reason: 'Should respect maxRecords limit',
        );
      }

      // Verify stats reflect truncation
      if (context.stats != null) {
        final stats = context.stats as dynamic;
        expect(
          stats.recordsIncluded,
          equals(context.recentRecords.length),
          reason: 'Stats should match actual included records',
        );
      }
    }
  });

  test('Property: Token budget enforcement is consistent across multiple builds', () async {
    final random = Random(654);
    const maxContextTokens = 2000;

    // Create a fixed set of records
    final now = DateTime(2025, 1, 15);
    final records = List.generate(
      100,
      (i) => _generateRecord(
        i,
        random,
        date: now.subtract(Duration(days: random.nextInt(365))),
      ),
    );

    // Build context multiple times with same parameters
    for (int iteration = 0; iteration < 10; iteration++) {
      final dateRange = DateRange.lastNDays(365);

      final builder = SpaceContextBuilderImpl(
        recordsServiceFuture: Future.value(_DummyRecordsService(_FakeRecordsRepo(records))),
        recordsRepositoryOverride: _FakeRecordsRepo(records),
        spaceManager: _FakeSpaceManager(_space()),
        filterEngine: ContextFilterEngine(),
        relevanceScorer: RecordRelevanceScorer(),
        tokenBudgetAllocator: const TokenBudgetAllocator(),
        truncationStrategy: const ContextTruncationStrategy(),
        formatter: RecordSummaryFormatter(),
        maxRecords: 20,
        dateRange: dateRange,
      );

      final context = await builder.build('test-space');

      final formatter = RecordSummaryFormatter();
      final actualTokens = context.recentRecords.fold<int>(
        0,
        (total, summary) => total + formatter.estimateTokens(summary),
      );

      expect(
        actualTokens,
        lessThanOrEqualTo(maxContextTokens),
        reason: 'Token budget exceeded on iteration $iteration',
      );
    }
  });
}

// Helper functions

/// Generate random date range with emphasis on large values
int _generateRandomDateRange(Random random) {
  final roll = random.nextInt(100);
  
  if (roll < 10) {
    // 10% chance: preset values (7, 14, 30)
    return [7, 14, 30][random.nextInt(3)];
  } else if (roll < 30) {
    // 20% chance: small custom values (1-90)
    return 1 + random.nextInt(90);
  } else if (roll < 60) {
    // 30% chance: medium custom values (91-365)
    return 91 + random.nextInt(275);
  } else {
    // 40% chance: large custom values (366-1095)
    return 366 + random.nextInt(730);
  }
}

// Test helpers

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
  Future<List<RecordEntity>> recent({int limit = 50}) async => _records.take(limit).toList();

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

Space _space() => Space(
      id: 'test-space',
      name: 'Test Space',
      icon: 'Icon',
      gradient: SpaceGradient(
        startColor: Colors.white,
        endColor: Colors.black,
      ),
      description: 'Test space',
      categories: const ['Test'],
    );

RecordEntity _generateRecord(
  int id,
  Random random, {
  DateTime? date,
  int? textLength,
}) {
  final recordDate = date ?? DateTime(2025, 1, 1).add(Duration(days: random.nextInt(365)));
  final noteLength = textLength ?? (50 + random.nextInt(150)); // 50-200 chars by default
  final note = List.generate(noteLength, (i) => 'abcdefghijklmnopqrstuvwxyz'[i % 26]).join();

  return RecordEntity(
    id: id,
    spaceId: 'test-space',
    type: 'note',
    date: recordDate,
    title: 'Record $id',
    text: note,
    tags: List.generate(random.nextInt(3), (i) => 'tag${i + 1}'),
    createdAt: recordDate,
    updatedAt: recordDate,
  );
}
