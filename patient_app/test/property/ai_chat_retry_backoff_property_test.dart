import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:patient_app/core/ai/chat/http_ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';

void main() {
  test('Property: Retry exponential backoff stays within jittered 1s/2s/4s', () async {
    final random = Random(123);
    final observed = <Duration>[];
    final client = MockClient((_) async => http.Response('error', 500));

    final service = HttpAiChatService(
      client: client,
      baseUrl: 'https://api.example.com',
      maxRetries: 3,
      connectivityCheck: () async => [ConnectivityResult.wifi],
      backoffObserver: observed.add,
    );

    final request = ChatRequest(
      threadId: 'thread-1',
      messageContent: 'Hello retry property',
      spaceContext: SpaceContext(
        spaceId: 'health',
        spaceName: 'Health',
        persona: SpacePersona.health,
      ),
    );

    await expectLater(service.sendMessage(request), throwsA(isA<Exception>()));

    expect(observed.length, 2);

    const bases = [1, 2];
    for (var i = 0; i < observed.length; i++) {
      final delay = observed[i].inMilliseconds;
      final expected = bases[i] * 1000;
      final lower = (expected * 0.8).floor();
      final upper = (expected * 1.2).ceil();
      expect(delay, inInclusiveRange(lower, upper));
    }
  });
}
