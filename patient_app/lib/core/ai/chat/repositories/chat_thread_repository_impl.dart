import 'package:isar/isar.dart';

import 'package:patient_app/core/ai/chat/data/entities/chat_message_entity.dart';
import 'package:patient_app/core/ai/chat/data/entities/chat_thread_entity.dart';
import 'package:patient_app/core/ai/chat/data/entities/message_attachment_entity.dart';
import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/models/chat_thread.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';
import 'package:patient_app/core/ai/models/ai_error.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'chat_thread_repository.dart';

class ChatThreadRepositoryImpl implements ChatThreadRepository {
  final Isar _isar;

  ChatThreadRepositoryImpl(this._isar);

  @override
  Future<ChatThread?> getById(String threadId) async {
    final entity = await _isar.chatThreadEntitys.getByThreadId(threadId);
    return entity?.toDomain();
  }

  @override
  Future<List<ChatThread>> getBySpaceId(
    String spaceId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final entities = await _isar.chatThreadEntitys
        .where()
        .spaceIdEqualTo(spaceId)
        .sortByUpdatedAtDesc()
        .offset(offset)
        .limit(limit)
        .findAll();

    return entities.map((e) => e.toDomain()).toList();
  }

  @override
  Future<void> saveThread(ChatThread thread) async {
    final entity = thread.toEntity();
    await _isar.writeTxn(() async {
      await _isar.chatThreadEntitys.putByThreadId(entity);
    });
    await AppLogger.info(
      'Saved chat thread',
      context: {'threadId': thread.id, 'spaceId': thread.spaceId},
    );
  }

  @override
  Future<void> deleteThread(String threadId) async {
    await _isar.writeTxn(() async {
      await _isar.chatThreadEntitys.deleteByThreadId(threadId);
    });
    await AppLogger.info(
      'Deleted chat thread',
      context: {'threadId': threadId},
    );
  }

  @override
  Future<void> addMessage(String threadId, ChatMessage message) async {
    await _isar.writeTxn(() async {
      final thread = await _isar.chatThreadEntitys.getByThreadId(threadId);
      if (thread != null) {
        final updatedMessages = List<ChatMessageEntity>.from(thread.messages)
          ..add(message.toEntity());
        
        thread.messages = updatedMessages;
        thread.updatedAt = DateTime.now();
        
        await _isar.chatThreadEntitys.putByThreadId(thread);
        await AppLogger.info(
          'Added chat message',
          context: {
            'threadId': threadId,
            'messageId': message.id,
            'sender': message.sender.name,
          },
        );
      } else {
        await AppLogger.error(
          'Chat thread not found when adding message',
          context: {'threadId': threadId, 'messageId': message.id},
        );
      }
    });
  }

  @override
  Future<void> updateMessageStatus(
    String threadId,
    String messageId,
    MessageStatus status, {
    String? errorMessage,
    String? errorCode,
    bool? errorRetryable,
  }) async {
    await _isar.writeTxn(() async {
      final thread = await _isar.chatThreadEntitys.getByThreadId(threadId);
      if (thread != null) {
        final updatedMessages = thread.messages.map((msg) {
          if (msg.id == messageId) {
            msg.status = status;
            if (errorMessage != null) msg.errorMessage = errorMessage;
            if (errorCode != null) msg.errorCode = errorCode;
            if (errorRetryable != null) msg.errorRetryable = errorRetryable;
          }
          return msg;
        }).toList();

        thread.messages = updatedMessages;
        thread.updatedAt = DateTime.now();
        
        await _isar.chatThreadEntitys.putByThreadId(thread);
        await AppLogger.info(
          'Updated chat message status',
          context: {
            'threadId': threadId,
            'messageId': messageId,
            'status': status.name,
            if (errorCode != null) 'errorCode': errorCode,
            if (errorRetryable != null) 'retryable': errorRetryable,
          },
        );
      } else {
        await AppLogger.error(
          'Chat thread not found when updating message status',
          context: {'threadId': threadId, 'messageId': messageId},
        );
      }
    });
  }

  @override
  Future<void> updateMessageContent(
    String threadId,
    String messageId,
    String content,
  ) async {
    await _isar.writeTxn(() async {
      final thread = await _isar.chatThreadEntitys.getByThreadId(threadId);
      if (thread != null) {
        final updatedMessages = thread.messages.map((msg) {
          if (msg.id == messageId) {
            msg.content = content;
          }
          return msg;
        }).toList();

        thread.messages = updatedMessages;
        thread.updatedAt = DateTime.now();
        
        await _isar.chatThreadEntitys.putByThreadId(thread);
        await AppLogger.debug(
          'Updated chat message content',
          context: {'threadId': threadId, 'messageId': messageId},
        );
      } else {
        await AppLogger.error(
          'Chat thread not found when updating message content',
          context: {'threadId': threadId, 'messageId': messageId},
        );
      }
    });
  }

  @override
  Future<void> updateMessageMetrics(
    String threadId,
    String messageId, {
    int? tokensUsed,
    int? latencyMs,
  }) async {
    await _isar.writeTxn(() async {
      final thread = await _isar.chatThreadEntitys.getByThreadId(threadId);
      if (thread != null) {
        final updatedMessages = thread.messages.map((msg) {
          if (msg.id == messageId) {
            if (tokensUsed != null) msg.tokensUsed = tokensUsed;
            if (latencyMs != null) msg.latencyMs = latencyMs;
          }
          return msg;
        }).toList();

        thread.messages = updatedMessages;
        thread.updatedAt = DateTime.now();
        
        await _isar.chatThreadEntitys.putByThreadId(thread);
        await AppLogger.debug(
          'Updated chat message metrics',
          context: {
            'threadId': threadId,
            'messageId': messageId,
            if (tokensUsed != null) 'tokensUsed': tokensUsed,
            if (latencyMs != null) 'latencyMs': latencyMs,
          },
        );
      } else {
        await AppLogger.error(
          'Chat thread not found when updating message metrics',
          context: {'threadId': threadId, 'messageId': messageId},
        );
      }
    });
  }
}

// Mappers

extension ChatThreadMapper on ChatThreadEntity {
  ChatThread toDomain() {
    return ChatThread(
      id: threadId,
      spaceId: spaceId,
      recordId: recordId,
      createdAt: createdAt,
      lastUpdated: updatedAt,
      messages: messages.map((e) => e.toDomain(threadId)).toList(),
    );
  }
}

extension ChatThreadDomainMapper on ChatThread {
  ChatThreadEntity toEntity() {
    return ChatThreadEntity(
      threadId: id,
      spaceId: spaceId,
      recordId: recordId,
      createdAt: createdAt,
      updatedAt: lastUpdated,
      messages: messages.map((e) => e.toEntity()).toList(),
    );
  }
}

extension ChatMessageMapper on ChatMessageEntity {
  ChatMessage toDomain(String threadId) {
    return ChatMessage(
      id: id,
      threadId: threadId,
      sender: sender,
      timestamp: timestamp ?? DateTime.fromMillisecondsSinceEpoch(0),
      content: content,
      attachments: attachments.map((e) => e.toDomain()).toList(),
      status: status,
      actionHints: actionHints,
      aiMetadata: AiMessageMetadata(
        tokensUsed: tokensUsed ?? 0,
        latencyMs: latencyMs ?? 0,
        provider: provider ?? 'unknown',
        confidence: confidence ?? 0.0,
      ),
      error: errorMessage != null
          ? AiError(
              message: errorMessage!,
              isRetryable: errorRetryable ?? false,
              code: errorCode,
            )
          : null,
    );
  }
}

extension ChatMessageDomainMapper on ChatMessage {
  ChatMessageEntity toEntity() {
    return ChatMessageEntity(
      id: id,
      sender: sender,
      timestamp: timestamp,
      content: content,
      attachments: attachments.map((e) => e.toEntity()).toList(),
      status: status,
      actionHints: actionHints,
      tokensUsed: aiMetadata?.tokensUsed,
      latencyMs: aiMetadata?.latencyMs,
      provider: aiMetadata?.provider,
      confidence: aiMetadata?.confidence,
      errorMessage: error?.message,
      errorCode: error?.code,
      errorRetryable: error?.isRetryable,
    );
  }
}

extension MessageAttachmentMapper on MessageAttachmentEntity {
  MessageAttachment toDomain() {
    return MessageAttachment(
      id: id,
      type: type,
      localPath: localPath,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      mimeType: mimeType,
      transcription: transcription,
    );
  }
}

extension MessageAttachmentDomainMapper on MessageAttachment {
  MessageAttachmentEntity toEntity() {
    return MessageAttachmentEntity(
      id: id,
      type: type,
      localPath: localPath,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      mimeType: mimeType,
      transcription: transcription,
    );
  }
}
