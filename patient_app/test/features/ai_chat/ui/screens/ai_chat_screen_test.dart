import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/application/interfaces/space_context_builder.dart';
import 'package:patient_app/core/ai/chat/application/use_cases/clear_chat_thread_use_case.dart';
import 'package:patient_app/core/ai/chat/application/use_cases/load_chat_history_use_case.dart';
import 'package:patient_app/core/ai/chat/application/use_cases/send_chat_message_use_case.dart';
import 'package:patient_app/core/ai/chat/application/use_cases/switch_space_context_use_case.dart';
import 'package:patient_app/core/ai/chat/chat_providers.dart';
import 'package:patient_app/core/ai/chat/fake_ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';
import 'package:patient_app/core/ai/chat/models/chat_thread.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/chat/models/date_range.dart';
import 'package:patient_app/core/ai/chat/repositories/chat_thread_repository.dart';
import 'package:patient_app/core/ai/chat/services/message_attachment_handler.dart';
import 'package:patient_app/core/ai/chat/services/message_queue_service.dart';
import 'package:patient_app/core/ai/chat/services/connectivity_monitor.dart';
import 'package:patient_app/core/ai/repositories/ai_consent_repository.dart';
import 'package:patient_app/core/ai/repositories/ai_config_repository.dart';
import 'package:patient_app/core/ai/ai_config.dart';
import 'package:patient_app/core/di/app_container.dart';
import 'package:patient_app/features/ai_chat/ui/controllers/ai_chat_controller.dart';
import 'package:patient_app/features/ai_chat/ui/screens/ai_chat_screen.dart';
import '../../../../core/ai/chat/fakes/fake_token_budget_allocator.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Stub implementations
class _StubThreadRepo implements ChatThreadRepository {
  @override
  Future<void> addMessage(String threadId, ChatMessage message) async {}
  @override
  Future<void> deleteThread(String threadId) async {}
  @override
  Future<ChatThread?> getById(String threadId) async => null;
  @override
  Future<List<ChatThread>> getBySpaceId(String spaceId, {int limit = 20, int offset = 0}) async => [];
  @override
  Future<void> saveThread(ChatThread thread) async {}
  @override
  Future<void> updateMessageContent(String threadId, String messageId, String content) async {}
  @override
  Future<void> updateMessageMetrics(String threadId, String messageId, {int? tokensUsed, int? latencyMs}) async {}
  @override
  Future<void> updateMessageStatus(String threadId, String messageId, MessageStatus status, {String? errorMessage, String? errorCode, bool? errorRetryable}) async {}
  @override
  Future<void> updateMessageFeedback(String threadId, String messageId, MessageFeedback feedback) async {}
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
    return MessageAttachment(id: 'stub', type: type, localPath: sourceFile.path, fileName: 'stub.txt', fileSizeBytes: 0);
  }
  @override
  Future<void> validateAttachment(File file, AttachmentType type) async {}
}

class _StubSpaceContextBuilder implements SpaceContextBuilder {
  @override
  Future<SpaceContext> build(String spaceId, {DateRange? dateRange, String? userQuery}) async {
    return SpaceContext(
      spaceId: spaceId,
      spaceName: 'Test Space',
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

class _StubAiConfigRepository implements AiConfigRepository {
  _StubAiConfigRepository()
      : _config = const AiConfig(
          enabled: true,
          mode: AiMode.fake,
          remoteUrl: '',
        );

  AiConfig _config;

  @override
  AiConfig get current => _config;

  @override
  Stream<AiConfig> get stream => Stream.value(_config);

  @override
  Future<AiConfig> loadConfig() async => _config;

  @override
  Future<void> setEnabled(bool enabled) async {
    _config = _config.copyWith(enabled: enabled);
  }

  @override
  Future<void> setMode(AiMode mode) async {
    _config = _config.copyWith(mode: mode);
  }
}

// Test controller that sets up initial state
class _TestController extends AiChatController {
  _TestController()
      : super(
          spaceId: 'health',
          sendChatMessageUseCase: SendChatMessageUseCase(
            aiChatService: FakeAiChatService(simulatedLatency: Duration.zero),
            chatThreadRepository: _StubThreadRepo(),
            consentRepository: _StubConsentRepo(),
            attachmentHandler: _StubAttachmentHandler(),
            spaceContextBuilder: _StubSpaceContextBuilder(),
            tokenBudgetAllocator: const FakeTokenBudgetAllocator(),
            uuid: const Uuid(),
          ),
          loadChatHistoryUseCase: LoadChatHistoryUseCase(
            chatThreadRepository: _StubThreadRepo(),
            uuid: const Uuid(),
          ),
          clearChatThreadUseCase: ClearChatThreadUseCase(
            chatThreadRepository: _StubThreadRepo(),
            attachmentHandler: _StubAttachmentHandler(),
          ),
          switchSpaceContextUseCase: SwitchSpaceContextUseCase(
            loadChatHistoryUseCase: LoadChatHistoryUseCase(
              chatThreadRepository: _StubThreadRepo(),
              uuid: const Uuid(),
            ),
            clearChatThreadUseCase: ClearChatThreadUseCase(
              chatThreadRepository: _StubThreadRepo(),
              attachmentHandler: _StubAttachmentHandler(),
            ),
            spaceContextBuilder: _StubSpaceContextBuilder(),
          ),
          chatThreadRepository: _StubThreadRepo(),
          spaceContextBuilder: _StubSpaceContextBuilder(),
          messageQueueService: _StubMessageQueueService(),
          connectivityMonitor: _StubConnectivityMonitor(_StubMessageQueueService()),
        );

  @override
  Future<void> loadInitial() async {
    state = AiChatState(
      isLoading: false,
      isSending: false,
      isOffline: false,
      thread: ChatThread(
        id: 't1',
        spaceId: 'health',
        messages: [
          ChatMessage(
            id: 'm1',
            threadId: 't1',
            sender: MessageSender.ai,
            content: 'hello',
            timestamp: DateTime(2025, 1, 1, 12, 0),
            attachments: const [],
          ),
        ],
      ),
      spaceContext: SpaceContext(
        spaceId: 'health',
        spaceName: 'Health',
        description: 'Health space',
        categories: const ['test'],
        persona: SpacePersona.health,
      ),
    );
  }
}

void main() {
  setUp(() {
    AppContainer.instance.registerSingleton<AiConfigRepository>(_StubAiConfigRepository());
  });

  testWidgets('renders chat screen with header, message list, and composer', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiChatControllerProvider.overrideWith((ref, spaceId) => _TestController()),
          aiChatServiceProvider.overrideWithValue(FakeAiChatService(simulatedLatency: Duration.zero)),
        ],
        child: const MaterialApp(
          home: AiChatScreen(spaceId: 'health'),
        ),
      ),
    );

    // Pump to build the widget
    await tester.pump();
    
    // Pump again to let the controller's loadInitial() complete
    await tester.pump();
    
    // Verify the screen builds
    expect(find.byType(AiChatScreen), findsOneWidget);
    
    // Verify header shows space name
    expect(find.text('Health'), findsOneWidget);
    
    // Verify message list is present
    expect(find.byType(ListView), findsOneWidget);
    
    // Verify composer is present (check for TextField instead of specific key)
    expect(find.byType(TextField), findsOneWidget);
  });
}

