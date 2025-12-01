import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/io_client.dart';
import 'package:patient_app/core/ai/chat/http_ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';

ChatRequest _request() {
  return ChatRequest(
    threadId: 'thread-1',
    messageContent: 'Hello echo',
    spaceContext: SpaceContext(
      spaceId: 'health',
      spaceName: 'Health',
      description: 'Health space',
      categories: const ['test'],
      persona: SpacePersona.health,
    ),
    messageHistory: const [],
    attachments: const [],
  );
}

void main() {
  test('echo endpoint round trip over HTTP', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    late HttpRequest captured;
    server.listen((HttpRequest request) async {
      captured = request;
      expect(request.uri.path, '/api/v1/chat/message');
      final body = await utf8.decoder.bind(request).join();
      final jsonBody = jsonDecode(body) as Map<String, dynamic>;
      expect(jsonBody['message'], 'Hello echo');
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'responseId': 'resp-1',
          'threadId': jsonBody['threadId'],
          'message': 'Echo: ${jsonBody['message']}',
          'timestamp': DateTime.now().toIso8601String(),
          'metadata': {
            'processingTimeMs': 1,
            'stage': 'echo',
            'llmProvider': 'none',
            'tokenUsage': {'prompt': 0, 'completion': 0, 'total': 0},
          },
        }),
      );
      await request.response.close();
    });

    final service = HttpAiChatService(
      client: IOClient(HttpClient()),
      baseUrl: 'http://localhost:${server.port}',
      connectivityCheck: () async => [ConnectivityResult.wifi],
    );

    final response = await service.sendMessage(_request());

    expect(captured.headers.value('x-correlation-id'), isNotNull);
    expect(response.messageContent, 'Echo: Hello echo');
    expect(response.metadata.provider, 'none');
  });
}
