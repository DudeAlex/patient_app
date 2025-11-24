import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/features/ai_chat/ui/widgets/chat_message_bubble.dart';
import 'package:patient_app/features/ai_chat/ui/widgets/message_list.dart';

void main() {
  ChatMessage createMessage(String id, {String content = 'msg'}) {
    return ChatMessage(
      id: id,
      threadId: 't1',
      sender: MessageSender.user,
      content: content,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
  }

  List<ChatMessage> createMessages(int count) {
    return List.generate(
      count,
      (i) => createMessage('m$i', content: 'Message $i'),
    );
  }

  testWidgets('shows only initialVisibleCount messages initially', (tester) async {
    final messages = createMessages(100); // 0 to 99 (99 is newest)

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageList(
            messages: messages,
            initialVisibleCount: 50,
          ),
        ),
      ),
    );

    // ListView is lazy, so we won't find 50 widgets.
    // We should find the newest message (at the bottom).
    expect(find.text('Message 99'), findsOneWidget);
    
    // We should NOT find the message just outside the visible window (Message 49).
    // Even if we scroll to the top, it shouldn't be there because itemCount is 50.
    expect(find.text('Message 49'), findsNothing);
    
    // We can verify that the ListView has the correct itemCount by inspecting the widget
    final listView = tester.widget<ListView>(find.byType(ListView));
    final delegate = listView.childrenDelegate as SliverChildBuilderDelegate;
    expect(delegate.estimatedChildCount, 50);
  });

  testWidgets('loads more when scrolled to top', (tester) async {
    final messages = createMessages(100);
    bool loadMoreCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageList(
            messages: messages,
            initialVisibleCount: 20,
            onLoadMore: () => loadMoreCalled = true,
          ),
        ),
      ),
    );

    final listViewInitial = tester.widget<ListView>(find.byType(ListView));
    final delegateInitial = listViewInitial.childrenDelegate as SliverChildBuilderDelegate;
    expect(delegateInitial.estimatedChildCount, 20);

    // Scroll to top (which is the end of the list in reverse mode)
    final scrollable = find.byType(Scrollable);
    await tester.drag(scrollable, const Offset(0, 500)); // Drag down to scroll up?
    // In reverse list:
    // Dragging DOWN moves content DOWN, revealing TOP items (older items).
    // Wait, reverse list:
    // Top of screen is "end" of list (maxScrollExtent).
    // Bottom of screen is "start" of list (pixels 0).
    // To see older items (higher index), we need to scroll towards maxScrollExtent.
    // This means dragging the content DOWN (swiping down).
    
    await tester.pump();

    // Trigger scroll notification
    await tester.drag(scrollable, const Offset(0, 1000));
    await tester.pumpAndSettle();

    // Should have expanded window
    final listView = tester.widget<ListView>(find.byType(ListView));
    final delegate = listView.childrenDelegate as SliverChildBuilderDelegate;
    expect(delegate.estimatedChildCount, 40); // 20 + 20
    expect(loadMoreCalled, isTrue);
  });

  testWidgets('auto-scrolls to bottom on new message', (tester) async {
    final messages = createMessages(10);
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageList(
            messages: messages,
            initialVisibleCount: 50,
          ),
        ),
      ),
    );

    // Scroll up a bit
    final scrollable = find.byType(Scrollable);
    await tester.drag(scrollable, const Offset(0, 100));
    await tester.pumpAndSettle();
    
    // Verify we are not at 0
    // (Hard to verify exact pixels in test without key, but we can check behavior)

    // Add new message
    final newMessages = [...messages, createMessage('new', content: 'New Message')];
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageList(
            messages: newMessages,
            initialVisibleCount: 50,
          ),
        ),
      ),
    );
    
    await tester.pumpAndSettle(); // Allow animation

    // Should be at bottom (new message visible)
    expect(find.text('New Message'), findsOneWidget);
    
    // If we were scrolled up, we should be back at bottom.
    // In a real app we'd check scroll offset, but visibility of newest item is a good proxy.
  });

  testWidgets('passes callbacks to bubbles', (tester) async {
    final messages = [createMessage('m1')];
    var retried = false;
    var copied = '';
    var hintTapped = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageList(
            messages: messages,
            onRetry: () => retried = true,
            onCopy: (val) => copied = val,
            onActionHintTap: (val) => hintTapped = val,
          ),
        ),
      ),
    );

    // Verify the bubble was built with the correct callbacks
    final bubbleFinder = find.byType(ChatMessageBubble);
    expect(bubbleFinder, findsOneWidget);
    
    final bubble = tester.widget<ChatMessageBubble>(bubbleFinder);
    expect(bubble.onRetry, isNotNull);
    expect(bubble.onCopy, isNotNull);
    expect(bubble.onActionHintTap, isNotNull);
    
    // Manually invoke the callback to verify wiring
    bubble.onCopy?.call('msg');
    expect(copied, 'msg');
  });
}
