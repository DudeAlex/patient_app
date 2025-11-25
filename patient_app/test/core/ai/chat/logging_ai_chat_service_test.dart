import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/logging_ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/models/ai_call_log_entry.dart';
import 'package:patient_app/core/ai/repositories/ai_call_log_repository.dart';
import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';

import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';

class _StubChatService implements AiChatService {
  _StubChatService({
    ChatResponse? response,
    Stream<ChatResponseChunk>? stream,
    Exception? toThrow,
  })  : _response = response,
        _stream = stream,
        _toThrow = toThrow;

  final ChatResponse? _response;
  final Stream<ChatResponseChunk>? _stream;
  final Exception? _toThrow;

  int sendCalls = 0;
  int streamCalls = 0;

  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    sendCalls++;
    if (_toThrow != null) throw _toThrow!;
    return _response!;
  }

  @override
  Stream<ChatResponseChunk> sendMessageStream(ChatRequest request) async* {
    streamCalls++;
    if (_toThrow != null) throw _toThrow!;
    yield* _stream!;
  }

  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) {
    return Future.value(
      AiSummaryResult.success(
        summaryText: 'ok',
        provider: 'stub',
      ),
    );
  }
}

ChatRequest _request() {
  return ChatRequest(
    threadId: 'thread-1',
    messageContent: 'Hello',
    spaceContext: SpaceContext(
      spaceId: 'health',
      spaceName: 'Health',
      description: 'Health space',
      categories: const ['test'],
      persona: SpacePersona.health,
    ),
    attachments: [
      MessageAttachment(
        id: 'a1',
        type: AttachmentType.photo,
        localPath: '/secret',
        fileName: 'img.jpg',
      ),
    ],
    messageHistory: [
      ChatMessage(
        id: 'm1',
        threadId: 'thread-1',
        sender: MessageSender.user,
        content: 'Hi',
        timestamp: DateTime(2025, 1, 1),
      ),
    ],
  );
}

void main() {
  test('delegates sendMessage and returns response', () async {
    final delegate = _StubChatService(
      response: ChatResponse.success(
        messageContent: 'Hi back',
        metadata: AiMessageMetadata(
          tokensUsed: 10,
          latencyMs: 20,
          provider: 'fake',
        ),
      ),
    );
    final callLogRepo = AiCallLogRepository(maxEntries: 5);
    final service = LoggingAiChatService(delegate, callLogRepository: callLogRepo);

    final result = await service.sendMessage(_request());

    expect(delegate.sendCalls, 1);
    expect(result.messageContent, 'Hi back');
    expect(callLogRepo.entries, isNotEmpty);
    expect(callLogRepo.entries.first.provider, 'fake');
  });

  test('delegates sendMessageStream and yields chunks', () async {
    final delegate = _StubChatService(
      stream: Stream.value(const ChatResponseChunk(content: 'partial', isComplete: true)),
    );
    final callLogRepo = AiCallLogRepository();
    final service = LoggingAiChatService(delegate, callLogRepository: callLogRepo);

    final chunks = await service.sendMessageStream(_request()).toList();

    expect(delegate.streamCalls, 1);
    expect(chunks, isNotEmpty);
    expect(chunks.first.isComplete, isTrue);
  });

  test('propagates errors from delegate', () async {
    final delegate = _StubChatService(toThrow: AiConsentRequiredException());
    final callLogRepo = AiCallLogRepository(maxEntries: 5);
    final service = LoggingAiChatService(delegate, callLogRepository: callLogRepo);

    expect(
      () => service.sendMessage(_request()),
      throwsA(isA<AiConsentRequiredException>()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(callLogRepo.entries.length, 1);
    expect(callLogRepo.entries.first.success, isFalse);
  });

  test('delegates summarizeItem', () async {
    final delegate = _StubChatService(response: ChatResponse.success(messageContent: 'ok'));
    final service = LoggingAiChatService(delegate);

    final result = await service.summarizeItem(
      InformationItem(
        spaceId: 'health',
        domainId: 'visit',
        data: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    expect(result.provider, 'stub');
  });
}

