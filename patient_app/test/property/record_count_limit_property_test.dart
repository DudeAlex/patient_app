import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/context/record_summary_formatter.dart';
import 'package:patient_app/core/ai/chat/context/space_context_builder.dart';
import 'package:patient_app/core/ai/chat/context/context_filter_engine.dart';
import 'package:patient_app/core/ai/chat/context/record_relevance_scorer.dart';
import 'package:patient_app/core/ai/chat/context/context_truncation_strategy.dart';
import 'package:patient_app/core/ai/chat/context/token_budget_allocator.dart';
import 'package:patient_app/core/ai/chat/models/date_range.dart';
import 'package:patient_app/core/ai/chat/models/intent_retrieval_config.dart';
import 'package:patient_app/core/ai/chat/domain/services/intent_driven_retriever.dart';
import 'package:patient_app/core/ai/chat/domain/services/query_analyzer.dart';
import 'package:patient_app/core/ai/chat/domain/services/relevance_scorer.dart';
import 'package:patient_app/core/ai/chat/domain/services/privacy_filter.dart';
import 'package:patient_app/core/ai/chat/domain/services/keyword_extractor.dart';
import 'package:patient_app/core/ai/chat/domain/services/intent_classifier.dart';
import 'package:patient_app/core/application/services/space_manager.dart';
import 'package:patient_app/core/application/ports/space_repository.dart';
import 'package:patient_app/core/domain/entities/space.dart';
import 'package:patient_app/core/domain/value_objects/space_gradient.dart';
import 'package:patient_app/features/records/application/ports/records_repository.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';
import 'package:patient_app/features/spaces/domain/space_registry.dart';
import 'package:flutter/material.dart';
import 'package:patient_app/features/records/data/records_service.dart';

/// Property 6: Record Count Limit
/// Validates: Requirements 5.1
///
/// For any large record set (50-100 records), when building optimized context,
/// the number of included records should not exceed the maximum limit (20).
void main() {
  test('Property: Record count never exceeds maximum limit', () async {
    final random = Random(42);

    // Test with various record set sizes
    for (int totalRecords in [50, 75, 100, 150]) {
      final records = List.generate(
        totalRecords,
        (i) => _generateRecord(i, random),
      );

      final builder = SpaceContextBuilderImpl(
        recordsServiceFuture: Future.value(_DummyRecordsService(_FakeRecordsRepo(records))),
        recordsRepositoryOverride: _FakeRecordsRepo(records),
        spaceManager: _FakeSpaceManager(_space()),
        filterEngine: ContextFilterEngine(),
        relevanceScorer: RecordRelevanceScorer(),
        tokenBudgetAllocator: const TokenBudgetAllocator(),
        truncationStrategy: const ContextTruncationStrategy(),
        intentDrivenRetriever: IntentDrivenRetriever(
          relevanceScorer: RelevanceScorer(),
          privacyFilter: PrivacyFilter(),
          config: const IntentRetrievalConfig(),
        ),
        queryAnalyzer: QueryAnalyzer(
          keywordExtractor: KeywordExtractor(),
          intentClassifier: IntentClassifier(),
        ),
        intentRetrievalConfig: const IntentRetrievalConfig(),
        formatter: RecordSummaryFormatter(),
        maxRecords: 20,
        dateRange: DateRange(
          start: DateTime(2020, 1, 1),
          end: DateTime(2030, 1, 1),
        ),
      );

      final context = await builder.build('test-space');

      expect(
        context.recentRecords.length,
        lessThanOrEqualTo(20),
        reason: 'Context should not exceed 20 records. '
            'Total records: $totalRecords, Included: ${context.recentRecords.length}',
      );
    }
  });

  test('Property: Record count respects maxRecords parameter', () async {
    final random = Random(123);
    final records = List.generate(100, (i) => _generateRecord(i, random));

    // Test with different maxRecords values
    for (int maxRecords in [5, 10, 15, 20, 25]) {
      final builder = SpaceContextBuilderImpl(
        recordsServiceFuture: Future.value(_DummyRecordsService(_FakeRecordsRepo(records))),
        recordsRepositoryOverride: _FakeRecordsRepo(records),
        spaceManager: _FakeSpaceManager(_space()),
        filterEngine: ContextFilterEngine(),
        relevanceScorer: RecordRelevanceScorer(),
        tokenBudgetAllocator: const TokenBudgetAllocator(),
        truncationStrategy: const ContextTruncationStrategy(),
        intentDrivenRetriever: IntentDrivenRetriever(
          relevanceScorer: RelevanceScorer(),
          privacyFilter: PrivacyFilter(),
          config: const IntentRetrievalConfig(),
        ),
        queryAnalyzer: QueryAnalyzer(
          keywordExtractor: KeywordExtractor(),
          intentClassifier: IntentClassifier(),
        ),
        intentRetrievalConfig: const IntentRetrievalConfig(),
        formatter: RecordSummaryFormatter(),
        maxRecords: maxRecords,
        dateRange: DateRange(
          start: DateTime(2020, 1, 1),
          end: DateTime(2030, 1, 1),
        ),
      );

      final context = await builder.build('test-space');

      expect(
        context.recentRecords.length,
        lessThanOrEqualTo(maxRecords),
        reason: 'Context should not exceed maxRecords=$maxRecords. '
            'Included: ${context.recentRecords.length}',
      );
    }
  });

  test('Property: Record count with small record sets', () async {
    final random = Random(456);

    // Test with record sets smaller than the limit
    for (int totalRecords in [5, 10, 15]) {
      final records = List.generate(
        totalRecords,
        (i) => _generateRecord(i, random),
      );

      final builder = SpaceContextBuilderImpl(
        recordsServiceFuture: Future.value(_DummyRecordsService(_FakeRecordsRepo(records))),
        recordsRepositoryOverride: _FakeRecordsRepo(records),
        spaceManager: _FakeSpaceManager(_space()),
        filterEngine: ContextFilterEngine(),
        relevanceScorer: RecordRelevanceScorer(),
        tokenBudgetAllocator: const TokenBudgetAllocator(),
        truncationStrategy: const ContextTruncationStrategy(),
        intentDrivenRetriever: IntentDrivenRetriever(
          relevanceScorer: RelevanceScorer(),
          privacyFilter: PrivacyFilter(),
          config: const IntentRetrievalConfig(),
        ),
        queryAnalyzer: QueryAnalyzer(
          keywordExtractor: KeywordExtractor(),
          intentClassifier: IntentClassifier(),
        ),
        intentRetrievalConfig: const IntentRetrievalConfig(),
        formatter: RecordSummaryFormatter(),
        maxRecords: 20,
        dateRange: DateRange(
          start: DateTime(2020, 1, 1),
          end: DateTime(2030, 1, 1),
        ),
      );

      final context = await builder.build('test-space');

      // When total records < maxRecords, all should be included
      expect(
        context.recentRecords.length,
        equals(totalRecords),
        reason: 'All records should be included when total < maxRecords. '
            'Total: $totalRecords, Included: ${context.recentRecords.length}',
      );
    }
  });

  test('Property: Record count with date filtering', () async {
    final now = DateTime(2025, 1, 15);
    final random = Random(789);

    // Create 100 records, but only 30 within date range
    final records = <RecordEntity>[
      // 30 records within last 30 days
      for (int i = 0; i < 30; i++)
        _generateRecord(
          i,
          random,
          date: now.subtract(Duration(days: i + 1)),
        ),
      // 70 records older than 30 days (will be filtered out)
      for (int i = 30; i < 100; i++)
        _generateRecord(
          i,
          random,
          date: now.subtract(Duration(days: 31 + (i - 30))),
        ),
    ];

    final builder = SpaceContextBuilderImpl(
      recordsServiceFuture: Future.value(_DummyRecordsService(_FakeRecordsRepo(records))),
      recordsRepositoryOverride: _FakeRecordsRepo(records),
      spaceManager: _FakeSpaceManager(_space()),
      filterEngine: ContextFilterEngine(),
      relevanceScorer: RecordRelevanceScorer(),
      tokenBudgetAllocator: const TokenBudgetAllocator(),
      truncationStrategy: const ContextTruncationStrategy(),
      intentDrivenRetriever: IntentDrivenRetriever(
        relevanceScorer: RelevanceScorer(),
        privacyFilter: PrivacyFilter(),
        config: const IntentRetrievalConfig(),
      ),
      queryAnalyzer: QueryAnalyzer(
        keywordExtractor: KeywordExtractor(),
        intentClassifier: IntentClassifier(),
      ),
      intentRetrievalConfig: const IntentRetrievalConfig(),
      formatter: RecordSummaryFormatter(),
      maxRecords: 20,
      dateRange: DateRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      ),
    );

    final context = await builder.build('test-space');

    // Should have at most 20 records (limited by maxRecords)
    expect(
      context.recentRecords.length,
      lessThanOrEqualTo(20),
      reason: 'Should not exceed maxRecords even with 30 records in date range',
    );

    // Should have at least some records (date filtering worked)
    expect(
      context.recentRecords.length,
      greaterThan(0),
      reason: 'Should include some records from the date range',
    );
  });

  test('Property: Empty record set returns zero records', () async {
    final records = <RecordEntity>[];

    final builder = SpaceContextBuilderImpl(
      recordsServiceFuture: Future.value(_DummyRecordsService(_FakeRecordsRepo(records))),
      recordsRepositoryOverride: _FakeRecordsRepo(records),
      spaceManager: _FakeSpaceManager(_space()),
      filterEngine: ContextFilterEngine(),
      relevanceScorer: RecordRelevanceScorer(),
      tokenBudgetAllocator: const TokenBudgetAllocator(),
      truncationStrategy: const ContextTruncationStrategy(),
      intentDrivenRetriever: IntentDrivenRetriever(
        relevanceScorer: RelevanceScorer(),
        privacyFilter: PrivacyFilter(),
        config: const IntentRetrievalConfig(),
      ),
      queryAnalyzer: QueryAnalyzer(
        keywordExtractor: KeywordExtractor(),
        intentClassifier: IntentClassifier(),
      ),
      intentRetrievalConfig: const IntentRetrievalConfig(),
      formatter: RecordSummaryFormatter(),
      maxRecords: 20,
      dateRange: DateRange(
        start: DateTime(2020, 1, 1),
        end: DateTime(2030, 1, 1),
      ),
    );

    final context = await builder.build('test-space');

    expect(context.recentRecords, isEmpty, reason: 'Empty record set should return zero records');
  });
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

RecordEntity _generateRecord(int id, Random random, {DateTime? date}) {
  final recordDate = date ?? DateTime(2025, 1, 1).add(Duration(days: random.nextInt(365)));
  return RecordEntity(
    id: id,
    spaceId: 'test-space',
    type: 'note',
    date: recordDate,
    title: 'Record $id',
    text: 'Note for record $id',
    tags: ['tag$id'],
    createdAt: recordDate,
    updatedAt: recordDate,
  );
}
