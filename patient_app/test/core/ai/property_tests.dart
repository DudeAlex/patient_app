import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:patient_app/core/ai/ai_service.dart';
import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';
import 'package:patient_app/core/ai/fake_ai_service.dart';
import 'package:patient_app/core/ai/http/http_ai_service.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/ai/repositories/ai_consent_repository.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';
import 'package:patient_app/features/information_items/application/use_cases/summarize_information_item_use_case.dart';
import 'package:patient_app/core/ai/chat/application/use_cases/send_chat_message_use_case.dart';
import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/models/chat_thread.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/chat/repositories/chat_thread_repository.dart';
import 'package:patient_app/core/ai/chat/services/message_attachment_handler.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';
import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';
import 'package:uuid/uuid.dart';

class _StubConsentRepo implements AiConsentRepository {
  bool consent;
  _StubConsentRepo(this.consent);
  @override
  Future<bool> hasConsent() async => consent;
  @override
  Future<void> grantConsent() async => consent = true;
  @override
  Future<void> revokeConsent() async => consent = false;
}


void main() {
  group('Property tests - FakeAiService', () {
    final now = DateTime.now();
    InformationItem buildItem(String notes) => InformationItem(
          spaceId: 'space',
          domainId: 'domain',
          data: {'title': 'Title', 'notes': notes, 'tags': ['tag']},
          createdAt: now,
          updatedAt: now,
        );

    test('summary stays reasonably short (<350 words)', () async {
      final service = FakeAiService(latency: Duration.zero);
      final rand = Random(42);
      for (var i = 0; i < 20; i++) {
        final notes = _randomText(rand, 200);
        final result = await service.summarizeItem(buildItem(notes));
        final wordCount = result.summaryText.trim().split(RegExp(r'\s+')).length;
        expect(wordCount <= 350, isTrue);
      }
    });

    test('action hints <=3 and each <=12 words', () async {
      final service = FakeAiService(latency: Duration.zero);
      final rand = Random(99);
      for (var i = 0; i < 10; i++) {
        final result = await service.summarizeItem(buildItem(_randomText(rand, 50)));
        expect(result.actionHints.length <= 3, isTrue);
        for (final hint in result.actionHints) {
          final words = hint.trim().split(RegExp(r'\s+')).length;
          expect(words <= 12, isTrue);
        }
      }
    });
  });

  test('Use case enforces consent (property)', () async {
    final now = DateTime.now();
    final item = InformationItem(spaceId: 'space', domainId: 'domain', data: {}, createdAt: now, updatedAt: now);
    final ai = _ImmediateAiService();
    final rand = Random(7);
    for (var i = 0; i < 20; i++) {
      final consent = rand.nextBool();
      final repo = _StubConsentRepo(consent);
      final useCase = SummarizeInformationItemUseCase(aiService: ai, consentRepository: repo);
      if (consent) {
        final result = await useCase.execute(item);
        expect(result.summaryText, 'ok');
      } else {
        expect(() => useCase.execute(item), throwsA(isA<AiConsentRequiredException>()));
      }
    }
  });

  test('HttpAiService retries up to maxRetries', () async {
    var callCount = 0;
    final client = MockClient((request) async {
      callCount++;
      return http.Response('error', 500);
    });
    final service = HttpAiService(
      client: client,
      baseUrl: 'https://example.com',
      maxRetries: 3,
      timeout: const Duration(milliseconds: 10),
    );
    final now = DateTime.now();
    final item = InformationItem(spaceId: 'space', domainId: 'domain', data: {}, createdAt: now, updatedAt: now);
    await expectLater(
      service.summarizeItem(item),
      throwsA(isA<AiProviderUnavailableException>()),
    );
    expect(callCount, 3);
  });

  group('Property tests - chat consent enforcement', () {
    final threadId = 't1';
    final spaceContext = SpaceContext(
      spaceId: 'health',
      spaceName: 'Health',
      persona: SpacePersona.health,
    );

    ChatRequest request() => ChatRequest(
          threadId: threadId,
          messageContent: 'hi',
          spaceContext: spaceContext,
          messageHistory: [
            ChatMessage(
              id: 'm1',
              threadId: threadId,
              sender: MessageSender.user,
              content: 'prev',
              timestamp: DateTime.now(),
            ),
          ],
        );

    test('SendChatMessageUseCase throws when consent is false', () async {
      final rand = Random(7);
      for (var i = 0; i < 10; i++) {
        final consent = rand.nextBool();
        final consentRepo = _StubConsentRepo(consent);
        final useCase = SendChatMessageUseCase(
          aiChatService: _StubChatService(
            ChatResponse.success(messageContent: 'hello'),
          ),
          chatThreadRepository: _InMemoryThreadRepo(),
          consentRepository: consentRepo,
          attachmentHandler: _NoopAttachmentHandler(),
          uuid: const Uuid(),
        );

        if (!consent) {
          expect(
            () => useCase.execute(
              threadId: threadId,
              spaceContext: spaceContext,
              messageContent: 'hello',
            ),
            throwsA(isA<AiConsentRequiredException>()),
          );
        } else {
          final response = await useCase.execute(
            threadId: threadId,
            spaceContext: spaceContext,
            messageContent: 'hello',
          );
          expect(response.content, 'hello');
        }
      }
    });
  });

  group('Property tests - chat context propagation', () {
    final rand = Random(101);
    SpaceContext buildSpace(int i) => SpaceContext(
          spaceId: 'space_$i',
          spaceName: 'Space $i',
          persona: SpacePersona.values[i % SpacePersona.values.length],
        );

    InformationItem buildItem(int i) => InformationItem(
          id: i,
          spaceId: 'space_$i',
          domainId: 'domain_$i',
          data: {'title': 'Item $i'},
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        );

    test('ChatRequest carries correct space id/persona', () {
      for (var i = 0; i < 20; i++) {
        final ctx = buildSpace(i);
        final request = ChatRequest(
          threadId: 't$i',
          messageContent: 'hello',
          spaceContext: ctx,
          messageHistory: [],
        );

        expect(request.spaceContext.spaceId, ctx.spaceId);
        expect(request.spaceContext.persona, ctx.persona);
      }
    });

    test('Record summaries carry the originating space and title', () {
      for (var i = 0; i < 10; i++) {
        final item = buildItem(i);
        final summary = RecordSummary(
          title: item.data['title'] as String,
          category: 'category_$i',
          tags: ['t$i'],
          createdAt: item.createdAt,
        );

        expect(summary.title, contains(item.data['title'] as String));
        expect(summary.category, 'category_$i');
        expect(summary.tags, contains('t$i'));
      }
    });
  });

  group('Property tests - chat payload safety', () {
    test('attachments exclude local paths when building ChatRequest', () {
      final request = ChatRequest(
        threadId: 't-safety',
        messageContent: 'hello',
        spaceContext: SpaceContext(
          spaceId: 'space_safety',
          spaceName: 'Space Safety',
          persona: SpacePersona.general,
        ),
        attachments: [
          MessageAttachment(
            id: 'a1',
            type: AttachmentType.file,
            localPath: '/secret/path',
            fileName: 'doc.pdf',
          ),
        ],
        messageHistory: const [],
      );

      final json = request.toJson();
      final attachments = json['attachments'] as List;
      expect(attachments.first.containsKey('localPath'), isFalse);
    });

    test('message history is trimmed to maxHistoryMessages', () {
      final history = List.generate(
        60,
        (i) => ChatMessage(
          id: 'm$i',
          threadId: 't',
          sender: MessageSender.user,
          content: 'msg $i',
          timestamp: DateTime(2025, 1, 1, 0, i),
        ),
      );

      final request = ChatRequest(
        threadId: 't-hist',
        messageContent: 'hi',
        spaceContext: SpaceContext(
          spaceId: 's',
          spaceName: 'S',
          persona: SpacePersona.general,
        ),
        messageHistory: history,
        maxHistoryMessages: 50,
      );

      expect(request.limitedHistory.length, 50);
      expect(request.limitedHistory.first.id, 'm0'); // taking first 50 of 60
    });
  });
}

class _StubChatService implements AiChatService {
  _StubChatService(this._response);
  final ChatResponse _response;
  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async => _response;
  @override
  Stream<ChatResponseChunk> sendMessageStream(ChatRequest request) async* {
    yield ChatResponseChunk(content: _response.messageContent, isComplete: true);
  }

  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) {
    return Future.value(AiSummaryResult.success(summaryText: 'ok', provider: 'stub'));
  }
}

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

class _NoopAttachmentHandler implements MessageAttachmentHandler {
  @override
  Future<MessageAttachment> processAttachment(
          {required File sourceFile, required AttachmentType type, required String targetThreadId}) async =>
      MessageAttachment(id: 'noop', type: type);

  @override
  Future<void> deleteAttachment(MessageAttachment attachment) async {}

  @override
  Future<void> validateAttachment(File file, AttachmentType type) async {}
}

class _ImmediateAiService implements AiService {
  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) async {
    return AiSummaryResult.success(summaryText: 'ok');
  }
}

String _randomText(Random rand, int words) {
  return List.generate(words, (_) => 'word${rand.nextInt(1000)}').join(' ');
}
