import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/core/ai/chat/models/chat_thread.dart';

void main() {
  group('ChatThreadRepository contract (domain-level expectations)', () {
    test('ChatThread is immutable and preserves message order', () {
      final msg1 = ChatMessage(
        id: 'm1',
        threadId: 't1',
        sender: MessageSender.user,
        content: 'hello',
        timestamp: DateTime(2025, 1, 1, 12, 0),
      );
      final msg2 = ChatMessage(
        id: 'm2',
        threadId: 't1',
        sender: MessageSender.ai,
        content: 'world',
        timestamp: DateTime(2025, 1, 1, 12, 1),
      );

      final thread = ChatThread(
        id: 't1',
        spaceId: 'health',
        messages: [msg1, msg2],
        createdAt: DateTime(2025, 1, 1),
      );

      expect(thread.messages.first.id, 'm1');
      expect(thread.messages.last.id, 'm2');
      expect(() => thread.messages.add(msg1), throwsUnsupportedError);
    });

    test('ChatThread copyWith replaces message list immutably', () {
      final original = ChatThread(
        id: 't1',
        spaceId: 'health',
        messages: const [],
        createdAt: DateTime(2025, 1, 1),
      );
      final msg = ChatMessage(
        id: 'm1',
        threadId: 't1',
        sender: MessageSender.user,
        content: 'text',
        timestamp: DateTime(2025, 1, 2),
      );

      final updated = original.copyWith(messages: [msg]);

      expect(updated.messages, hasLength(1));
      expect(original.messages, isEmpty);
    });
  });
}
