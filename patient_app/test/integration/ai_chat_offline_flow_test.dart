import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/application/interfaces/space_context_builder.dart';
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
import 'package:patient_app/core/ai/chat/services/connectivity_monitor.dart';
import 'package:patient_app/core/ai/chat/services/message_attachment_handler.dart';
import 'package:patient_app/core/ai/chat/services/message_queue_service.dart';
import 'package:patient_app/core/ai/repositories/ai_consent_repository.dart';
import 'package:patient_app/features/ai_chat/ui/controllers/ai_chat_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/ai/chat/fakes/fake_token_budget_allocator.dart';

class _FakeConnectivityPlatform extends ConnectivityPlatform {
  _FakeConnectivityPlatform(List<ConnectivityResult> initial)
      : _current = initial,
        _controller = StreamController<List<ConnectivityResult>>.broadcast();

  List<ConnectivityResult> _current;
  final StreamController<List<ConnectivityResult>> _controller;

  void setStatus(List<ConnectivityResult> status) {
    _current = status;
    _controller.add(status);
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _current;
}

class _InMemoryChatThreadRepository extends ChatThreadRepository {
  final Map<String, ChatThread> _threads = {};

  @override
  Future<void> addMessage(String threadId, ChatMessage message) async {
    final existing = _threads[threadId];
    final updated =
        (existing ?? ChatThread(id: threadId, spaceId: 'health')).addMessage(
      message,
    );
    _threads[threadId] = updated;
  }

  @override
  Future<void> deleteThread(String threadId) async {
    _threads.remove(threadId);
  }

  @override
  Future<ChatThread?> getById(String threadId) async => _threads[threadId];

  @override
  Future<List<ChatThread>> getBySpaceId(String spaceId,
      {int limit = 20, int offset = 0}) async {
    return _threads.values
        .where((thread) => thread.spaceId == spaceId)
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<void> saveThread(ChatThread thread) async {
    _threads[thread.id] = thread;
  }

  @override
  Future<void> updateMessageStatus(String threadId, String messageId,
      MessageStatus status,
      {String? errorMessage, String? errorCode, bool? errorRetryable}) async {
    final thread = _threads[threadId];
    if (thread == null) return;
    final updatedMessages = thread.messages
        .map((m) => m.id == messageId ? m.copyWith(status: status) : m)
        .toList();
    _threads[threadId] = thread.copyWith(messages: updatedMessages);
  }

  @override
  Future<void> updateMessageContent(
      String threadId, String messageId, String content) async {
    final thread = _threads[threadId];
    if (thread == null) return;
    final updatedMessages = thread.messages
        .map((m) => m.id == messageId ? m.copyWith(content: content) : m)
        .toList();
    _threads[threadId] = thread.copyWith(messages: updatedMessages);
  }

  @override
  Future<void> updateMessageMetrics(String threadId, String messageId,
      {int? tokensUsed, int? latencyMs}) async {
    // Metrics ignored for this test repository.
  }
}

class _AlwaysConsentedRepository implements AiConsentRepository {
  @override
  Future<bool> hasConsent() async => true;

  @override
  Future<void> grantConsent() async {}

  @override
  Future<void> revokeConsent() async {}
}

class _FakeMessageAttachmentHandler implements MessageAttachmentHandler {
  @override
  Future<MessageAttachment> processAttachment(
      {required File sourceFile,
      required AttachmentType type,
      required String targetThreadId}) {
    return Future.value(
      MessageAttachment(
        id: const Uuid().v4(),
        type: type,
        localPath: sourceFile.path,
      ),
    );
  }

  @override
  Future<void> deleteAttachment(MessageAttachment attachment) async {}

  @override
  Future<void> validateAttachment(File file, AttachmentType type) async {}
}

class _FakeSpaceContextBuilder implements SpaceContextBuilder {
  @override
  Future<SpaceContext> build(String spaceId) async {
    return SpaceContext(
      spaceId: spaceId,
      spaceName: 'Health',
      description: 'Health space',
      categories: const ['test'],
      persona: SpacePersona.health,
    );
  }
}

void main() {
  group('Offline/online integration', () {
    late ConnectivityPlatform originalPlatform;
    late _FakeConnectivityPlatform fakePlatform;

    setUp(() {
      originalPlatform = ConnectivityPlatform.instance;
      fakePlatform =
          _FakeConnectivityPlatform(const [ConnectivityResult.none]);
      ConnectivityPlatform.instance = fakePlatform;
    });

    tearDown(() {
      ConnectivityPlatform.instance = originalPlatform;
    });

    test('queues offline messages and retries when connectivity returns',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = _InMemoryChatThreadRepository();
      final loadUseCase =
          LoadChatHistoryUseCase(chatThreadRepository: repo, uuid: const Uuid());
      final consentRepo = _AlwaysConsentedRepository();
      final attachmentHandler = _FakeMessageAttachmentHandler();
      final sendUseCase = SendChatMessageUseCase(
        aiChatService: FakeAiChatService(simulatedLatency: Duration.zero),
        chatThreadRepository: repo,
        consentRepository: consentRepo,
        attachmentHandler: attachmentHandler,
        spaceContextBuilder: _FakeSpaceContextBuilder(),
        tokenBudgetAllocator: const FakeTokenBudgetAllocator(),
        uuid: const Uuid(),
      );
      final queueService = MessageQueueService(
        sendChatMessageUseCase: sendUseCase,
        chatThreadRepository: repo,
        preferences: prefs,
        now: () => DateTime(2025, 1, 1),
      );
      final connectivity = Connectivity();

      late AiChatController controller;
      final monitor = ConnectivityMonitor(
        messageQueueService: queueService,
        connectivity: connectivity,
        onStatusChanged: (isOffline) => controller.setOffline(isOffline),
      );
      final clearUseCase = ClearChatThreadUseCase(
        chatThreadRepository: repo,
        attachmentHandler: attachmentHandler,
      );
      final switchUseCase = SwitchSpaceContextUseCase(
        loadChatHistoryUseCase: loadUseCase,
        clearChatThreadUseCase: clearUseCase,
        spaceContextBuilder: _FakeSpaceContextBuilder(),
      );

      controller = AiChatController(
        spaceId: 'health',
        sendChatMessageUseCase: sendUseCase,
        loadChatHistoryUseCase: loadUseCase,
        clearChatThreadUseCase: clearUseCase,
        switchSpaceContextUseCase: switchUseCase,
        chatThreadRepository: repo,
        spaceContextBuilder: _FakeSpaceContextBuilder(),
        messageQueueService: queueService,
        connectivityMonitor: monitor,
      );

      await controller.loadInitial();
      final threadId = controller.state.thread!.id;
      await controller.startConnectivityMonitoring();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.state.isOffline, isTrue);

      await controller.sendMessage('Queued while offline');

      expect(queueService.pendingCount, 1);
      expect(controller.state.attachments, isEmpty);

      // Restore connectivity and allow queue processing to run.
      fakePlatform.setStatus(const [ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(queueService.pendingCount, 0);
      expect(controller.state.isOffline, isFalse);

      final threads = await repo.getBySpaceId('health');
      final allMessages = threads.expand((t) => t.messages).toList();
      final contents = allMessages.map((m) => m.content).toList();
      expect(contents, contains('Queued while offline'));
      final byId = await repo.getById(threadId);
      expect(byId?.messages.length ?? 0, greaterThan(0));
    });
  });
}
