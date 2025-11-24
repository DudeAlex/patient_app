import 'package:patient_app/core/ai/chat/repositories/chat_thread_repository.dart';
import 'package:patient_app/core/ai/chat/services/message_attachment_handler.dart';

/// Use case to delete a chat thread and clean up associated attachments.
class ClearChatThreadUseCase {
  ClearChatThreadUseCase({
    required ChatThreadRepository chatThreadRepository,
    required MessageAttachmentHandler attachmentHandler,
  })  : _chatThreadRepository = chatThreadRepository,
        _attachmentHandler = attachmentHandler;

  final ChatThreadRepository _chatThreadRepository;
  final MessageAttachmentHandler _attachmentHandler;

  Future<void> execute(String threadId) async {
    final thread = await _chatThreadRepository.getById(threadId);
    if (thread != null) {
      for (final message in thread.messages) {
        for (final attachment in message.attachments) {
          await _attachmentHandler.deleteAttachment(attachment);
        }
      }
    }
    await _chatThreadRepository.deleteThread(threadId);
  }
}
