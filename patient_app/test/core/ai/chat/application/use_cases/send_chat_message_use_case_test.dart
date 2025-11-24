import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/application/use_cases/send_chat_message_use_case.dart';
import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/chat/repositories/chat_thread_repository.dart';
import 'package:patient_app/core/ai/chat/services/message_attachment_handler.dart';
import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';
import 'package:patient_app/core/ai/models/ai_error.dart';
import 'package:patient_app/core/ai/repositories/ai_consent_repository.dart';
import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';
import 'package:patient_app/core/ai/chat/models/chat_thread.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';
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
    final updated = thread.messages.map((m) {
      if (m.id == messageId) {
        return m.copyWith(
          status: status,
          actionHints: m.actionHints,
          aiMetadata: m.aiMetadata,
          error: errorMessage != null
              ? AiError(
                  message: errorMessage,
                  isRetryable: errorRetryable ?? false,
                  code: errorCode,
                )
              : null,
        );
      }
      return m;
    }).toList();
    _store[threadId] = thread.copyWith(messages: updated);
  }
}

class _StubConsentRepo implements AiConsentRepository {
  _StubConsentRepo(this._hasConsent);
  bool _hasConsent;

  @override
  Future<bool> hasConsent() async => _hasConsent;

  @override
  Future<void> setConsent(bool consent) async {
    _hasConsent = consent;
  }

  @override
  Future<void> grantConsent() async {
    _hasConsent = true;
  }

  @override
  Future<void> revokeConsent() async {
    _hasConsent = false;
  }
}

class _StubAttachmentHandler implements MessageAttachmentHandler {
  int processCalls = 0;
  int deleteCalls = 0;

  @override
  Future<MessageAttachment> processAttachment(
      {required File sourceFile, required AttachmentType type, required String targetThreadId}) async {
    processCalls++;
    return MessageAttachment(
      id: 'att-${processCalls}',
      type: type,
      localPath: sourceFile.path,
      fileName: sourceFile.uri.pathSegments.last,
      fileSizeBytes: await sourceFile.length(),
      mimeType: 'text/plain',
    );
  }

  @override
  Future<void> deleteAttachment(MessageAttachment attachment) async {
    deleteCalls++;
  }

  @override
  Future<void> validateAttachment(File file, AttachmentType type) async {}
}

class _StubAiChatService implements AiChatService {
  _StubAiChatService({ChatResponse? response, Exception? toThrow})
      : _response = response,
        _toThrow = toThrow;

  final ChatResponse? _response;
  final Exception? _toThrow;

  int calls = 0;

  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    calls++;
    if (_toThrow != null) throw _toThrow!;
    return _response!;
  }

  @override
  Stream<ChatResponseChunk> sendMessageStream(ChatRequest request) => const Stream.empty();

  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) {
    throw UnimplementedError();
  }
}

SpaceContext _context() => SpaceContext(
      spaceId: 'health',
      spaceName: 'Health',
      persona: SpacePersona.health,
    );

void main() {
  test('sends chat message, processes attachments, and stores AI reply', () async {
    final repo = _InMemoryThreadRepo();
    final consent = _StubConsentRepo(true);
    final attachments = _StubAttachmentHandler();
    final aiService = _StubAiChatService(
      response: ChatResponse.success(
        messageContent: 'AI reply',
        actionHints: const ['Hint'],
        metadata: AiMessageMetadata(tokensUsed: 5, latencyMs: 10, provider: 'fake'),
      ),
    );

    final useCase = SendChatMessageUseCase(
      aiChatService: aiService,
      chatThreadRepository: repo,
      consentRepository: consent,
      attachmentHandler: attachments,
      uuid: const Uuid(),
    );

    final tempFile = await File('${Directory.systemTemp.path}/att.txt').writeAsString('data');

    final aiMessage = await useCase.execute(
      threadId: 'thread-1',
      spaceContext: _context(),
      messageContent: 'Hello',
      attachments: [
        ChatAttachmentInput(file: tempFile, type: AttachmentType.file),
      ],
    );

    final thread = await repo.getById('thread-1');
    expect(thread, isNotNull);
    expect(thread!.messages.length, 2);
    expect(thread.messages.first.sender, MessageSender.user);
    expect(thread.messages.first.status, MessageStatus.sent);
    expect(attachments.processCalls, 1);
    expect(aiMessage.content, 'AI reply');
    expect(aiMessage.actionHints, contains('Hint'));
  });

  test('throws when consent missing', () async {
    final repo = _InMemoryThreadRepo();
    await repo.saveThread(ChatThread(id: 't1', spaceId: 'health', messages: const []));
    final useCase = SendChatMessageUseCase(
      aiChatService: _StubAiChatService(
        response: ChatResponse.success(messageContent: 'ok'),
      ),
      chatThreadRepository: repo,
      consentRepository: _StubConsentRepo(false),
      attachmentHandler: _StubAttachmentHandler(),
      uuid: const Uuid(),
    );

    expect(
      () => useCase.execute(
        threadId: 't1',
        spaceContext: _context(),
        messageContent: 'hi',
      ),
      throwsA(isA<AiConsentRequiredException>()),
    );
  });

  test('marks user message failed when AI call throws', () async {
    final repo = _InMemoryThreadRepo();
    await repo.saveThread(ChatThread(id: 't1', spaceId: 'health', messages: const []));
    final useCase = SendChatMessageUseCase(
      aiChatService: _StubAiChatService(toThrow: AiProviderUnavailableException()),
      chatThreadRepository: repo,
      consentRepository: _StubConsentRepo(true),
      attachmentHandler: _StubAttachmentHandler(),
      uuid: const Uuid(),
    );

    await expectLater(
      () => useCase.execute(
        threadId: 't1',
        spaceContext: _context(),
        messageContent: 'hi',
      ),
      throwsA(isA<AiProviderUnavailableException>()),
    );

    final thread = await repo.getById('t1');
    expect(thread, isNotNull);
    expect(thread!.messages.first.status, MessageStatus.failed);
  });
}
