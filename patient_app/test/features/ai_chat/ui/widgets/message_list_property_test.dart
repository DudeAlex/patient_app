import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/features/ai_chat/ui/widgets/message_list.dart';
import 'package:patient_app/features/ai_chat/ui/widgets/chat_message_bubble.dart';

void main() {
  testWidgets('MessageList renders at most initialVisibleCount initially', (tester) async {
    final rand = Random(123);
    for (var i = 0; i < 5; i++) {
      final total = 20 + rand.nextInt(80); // 20..99 messages
      final messages = List.generate(
        total,
        (idx) => ChatMessage(
          id: 'm$idx',
          threadId: 't1',
          sender: idx.isEven ? MessageSender.user : MessageSender.ai,
          content: 'message $idx',
          timestamp: DateTime(2025, 1, 1, 0, idx),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageList(
              messages: messages,
              onRetry: () {},
              onCopy: (_) {},
              onActionHintTap: (_) {},
              onLoadMore: () {},
            ),
          ),
        ),
      );

      // MessageList internally caps to initialVisibleCount (50) but the viewport
      // may render fewer depending on layout; assert it never exceeds the cap.
      final rendered = find.byType(ChatMessageBubble);
      final count = rendered.evaluate().length;
      expect(count <= 50, isTrue);
      expect(count, greaterThan(0));
    }
  });

  testWidgets('MessageList build completes within reasonable time for 100 messages', (tester) async {
    final messages = List.generate(
      100,
      (idx) => ChatMessage(
        id: 'm$idx',
        threadId: 't1',
        sender: MessageSender.user,
        content: 'message $idx',
        timestamp: DateTime(2025, 1, 1, 0, idx),
      ),
    );

    final sw = Stopwatch()..start();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageList(
            messages: messages,
            onRetry: () {},
            onCopy: (_) {},
            onActionHintTap: (_) {},
            onLoadMore: () {},
          ),
        ),
      ),
    );
    sw.stop();

    expect(sw.elapsedMilliseconds < 500, isTrue);
  });
}
