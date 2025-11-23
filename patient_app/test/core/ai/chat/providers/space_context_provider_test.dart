import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/core/ai/chat/models/chat_thread.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/chat/providers/space_context_provider.dart';
import 'package:patient_app/core/ai/chat/repositories/chat_thread_repository.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';
import 'package:patient_app/features/records/application/ports/records_repository.dart';
import 'package:patient_app/features/records/application/use_cases/fetch_recent_records_use_case.dart';
import 'package:patient_app/features/records/data/records_service.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

class _StubRecordsService implements RecordsService {
  _StubRecordsService(this._records);

  final List<RecordEntity> _records;

  @override
  FetchRecentRecordsUseCase get fetchRecentRecords =>
      FetchRecentRecordsUseCase(_StubRecordsRepository(_records));

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

  // Unused members
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

void main() {
  test('builds persona and recent records summaries for space', () async {
    final container = ProviderContainer(
      overrides: [
        spaceContextBuilderProvider.overrideWithValue(
          DefaultSpaceContextBuilder(
            recordsServiceFuture: Future.value(
              _StubRecordsService([
                RecordEntity(
                  id: 1,
                  spaceId: 'health',
                  type: 'visit',
                  date: DateTime(2025, 1, 2),
                  title: 'Checkup',
                  text: 'Notes about visit',
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
            chatThreadRepository: _StubThreadRepo(),
            maxRecords: 1,
          ),
        ),
      ],
    );

    final context = await container.read(spaceContextProvider('health').future);

    expect(context.persona, SpacePersona.health);
    expect(context.limitedRecords.length, 1);
    expect(context.limitedRecords.first.title, 'Checkup');
  });

  test('defaults to general persona for unknown spaces', () async {
    final builder = DefaultSpaceContextBuilder(
      recordsServiceFuture: Future.value(
        _StubRecordsService([]),
      ),
      chatThreadRepository: _StubThreadRepo(),
    );

    final context = await builder.build('custom_space');

    expect(context.persona, SpacePersona.general);
    expect(context.spaceName, 'Custom_space');
  });
}
