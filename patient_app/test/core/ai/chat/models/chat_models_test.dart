import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/core/ai/chat/models/chat_thread.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';

void main() {
  group('MessageAttachment', () {
    test('toMetadataJson excludes localPath and includes metadata', () {
      final attachment = MessageAttachment(
        id: 'a1',
        type: AttachmentType.photo,
        localPath: '/tmp/image.jpg',
        fileName: 'image.jpg',
        fileSizeBytes: 1024,
        mimeType: 'image/jpeg',
        transcription: 'sample',
      );

      final metadata = attachment.toMetadataJson();

      expect(metadata['id'], 'a1');
      expect(metadata['type'], 'photo');
      expect(metadata['fileName'], 'image.jpg');
      expect(metadata['fileSizeBytes'], 1024);
      expect(metadata['mimeType'], 'image/jpeg');
      expect(metadata['transcription'], 'sample');
      expect(metadata.containsKey('localPath'), isFalse);
    });
  });

  group('ChatMessage', () {
    test('validates content or attachments are present', () {
      expect(
        () => ChatMessage(
          id: 'm1',
          threadId: 't1',
          sender: MessageSender.user,
          content: '',
          timestamp: DateTime(2025, 1, 1),
        ),
        throwsA(isA<AssertionError>()),
      );

      expect(
        ChatMessage(
          id: 'm2',
          threadId: 't1',
          sender: MessageSender.user,
          content: '',
          timestamp: DateTime(2025, 1, 1),
          attachments: [
            MessageAttachment(id: 'a1', type: AttachmentType.file),
          ],
        ),
        isA<ChatMessage>(),
      );
    });

    test('copyWith updates fields immutably', () {
      final original = ChatMessage(
        id: 'm1',
        threadId: 't1',
        sender: MessageSender.user,
        content: 'hello',
        timestamp: DateTime(2025, 1, 1),
        status: MessageStatus.sending,
        attachments: [
          MessageAttachment(id: 'a1', type: AttachmentType.photo),
        ],
      );

      final updated = original.copyWith(
        content: 'updated',
        status: MessageStatus.sent,
        attachments: [
          MessageAttachment(id: 'a2', type: AttachmentType.file),
        ],
      );

      expect(updated.content, 'updated');
      expect(updated.status, MessageStatus.sent);
      expect(updated.attachments.single.id, 'a2');
      expect(original.content, 'hello');
      expect(original.attachments.single.id, 'a1');
    });
  });

  group('ChatThread', () {
    test('addMessage appends and bumps lastUpdated', () {
      final initial = ChatThread(
        id: 't1',
        spaceId: 'health',
        messages: const [],
        createdAt: DateTime(2025, 1, 1),
        lastUpdated: DateTime(2025, 1, 1),
      );

      final msg = ChatMessage(
        id: 'm1',
        threadId: 't1',
        sender: MessageSender.user,
        content: 'hi',
        timestamp: DateTime(2025, 1, 2, 12),
      );

      final updated = initial.addMessage(msg);

      expect(updated.messages, hasLength(1));
      expect(updated.lastUpdated, msg.timestamp);
      expect(initial.messages, isEmpty);
      expect(initial.lastUpdated, DateTime(2025, 1, 1));
    });
  });
}
