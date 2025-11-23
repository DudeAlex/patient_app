import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';
import 'package:patient_app/features/ai_chat/ui/widgets/chat_message_bubble.dart';

void main() {
  ChatMessage baseMessage({
    MessageStatus status = MessageStatus.sent,
    List<MessageAttachment> attachments = const [],
  }) =>
      ChatMessage(
        id: 'm1',
        threadId: 't1',
        sender: MessageSender.user,
        content: 'Hello **world**',
        timestamp: DateTime(2025, 1, 1, 12, 0),
        status: status,
        attachments: attachments,
      );

  testWidgets('renders user message on right with markdown', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageBubble(message: baseMessage()),
        ),
      ),
    );

    expect(find.textContaining('Hello'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('shows loading indicator when sending', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageBubble(
            message: baseMessage(status: MessageStatus.sending),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows retry button when failed', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageBubble(
            message: baseMessage(status: MessageStatus.failed),
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('shows attachments with icons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageBubble(
            message: baseMessage(
              attachments: [
                MessageAttachment(
                  id: 'a1',
                  type: AttachmentType.photo,
                  fileName: 'pic.jpg',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('pic.jpg'), findsOneWidget);
    expect(find.byIcon(Icons.photo), findsOneWidget);
  });
}
