import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/application/use_cases/send_chat_message_use_case.dart';
import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/chat/repositories/chat_thread_repository.dart';
import 'package:patient_app/core/ai/chat/services/message_queue_service.dart';
import 'package:patient_app/core/ai/chat/models/chat_thread.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSendUseCase implements SendChatMessageUseCase {
  _FakeSendUseCase();

  bool shouldFail = false;
  int calls = 0;

  @override
  Future<ChatMessage> execute({
    required String threadId,
    required SpaceContext spaceContext,
    required String messageContent,
    List<ChatAttachmentInput> attachments = const [],
    int maxHistoryMessages = 10,
  }) async {
    calls += 1;
    if (shouldFail) {
      throw StateError('failed');
    }
    return ChatMessage(
      id: 'ai',
      threadId: threadId,
      sender: MessageSender.ai,
      content: 'ok',
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
  }
}

class _FakeChatThreadRepository extends ChatThreadRepository {
  @override
  Future<void> addMessage(String threadId, ChatMessage message) async {}

  @override
  Future<ChatThread?> getById(String threadId) async => null;

  @override
  Future<void> saveThread(ChatThread thread) async {}

  @override
  Future<void> updateMessageStatus(
    String threadId,
    String messageId,
    MessageStatus status, {
    String? errorMessage,
    String? errorCode,
    bool? errorRetryable,
  }) async {}

  @override
  Future<void> deleteThread(String threadId) async {}

  @override
  Future<List<ChatThread>> getBySpaceId(String spaceId, {int limit = 20, int offset = 0}) async {
    return const [];
  }

  @override
  Future<void> updateMessageContent(
    String threadId,
    String messageId,
    String newContent,
  ) async {}

  @override
  Future<void> updateMessageMetrics(
    String threadId,
    String messageId, {
    int? latencyMs,
    int? tokensUsed,
  }) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('enqueue persists to SharedPreferences without localPath', () async {
    final prefs = await SharedPreferences.getInstance();
    final sendUseCase = _FakeSendUseCase();
    final queue = MessageQueueService(
      sendChatMessageUseCase: sendUseCase,
      chatThreadRepository: _FakeChatThreadRepository(),
      preferences: prefs,
      now: () => DateTime(2025, 1, 1),
    );

    final tempFile = File('${Directory.systemTemp.path}/mq_test.txt');
    await tempFile.writeAsString('hello');

    await queue.enqueue(
      threadId: 't1',
      spaceContext: SpaceContext(
        spaceId: 'health',
        spaceName: 'Health',
        description: 'Health space',
        categories: const ['test'],
        persona: SpacePersona.health,
      ),
      content: 'hi',
      attachments: [
        MessageAttachment(
          id: 'a1',
          type: AttachmentType.file,
          localPath: tempFile.path,
          fileName: 'mq_test.txt',
        ),
      ],
    );

    final raw = prefs.getString('ai_chat_offline_queue_v1');
    expect(raw, isNotNull);
    final list = raw != null ? (jsonDecode(raw) as List).cast<Map<String, dynamic>>() : [];
    expect(list, isNotEmpty);
    final attachment = (list.first['attachments'] as List).first as Map<String, dynamic>;
    expect(attachment['path'], tempFile.path);
    expect(attachment.containsKey('localPath'), isFalse);
  });

  test('processQueue removes message on success and leaves on failure', () async {
    final prefs = await SharedPreferences.getInstance();
    final sendUseCase = _FakeSendUseCase();
    final queue = MessageQueueService(
      sendChatMessageUseCase: sendUseCase,
      chatThreadRepository: _FakeChatThreadRepository(),
      preferences: prefs,
      now: () => DateTime(2025, 1, 1),
    );

    final tempFile = File('${Directory.systemTemp.path}/mq_test2.txt');
    await tempFile.writeAsString('hello');

    await queue.enqueue(
      threadId: 't1',
      spaceContext: SpaceContext(
        spaceId: 'health',
        spaceName: 'Health',
        description: 'Health space',
        categories: const ['test'],
        persona: SpacePersona.health,
      ),
      content: 'hi',
      attachments: [
        MessageAttachment(
          id: 'a1',
          type: AttachmentType.file,
          localPath: tempFile.path,
        ),
      ],
    );

    await queue.processQueue();
    expect(queue.pendingCount, 0);

    // Re-enqueue and force failure.
    sendUseCase.shouldFail = true;
    await queue.enqueue(
      threadId: 't1',
      spaceContext: SpaceContext(
        spaceId: 'health',
        spaceName: 'Health',
        description: 'Health space',
        categories: const ['test'],
        persona: SpacePersona.health,
      ),
      content: 'hi again',
      attachments: const [],
    );
    await queue.processQueue();
    expect(queue.pendingCount, 1);
  });

  test('purges expired messages on load', () async {
    final prefs = await SharedPreferences.getInstance();
    // Seed expired entry (8 days old).
    final expiredDate = DateTime.now().subtract(const Duration(days: 8)).toIso8601String();
    prefs.setString(
      'ai_chat_offline_queue_v1',
      '''
      [
        {
          "threadId":"t1",
          "spaceContext":{"spaceId":"health","spaceName":"Health","persona":"health","maxContextRecords":5,"recentRecords":[]},
          "content":"stale",
          "attachments":[],
          "enqueuedAt":"$expiredDate"
        }
      ]
      ''',
    );

    final queue = MessageQueueService(
      sendChatMessageUseCase: _FakeSendUseCase(),
      chatThreadRepository: _FakeChatThreadRepository(),
      preferences: prefs,
      now: () => DateTime.now(),
    );

    await queue.processQueue();
    expect(queue.pendingCount, 0);
  });
}
