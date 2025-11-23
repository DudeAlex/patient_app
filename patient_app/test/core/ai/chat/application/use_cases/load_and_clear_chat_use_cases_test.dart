import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/application/use_cases/clear_chat_thread_use_case.dart';
import 'package:patient_app/core/ai/chat/application/use_cases/load_chat_history_use_case.dart';
import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/core/ai/chat/models/chat_thread.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';
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

void main() {
  test('creates thread when none exists', () async {
    final repo = _InMemoryThreadRepo();
    final useCase = LoadChatHistoryUseCase(chatThreadRepository: repo, uuid: const Uuid());

    final thread = await useCase.execute('health');

    expect(thread.spaceId, 'health');
    expect(thread.id, isNotEmpty);
    final stored = await repo.getById(thread.id);
    expect(stored, isNotNull);
  });

  test('sorts messages when returning existing thread', () async {
    final repo = _InMemoryThreadRepo();
    final thread = ChatThread(
      id: 't1',
      spaceId: 'health',
      messages: [
        ChatMessage(
          id: 'm2',
          threadId: 't1',
          sender: MessageSender.user,
          content: 'later',
          timestamp: DateTime(2025, 1, 2),
        ),
        ChatMessage(
          id: 'm1',
          threadId: 't1',
          sender: MessageSender.user,
          content: 'earlier',
          timestamp: DateTime(2025, 1, 1),
        ),
      ],
    );
    await repo.saveThread(thread);
    final useCase = LoadChatHistoryUseCase(chatThreadRepository: repo, uuid: const Uuid());

    final loaded = await useCase.execute('health');

    expect(loaded.messages.first.id, 'm1');
  });

  test('clears thread and deletes attachments', () async {
    final repo = _InMemoryThreadRepo();
    final attachmentHandler = _StubAttachmentHandler();
    final thread = ChatThread(
      id: 't1',
      spaceId: 'health',
      messages: [
        ChatMessage(
          id: 'm1',
          threadId: 't1',
          sender: MessageSender.user,
          content: 'hello',
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
    await repo.saveThread(thread);
    final clearUseCase = ClearChatThreadUseCase(
      chatThreadRepository: repo,
      attachmentHandler: attachmentHandler,
    );

    await clearUseCase.execute('t1');

    expect(await repo.getById('t1'), isNull);
    expect(attachmentHandler.deleteCalls, 1);
  });
}
