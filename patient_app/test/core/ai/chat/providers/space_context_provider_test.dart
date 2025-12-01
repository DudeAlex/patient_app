import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/core/ai/chat/models/chat_thread.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/chat/providers/space_context_provider.dart';
import 'package:patient_app/core/ai/chat/repositories/chat_thread_repository.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';
import 'package:patient_app/core/ai/chat/context/context_filter_engine.dart';
import 'package:patient_app/core/ai/chat/context/record_relevance_scorer.dart';
import 'package:patient_app/core/ai/chat/context/context_truncation_strategy.dart';
import 'package:patient_app/core/ai/chat/context/record_summary_formatter.dart';
import 'package:patient_app/core/ai/chat/context/space_context_builder.dart';
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
import 'package:patient_app/features/spaces/domain/space_registry.dart';
import 'package:patient_app/features/records/application/ports/records_repository.dart';
import 'package:patient_app/features/records/application/use_cases/fetch_recent_records_use_case.dart';
import 'package:patient_app/features/records/data/records_service.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';
import 'package:flutter/material.dart';

class _StubRecordsService implements RecordsService {
  _StubRecordsService(this._records);

  final List<RecordEntity> _records;

  @override
  FetchRecentRecordsUseCase get fetchRecentRecords =>
      FetchRecentRecordsUseCase(_StubRecordsRepository(_records));

  @override
  RecordsRepository get records => _StubRecordsRepository(_records);

  // Unused members for this test
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubRecordsRepository implements RecordsRepository {
  _StubRecordsRepository(this._records);
  final List<RecordEntity> _records;

  @override
  Future<List<RecordEntity>> recent({int limit = 50}) async {
    final sorted = [..._records]
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }

  @override
  Future<List<RecordEntity>> fetchPage({
    required int offset,
    required int limit,
    String? query,
    String? spaceId,
  }) async {
    final filtered = spaceId == null
        ? _records
        : _records.where((record) => record.spaceId == spaceId).toList();
    final sorted = [...filtered]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.skip(offset).take(limit).toList();
  }

  @override
  Future<RecordEntity> save(RecordEntity record) async => record;

  @override
  Future<RecordEntity?> byId(int id) async => _records.firstWhere((r) => r.id == id);

  @override
  Future<void> delete(int id) async {}
}

class _StubThreadRepo implements ChatThreadRepository {
  @override
  Future<void> addMessage(String threadId, ChatMessage message) async {}

  @override
  Future<void> deleteThread(String threadId) async {}

  @override
  Future<ChatThread?> getById(String threadId) async => null;

  @override
  Future<List<ChatThread>> getBySpaceId(String spaceId, {int limit = 20, int offset = 0}) async =>
      const [];

  @override
  Future<void> saveThread(ChatThread thread) async {}

  @override
  Future<void> updateMessageContent(String threadId, String messageId, String content) async {}

  @override
  Future<void> updateMessageMetrics(String threadId, String messageId, {int? tokensUsed, int? latencyMs}) async {}

  @override
  Future<void> updateMessageStatus(String threadId, String messageId, MessageStatus status,
      {String? errorMessage, String? errorCode, bool? errorRetryable}) async {}
}

class _StubSpaceRepo implements SpaceRepository {
  _StubSpaceRepo(this.spaceId);
  final String spaceId;

  @override
  Future<List<String>> getActiveSpaceIds() async => [spaceId];

  @override
  Future<String> getCurrentSpaceId() async => spaceId;

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
  Future<bool> spaceExists(String spaceId) async => spaceId == this.spaceId;

  @override
  Future<bool> hasCompletedOnboarding() async => true;

  @override
  Future<void> setOnboardingComplete() async {}
}

class _StubSpaceRegistry extends SpaceRegistry {}

class _StubSpaceManager extends SpaceManager {
  _StubSpaceManager(String spaceId)
      : _spaceId = spaceId,
        super(
          _StubSpaceRepo(spaceId),
          _StubSpaceRegistry(),
        );

  final String _spaceId;

  @override
  Future<Space> getCurrentSpace() async => Space(
        id: _spaceId,
        name: _spaceId[0].toUpperCase() + _spaceId.substring(1),
        icon: 'icon',
        gradient: SpaceGradient(
          startColor: Colors.white,
          endColor: Colors.black,
        ),
        description: 'desc',
        categories: const ['test'],
      );

  @override
  Future<List<Space>> getActiveSpaces() async => [await getCurrentSpace()];
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

void main() {
  test('builds persona and recent records summaries for space', () async {
    final container = ProviderContainer(
      overrides: [
        spaceContextBuilderProvider.overrideWithValue(
          SpaceContextBuilderImpl(
            recordsServiceFuture: Future.value(
              _StubRecordsService([
                RecordEntity(
                  id: 1,
                  spaceId: 'health',
                  type: 'visit',
                  date: DateTime(2025, 1, 2),
                  title: 'Checkup',
                  text: 'Notes about visit ' + 'x' * 500,
                  tags: ['tag1'],
                  createdAt: DateTime(2025, 1, 2),
                  updatedAt: DateTime(2025, 1, 2),
                ),
                RecordEntity(
                  id: 2,
                  spaceId: 'health',
                  type: 'lab',
                  date: DateTime(2025, 1, 1),
                  title: 'Lab',
                  text: 'Lab notes',
                  tags: ['tag2'],
                  createdAt: DateTime(2025, 1, 1),
                  updatedAt: DateTime(2025, 1, 1),
                ),
              ]),
            ),
            recordsRepositoryOverride: _StubRecordsRepository([
              RecordEntity(
                id: 1,
                spaceId: 'health',
                type: 'visit',
                date: DateTime(2025, 1, 2),
                title: 'Checkup',
                text: 'Notes about visit ' + 'x' * 500,
                tags: ['tag1'],
                createdAt: DateTime(2025, 1, 2),
                updatedAt: DateTime(2025, 1, 2),
              ),
            ]),
            spaceManager: _StubSpaceManager('health'),
            filterEngine: ContextFilterEngine(),
            relevanceScorer: _TestRelevanceScorer(),
            tokenBudgetAllocator: const TokenBudgetAllocator(
              total: 4800,
              system: 800,
              context: 2000,
              history: 1000,
              response: 1000,
            ),
            truncationStrategy: const ContextTruncationStrategy(),
            formatter: RecordSummaryFormatter(),
            maxRecords: 1,
            dateRange: DateRange(
              start: DateTime(2020, 1, 1),
              end: DateTime(2030, 1, 1),
            ),
          ),
        ),
      ],
    );

    final context = await container.read(spaceContextProvider('health').future);

    expect(context.persona, SpacePersona.health);
    expect(context.limitedRecords.length, 1);
    expect(context.limitedRecords.first.title, 'Checkup');
    expect(context.limitedRecords.first.summary!.length, lessThanOrEqualTo(100));
  });

  test('defaults to general persona for unknown spaces', () async {
    final builder = SpaceContextBuilderImpl(
      recordsServiceFuture: Future.value(_StubRecordsService([])),
      recordsRepositoryOverride: _StubRecordsRepository([]),
      spaceManager: _StubSpaceManager('custom_space'),
      filterEngine: ContextFilterEngine(),
      relevanceScorer: _TestRelevanceScorer(),
      tokenBudgetAllocator: const TokenBudgetAllocator(
        total: 4800,
        system: 800,
        context: 2000,
        history: 1000,
        response: 1000,
      ),
      truncationStrategy: const ContextTruncationStrategy(),
      formatter: RecordSummaryFormatter(),
      maxRecords: 1,
      dateRange: DateRange(
        start: DateTime(2020, 1, 1),
        end: DateTime(2030, 1, 1),
      ),
    );

    final context = await builder.build('custom_space');

    expect(context.persona, SpacePersona.general);
    expect(context.spaceName, 'Custom_space');
  });
}
