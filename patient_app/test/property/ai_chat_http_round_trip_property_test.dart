import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/io_client.dart';
import 'package:patient_app/core/ai/chat/http_ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';

String _randomMessage(Random random, int min, int max) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789';
  final length = min + random.nextInt(max - min + 1);
  return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
}

void main() {
  test('Property: HTTP connectivity round trip echoes message content', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    server.listen((HttpRequest request) async {
      expect(request.uri.path, '/api/v1/chat/echo');
      final body = await utf8.decoder.bind(request).join();
      final jsonBody = jsonDecode(body) as Map<String, dynamic>;
      final message = jsonBody['message'] as String?;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'threadId': jsonBody['threadId'],
          'message': 'Echo: $message',
          'metadata': {
            'processingTimeMs': 1,
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

    final random = Random(42);
    final messages = List.generate(
      20,
      (_) => _randomMessage(random, 5, 50),
    );

    for (var i = 0; i < messages.length; i++) {
      final request = ChatRequest(
        threadId: 'thread-$i',
        messageContent: messages[i],
        spaceContext: SpaceContext(
          spaceId: 'health',
          spaceName: 'Health',
          description: 'Health space',
          categories: const ['test'],
          persona: SpacePersona.health,
        ),
      );

      final response = await service.sendMessage(request);
      expect(response.messageContent, 'Echo: ${messages[i]}');
      expect(response.metadata.provider, 'none');
    }
  });
}
