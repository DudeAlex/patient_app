import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:patient_app/core/ai/chat/http_ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';
import 'package:patient_app/core/ai/models/ai_error.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';

import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';

ChatRequest _request() {
  return ChatRequest(
    threadId: 'thread-1',
    messageContent: 'Hello world',
    spaceContext: SpaceContext(
      spaceId: 'health',
      spaceName: 'Health',
      persona: SpacePersona.health,
    ),
    attachments: [
      MessageAttachment(
        id: 'att-1',
        type: AttachmentType.photo,
        localPath: '/tmp/secret/path.jpg',
        fileName: 'path.jpg',
        fileSizeBytes: 123,
        mimeType: 'image/jpeg',
      ),
    ],
    messageHistory: [
      ChatMessage(
        id: 'm1',
        threadId: 'thread-1',
        sender: MessageSender.user,
        content: 'Earlier message',
        timestamp: DateTime(2025, 1, 1),
      ),
    ],
  );
}

void main() {
  test('sends payload and parses success response', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['threadId'], equals('thread-1'));
      expect(body['attachments'], isA<List>());
      expect((body['attachments'] as List).first.containsKey('localPath'), isFalse);
      return http.Response(
        jsonEncode({
          'message': 'Hi back',
          'actionHints': ['Do next thing'],
          'metadata': {
            'tokensUsed': 42,
            'latencyMs': 1200,
            'provider': 'remote',
            'confidence': 0.75,
          }
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = HttpAiChatService(
      client: client,
      baseUrl: 'https://api.example.com',
      timeout: const Duration(seconds: 1),
    );

    final response = await service.sendMessage(_request());

    expect(captured.url.toString(), 'https://api.example.com/chat/send');
    expect(response.messageContent, 'Hi back');
    expect(response.actionHints, contains('Do next thing'));
    expect(response.metadata.tokensUsed, 42);
    expect(response.metadata.provider, 'remote');
  });

  test('retries on retryable status and succeeds', () async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      if (calls == 1) {
        return http.Response('error', 500);
      }
      return http.Response(jsonEncode({'message': 'ok', 'metadata': {}}), 200,
          headers: {'content-type': 'application/json'});
    });

    final service = HttpAiChatService(
      client: client,
      baseUrl: 'https://api.example.com',
      timeout: const Duration(seconds: 1),
      maxRetries: 3,
    );

    final response = await service.sendMessage(_request());

    expect(calls, 2);
    expect(response.messageContent, 'ok');
  });

  test('throws non-retryable status as provider unavailable', () async {
    final client = MockClient((_) async => http.Response('bad request', 400));
    final service = HttpAiChatService(
      client: client,
      baseUrl: 'https://api.example.com',
      timeout: const Duration(seconds: 1),
      maxRetries: 2,
    );

    expect(
      () => service.sendMessage(_request()),
      throwsA(
        isA<AiProviderUnavailableException>().having(
          (e) => e.error,
          'error',
          isA<AiError>().having((err) => err.isRetryable, 'retryable', isFalse),
        ),
      ),
    );
  });

  test('throws timeout after max retries', () async {
    final client = MockClient((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return http.Response('slow', 200);
    });
    final service = HttpAiChatService(
      client: client,
      baseUrl: 'https://api.example.com',
      timeout: const Duration(milliseconds: 50),
      maxRetries: 1,
    );

    expect(
      () => service.sendMessage(_request()),
      throwsA(
        isA<AiProviderUnavailableException>().having(
          (e) => e.error,
          'error',
          isA<AiError>().having((err) => err.isRetryable, 'retryable', isTrue),
        ),
      ),
    );
  });
}
