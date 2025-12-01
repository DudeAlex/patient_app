import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/context/record_summary_formatter.dart';
import 'package:patient_app/core/ai/chat/context/space_context_builder.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/chat/context/context_filter_engine.dart';
import 'package:patient_app/core/ai/chat/context/record_relevance_scorer.dart';
import 'package:patient_app/core/ai/chat/context/context_truncation_strategy.dart';
import 'package:patient_app/core/ai/chat/models/record_summary.dart';
import 'package:patient_app/core/ai/chat/models/date_range.dart';
import 'package:patient_app/core/ai/chat/models/intent_retrieval_config.dart';
import 'package:patient_app/core/ai/chat/domain/services/intent_driven_retriever.dart';
import 'package:patient_app/core/ai/chat/domain/services/query_analyzer.dart';
import 'package:patient_app/core/ai/chat/domain/services/relevance_scorer.dart';
import 'package:patient_app/core/ai/chat/domain/services/privacy_filter.dart';
import 'package:patient_app/core/ai/chat/domain/services/keyword_extractor.dart';
import 'package:patient_app/core/ai/chat/domain/services/intent_classifier.dart';
import 'package:patient_app/core/ai/chat/models/query_analysis.dart';
import 'package:patient_app/core/ai/chat/models/retrieval_result.dart';
import 'package:patient_app/core/ai/chat/models/retrieval_stats.dart';
import 'package:patient_app/core/ai/chat/models/scored_record.dart';
import 'package:patient_app/core/ai/chat/models/query_intent.dart';
import 'package:patient_app/core/ai/chat/context/token_budget_allocator.dart';
import 'package:patient_app/core/application/services/space_manager.dart';
import 'package:patient_app/core/application/ports/space_repository.dart';
import 'package:patient_app/core/domain/entities/space.dart';
import 'package:patient_app/core/domain/value_objects/space_gradient.dart';
import 'package:patient_app/features/records/application/ports/records_repository.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';
import 'package:patient_app/features/spaces/domain/space_registry.dart';
import 'package:flutter/material.dart';
import 'package:patient_app/features/records/data/records_service.dart';

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

class _DummyRecordsService extends Fake implements RecordsService {
  _DummyRecordsService(this.records);
  @override
  final RecordsRepository records;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestRelevanceScorer extends RecordRelevanceScorer {
  @override
  Future<List<RecordEntity>> sortByRelevance(
    List<RecordEntity> records, {
    DateTime? now,
    Map<int, int>? accessCounts,
  }) {
    return super.sortByRelevance(
      records,
      now: DateTime(2025, 2, 1),
      accessCounts: accessCounts,
    );
  }
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
    final filtered = spaceId == null
        ? _records
        : _records.where((record) => record.spaceId == spaceId).toList();
    return filtered.skip(offset).take(limit).toList();
 }

  @override
  Future<List<RecordEntity>> recent({int limit = 50}) async {
    return _records.take(limit).toList();
  }

  @override
  Future<RecordEntity> save(RecordEntity record) async => record;
}

class _FakeIntentDrivenRetriever extends IntentDrivenRetriever {
  _FakeIntentDrivenRetriever() : super(
    relevanceScorer: RelevanceScorer(),
    privacyFilter: PrivacyFilter(),
    config: const IntentRetrievalConfig(),
  );
}

class _FakeQueryAnalyzer extends QueryAnalyzer {
  _FakeQueryAnalyzer() : super(
    keywordExtractor: KeywordExtractor(),
    intentClassifier: IntentClassifier(),
  );
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
      recordsServiceFuture: Future.value(_DummyRecordsService(_FakeRecordsRepo(records))),
      spaceManager: _FakeSpaceManager(_space()),
      filterEngine: ContextFilterEngine(),
      relevanceScorer: _TestRelevanceScorer(),
      tokenBudgetAllocator: const TokenBudgetAllocator(
        total: 4800,
        system: 800,
        context: 200,
        history: 1000,
        response: 1000,
      ),
      truncationStrategy: const ContextTruncationStrategy(),
      intentDrivenRetriever: _FakeIntentDrivenRetriever(), // Mock implementation
      queryAnalyzer: _FakeQueryAnalyzer(), // Mock implementation
      intentRetrievalConfig: const IntentRetrievalConfig(),
      formatter: RecordSummaryFormatter(maxNoteLength: 50),
      maxRecords: 10,
      dateRange: DateRange(
        start: DateTime(2020, 1, 1),
        end: DateTime(2030, 1, 1),
      ),
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
