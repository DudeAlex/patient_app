import 'dart:async';
import 'dart:io';

import 'package:patient_app/core/ai/chat/application/use_cases/send_chat_message_use_case.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/chat/repositories/chat_thread_repository.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';

import '../models/message_attachment.dart';
import '../application/use_cases/send_chat_message_use_case.dart' as chat_use_cases;

/// Queues chat messages when offline and retries them when connectivity returns.
///
/// Minimal in-memory queue; if durability is required across app restarts, add
/// persistence to storage/Isar in a follow-up.
class MessageQueueService {
  MessageQueueService({
    required SendChatMessageUseCase sendChatMessageUseCase,
    required ChatThreadRepository chatThreadRepository,
  })  : _sendChatMessageUseCase = sendChatMessageUseCase,
        _chatThreadRepository = chatThreadRepository;

  final SendChatMessageUseCase _sendChatMessageUseCase;
  final ChatThreadRepository _chatThreadRepository;

  final List<_QueuedMessage> _queue = [];
  bool _processing = false;

  /// Adds a message to the offline queue.
  Future<void> enqueue({
    required String threadId,
    required SpaceContext spaceContext,
    required String content,
    required List<MessageAttachment> attachments,
  }) async {
    final opId = AppLogger.startOperation('enqueue_chat_message');
    try {
      final inputs = attachments.map((attachment) {
        if (attachment.localPath == null) {
          throw StateError('Attachment ${attachment.id} is missing localPath');
        }
        return chat_use_cases.ChatAttachmentInput(
          file: File(attachment.localPath!),
          type: attachment.type,
        );
      }).toList(growable: false);

      _queue.add(
        _QueuedMessage(
          threadId: threadId,
          spaceContext: spaceContext,
          content: content,
          attachments: inputs,
        ),
      );

      await AppLogger.info('Queued chat message for offline send', context: {
        'threadId': threadId,
        'attachments': attachments.length,
      });
    } finally {
      await AppLogger.endOperation(opId);
    }
  }

  /// Attempts to send all queued messages sequentially.
  ///
  /// Messages that fail remain in the queue for the next retry.
  Future<void> processQueue() async {
    if (_processing || _queue.isEmpty) return;
    _processing = true;
    final opId = AppLogger.startOperation('process_chat_queue');
    try {
      // Iterate over a copy so we can remove from the original safely.
      final pending = List<_QueuedMessage>.from(_queue);
      for (final queued in pending) {
        final messageOp = AppLogger.startOperation(
          'process_chat_queue_item',
          parentId: opId,
        );
        try {
          await _sendChatMessageUseCase.execute(
            threadId: queued.threadId,
            spaceContext: queued.spaceContext,
            messageContent: queued.content,
            attachments: queued.attachments,
          );

          // Refresh thread so callers can update UI if needed.
          await _chatThreadRepository.getById(queued.threadId);

          _queue.remove(queued);
          await AppLogger.info('Queued chat message sent', context: {
            'threadId': queued.threadId,
          });
        } catch (e, stackTrace) {
          await AppLogger.error(
            'Failed to send queued chat message',
            error: e,
            stackTrace: stackTrace,
            context: {'threadId': queued.threadId},
          );
          // Leave in queue for next attempt; consider adding backoff metadata later.
        } finally {
          await AppLogger.endOperation(messageOp);
        }
      }
    } finally {
      _processing = false;
      await AppLogger.endOperation(opId);
    }
  }

  int get pendingCount => _queue.length;
}

class _QueuedMessage {
  _QueuedMessage({
    required this.threadId,
    required this.spaceContext,
    required this.content,
    required this.attachments,
  });

  final String threadId;
  final SpaceContext spaceContext;
  final String content;
  final List<chat_use_cases.ChatAttachmentInput> attachments;
}
