import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/application/use_cases/clear_chat_thread_use_case.dart';
import 'package:patient_app/core/ai/chat/application/use_cases/load_chat_history_use_case.dart';
import 'package:patient_app/core/ai/chat/application/use_cases/switch_space_context_use_case.dart';
import 'package:patient_app/core/ai/chat/application/interfaces/space_context_builder.dart';
import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/core/ai/chat/models/chat_thread.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/chat/models/date_range.dart';
import 'package:patient_app/core/ai/chat/repositories/chat_thread_repository.dart';
import 'package:patient_app/core/ai/chat/services/message_attachment_handler.dart';
import 'package:uuid/uuid.dart';

class _InMemoryThreadRepo implements ChatThreadRepository {
  final Map<String, ChatThread> _store = {};

  @override
  Future<void> addMessage(String threadId, ChatMessage message) async {
    final thread = _store[threadId];
    if (thread == null) return;
    _store[threadId] = thread.addMessage(message);
  }

  @override
  Future<void> deleteThread(String threadId) async {
    _store.remove(threadId);
  }

  @override
  Future<ChatThread?> getById(String threadId) async => _store[threadId];

  @override
  Future<List<ChatThread>> getBySpaceId(String spaceId, {int limit = 20, int offset = 0}) async {
    final threads = _store.values.where((t) => t.spaceId == spaceId).toList();
    return threads.skip(offset).take(limit).toList();
  }

  @override
  Future<void> saveThread(ChatThread thread) async {
    _store[thread.id] = thread;
  }

  @override
  Future<void> updateMessageContent(String threadId, String messageId, String content) async {}

  @override
  Future<void> updateMessageMetrics(String threadId, String messageId, {int? tokensUsed, int? latencyMs}) async {}

  @override
  Future<void> updateMessageStatus(String threadId, String messageId, MessageStatus status,
      {String? errorMessage, String? errorCode, bool? errorRetryable}) async {}

  @override
  Future<void> updateMessageFeedback(String threadId, String messageId, MessageFeedback feedback) async {}
}

class _StubAttachmentHandler implements MessageAttachmentHandler {
  int deleteCalls = 0;

  @override
  Future<MessageAttachment> processAttachment(
      {required File sourceFile, required AttachmentType type, required String targetThreadId}) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAttachment(MessageAttachment attachment) async {
    deleteCalls++;
  }

  @override
  Future<void> validateAttachment(File file, AttachmentType type) async {}
}

class _StubSpaceContextBuilder implements SpaceContextBuilder {
  @override
  Future<SpaceContext> build(String spaceId, {DateRange? dateRange, String? userQuery}) async {
    return SpaceContext(
      spaceId: spaceId,
      spaceName: 'Space $spaceId',
      description: 'Test space',
      categories: const ['test'],
      persona: SpacePersona.general,
    );
  }
}

void main() {
  test('clears current thread when requested and loads new space thread', () async {
    final repo = _InMemoryThreadRepo();
    final attachmentHandler = _StubAttachmentHandler();
    // Seed current thread with attachment to verify cleanup.
    final current = ChatThread(
      id: 'current',
      spaceId: 'health',
      messages: [
        ChatMessage(
          id: 'm1',
          threadId: 'current',
          sender: MessageSender.user,
          content: 'hi',
          timestamp: DateTime.now(),
          attachments: [
            MessageAttachment(
              id: 'a1',
              type: AttachmentType.photo,
              localPath: '/tmp/a1',
            ),
          ],
        ),
      ],
    );
    await repo.saveThread(current);

    final load = LoadChatHistoryUseCase(chatThreadRepository: repo, uuid: const Uuid());
    final clear = ClearChatThreadUseCase(
      chatThreadRepository: repo,
      attachmentHandler: attachmentHandler,
    );
    final useCase = SwitchSpaceContextUseCase(
      loadChatHistoryUseCase: load,
      clearChatThreadUseCase: clear,
      spaceContextBuilder: _StubSpaceContextBuilder(),
    );

    final result = await useCase.execute(
      currentThreadId: 'current',
      newSpaceId: 'education',
      shouldClearCurrentThread: true,
    );

    expect(await repo.getById('current'), isNull);
    expect(attachmentHandler.deleteCalls, 1);
    expect(result.spaceContext.spaceId, 'education');
    expect(result.newThread.spaceId, 'education');
  });
}
