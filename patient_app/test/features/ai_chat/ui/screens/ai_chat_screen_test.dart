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
import 'package:patient_app/core/ai/chat/repositories/chat_thread_repository.dart';
import 'package:patient_app/core/ai/chat/services/message_attachment_handler.dart';
import 'package:patient_app/core/ai/repositories/ai_consent_repository.dart';
import 'package:patient_app/features/ai_chat/ui/controllers/ai_chat_controller.dart';
import 'package:patient_app/features/ai_chat/ui/screens/ai_chat_screen.dart';
import 'package:uuid/uuid.dart';

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
  Future<SpaceContext> build(String spaceId) async {
    return SpaceContext(spaceId: spaceId, spaceName: 'Test Space', persona: SpacePersona.general);
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
        persona: SpacePersona.health,
      ),
    );
  }
}

void main() {
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


