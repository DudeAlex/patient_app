import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:patient_app/core/ai/chat/application/use_cases/clear_chat_thread_use_case.dart';
import 'package:patient_app/core/ai/chat/application/use_cases/load_chat_history_use_case.dart';
import 'package:patient_app/core/ai/chat/application/use_cases/send_chat_message_use_case.dart';
import 'package:patient_app/core/ai/chat/application/use_cases/switch_space_context_use_case.dart';
import 'package:patient_app/core/ai/chat/fake_ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/core/ai/chat/models/chat_thread.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/chat/repositories/chat_thread_repository.dart';
import 'package:patient_app/core/ai/chat/services/message_attachment_handler.dart';
import 'package:patient_app/core/ai/chat/services/message_queue_service.dart';
import 'package:patient_app/core/ai/repositories/ai_consent_repository.dart';
import 'package:patient_app/core/ai/chat/application/interfaces/space_context_builder.dart';
import 'package:patient_app/features/ai_chat/ui/controllers/ai_chat_controller.dart';
import 'package:patient_app/core/ai/chat/services/connectivity_monitor.dart';
import '../../../../core/ai/chat/fakes/fake_token_budget_allocator.dart';
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
      {String? errorMessage, String? errorCode, bool? errorRetryable}) async {
    final thread = _store[threadId];
    if (thread == null) return;
    final updated = thread.messages.map((m) => m.id == messageId ? m.copyWith(status: status) : m).toList();
    _store[threadId] = thread.copyWith(messages: updated);
  }
}

class _StubConsentRepo implements AiConsentRepository {
  @override
  Future<void> grantConsent() async {}

  @override
  Future<bool> hasConsent() async => true;

  @override
  Future<void> revokeConsent() async {}

  @override
  Future<void> setConsent(bool consent) async {}
}

class _StubAttachmentHandler implements MessageAttachmentHandler {
  @override
  Future<void> deleteAttachment(MessageAttachment attachment) async {}

  @override
  Future<MessageAttachment> processAttachment({required File sourceFile, required AttachmentType type, required String targetThreadId}) async {
    return MessageAttachment(
      id: 'att-${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      localPath: sourceFile.path,
      fileName: sourceFile.uri.pathSegments.last,
      fileSizeBytes: await sourceFile.length(),
    );
  }

  @override
  Future<void> validateAttachment(File file, AttachmentType type) async {}
}

class _StubSpaceContextBuilder implements SpaceContextBuilder {
  @override
  Future<SpaceContext> build(String spaceId) async {
    return SpaceContext(
      spaceId: spaceId,
      spaceName: 'Space $spaceId',
      description: 'Test space',
      categories: const ['test'],
      persona: SpacePersona.general,
    );
  }
}

class _StubMessageQueueService implements MessageQueueService {
  @override
  int get pendingCount => 0;

  @override
  Future<void> enqueue({
    required String threadId,
    required SpaceContext spaceContext,
    required String content,
    required List<MessageAttachment> attachments,
  }) async {}

  @override
  Future<void> processQueue() async {}
}

class _StubConnectivityMonitor implements ConnectivityMonitor {
  _StubConnectivityMonitor(this._queue);

  final MessageQueueService _queue;

  @override
  Connectivity get connectivity => Connectivity();

  @override
  MessageQueueService get messageQueueService => _queue;

  @override
  void Function(bool p1)? get onStatusChanged => null;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

void main() {
  test('loadInitial populates thread and context', () async {
    final repo = _InMemoryThreadRepo();
    final attachmentHandler = _StubAttachmentHandler();
    final loadUseCase = LoadChatHistoryUseCase(chatThreadRepository: repo, uuid: const Uuid());
    final clearUseCase = ClearChatThreadUseCase(chatThreadRepository: repo, attachmentHandler: attachmentHandler);
    final sendUseCase = SendChatMessageUseCase(
      aiChatService: FakeAiChatService(simulatedLatency: Duration.zero),
      chatThreadRepository: repo,
      consentRepository: _StubConsentRepo(),
      attachmentHandler: attachmentHandler,
      spaceContextBuilder: _StubSpaceContextBuilder(),
      tokenBudgetAllocator: const FakeTokenBudgetAllocator(),
      uuid: const Uuid(),
    );
    final messageQueue = _StubMessageQueueService();
    final connectivityMonitor = _StubConnectivityMonitor(messageQueue);
    final controller = AiChatController(
      spaceId: 'health',
      sendChatMessageUseCase: sendUseCase,
      loadChatHistoryUseCase: loadUseCase,
      clearChatThreadUseCase: clearUseCase,
      switchSpaceContextUseCase: SwitchSpaceContextUseCase(
        loadChatHistoryUseCase: loadUseCase,
        clearChatThreadUseCase: clearUseCase,
        spaceContextBuilder: _StubSpaceContextBuilder(),
      ),
      chatThreadRepository: repo,
      spaceContextBuilder: _StubSpaceContextBuilder(),
      messageQueueService: messageQueue,
      connectivityMonitor: connectivityMonitor,
    );

    await controller.loadInitial();

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.thread, isNotNull);
    expect(controller.state.spaceContext, isNotNull);
  });

  test('sendMessage clears attachments and refreshes thread', () async {
    final repo = _InMemoryThreadRepo();
    final attachmentHandler = _StubAttachmentHandler();
    final loadUseCase = LoadChatHistoryUseCase(chatThreadRepository: repo, uuid: const Uuid());
    final clearUseCase = ClearChatThreadUseCase(chatThreadRepository: repo, attachmentHandler: attachmentHandler);
    final sendUseCase = SendChatMessageUseCase(
      aiChatService: FakeAiChatService(simulatedLatency: Duration.zero),
      chatThreadRepository: repo,
      consentRepository: _StubConsentRepo(),
      attachmentHandler: attachmentHandler,
      spaceContextBuilder: _StubSpaceContextBuilder(),
      tokenBudgetAllocator: const FakeTokenBudgetAllocator(),
      uuid: const Uuid(),
    );
    final messageQueue = _StubMessageQueueService();
    final connectivityMonitor = _StubConnectivityMonitor(messageQueue);
    final controller = AiChatController(
      spaceId: 'health',
      sendChatMessageUseCase: sendUseCase,
      loadChatHistoryUseCase: loadUseCase,
      clearChatThreadUseCase: clearUseCase,
      switchSpaceContextUseCase: SwitchSpaceContextUseCase(
        loadChatHistoryUseCase: loadUseCase,
        clearChatThreadUseCase: clearUseCase,
        spaceContextBuilder: _StubSpaceContextBuilder(),
      ),
      chatThreadRepository: repo,
      spaceContextBuilder: _StubSpaceContextBuilder(),
      messageQueueService: messageQueue,
      connectivityMonitor: connectivityMonitor,
    );

    await controller.loadInitial();

    // Seed an attachment with a real file path.
    final tempFile = await File('${Directory.systemTemp.path}/chat_att.txt').writeAsString('data');
    controller.addAttachment(
      MessageAttachment(id: 'a1', type: AttachmentType.file, localPath: tempFile.path),
    );

    await controller.sendMessage('hello');

    expect(controller.state.attachments, isEmpty);
    expect(controller.state.thread?.messages.length, greaterThan(0));
  });
}
