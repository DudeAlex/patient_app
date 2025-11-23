import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/fake_ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';

import 'package:patient_app/core/ai/chat/models/chat_message.dart';

void main() {
  FakeAiChatService buildService({
    Duration latency = const Duration(milliseconds: 10),
    Duration chunkDelay = const Duration(milliseconds: 1),
  }) =>
      FakeAiChatService(
        simulatedLatency: latency,
        streamChunkDelay: chunkDelay,
      );

  ChatRequest buildRequest({
    SpacePersona persona = SpacePersona.health,
    String message = 'Need help with my records',
  }) {
    return ChatRequest(
      threadId: 'thread_1',
      messageContent: message,
      spaceContext: SpaceContext(
        spaceId: 'space_1',
        spaceName: 'Health',
        persona: persona,
      ),
      messageHistory: [
        ChatMessage(
          id: 'm1',
          threadId: 'thread_1',
          sender: MessageSender.user,
          content: 'Previous note',
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  test('generates health persona response with safety-first tone', () async {
    final service = buildService();
    final response = await service.sendMessage(buildRequest(persona: SpacePersona.health));

    expect(response.isSuccess, isTrue);
    expect(response.metadata.provider, 'fake');
    expect(response.metadata.latencyMs, equals(service.simulatedLatency.inMilliseconds));
    expect(response.actionHints, isNotEmpty);
    expect(
      response.messageContent.toLowerCase(),
      allOf(
        contains('medical advice'),
        contains('safety-first'),
      ),
    );
  });

  test('generates persona-specific hints', () async {
    final service = buildService();
    final response = await service.sendMessage(
      buildRequest(persona: SpacePersona.finance, message: 'Budget check'),
    );

    expect(response.actionHints, contains('Set budget goals'));
    expect(response.metadata.tokensUsed, greaterThan(0));
  });

  test('streams response chunks and marks completion', () async {
    final service = buildService();
    final request = buildRequest(message: 'Plan trip soon');

    final chunks = await service.sendMessageStream(request).toList();

    expect(chunks, isNotEmpty);
    expect(chunks.last.isComplete, isTrue);
    expect(chunks.last.content, isNotEmpty);
    expect(
      chunks.last.content.split(' ').length,
      equals(chunks.length),
    );
  });

  test('summarizeItem returns deterministic summary', () async {
    final service = buildService();
    final item = InformationItem(
      id: 1,
      spaceId: 'health',
      domainId: 'visit',
      data: {
        'title': 'Cardiology follow-up',
        'notes': 'Discussed blood pressure and medication adjustments.',
        'tags': ['cardio', 'bp'],
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await service.summarizeItem(item);

    expect(result.isSuccess, isTrue);
    expect(result.summaryText.toLowerCase(), contains('cardiology follow-up'));
    expect(result.actionHints, isNotEmpty);
    expect(result.provider, 'fake');
  });
}
