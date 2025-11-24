import 'dart:io';

import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/chat/models/chat_thread.dart';
import 'package:patient_app/core/ai/chat/repositories/chat_thread_repository.dart';
import 'package:patient_app/core/ai/chat/services/message_attachment_handler.dart';
import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';
import 'package:patient_app/core/ai/repositories/ai_consent_repository.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:uuid/uuid.dart';

/// Use case that sends a chat message, handling consent, attachment processing,
/// persistence, and AI response storage.
class SendChatMessageUseCase {
  SendChatMessageUseCase({
    required AiChatService aiChatService,
    required ChatThreadRepository chatThreadRepository,
    required AiConsentRepository consentRepository,
    required MessageAttachmentHandler attachmentHandler,
    Uuid? uuid,
  })  : _aiChatService = aiChatService,
        _chatThreadRepository = chatThreadRepository,
        _consentRepository = consentRepository,
        _attachmentHandler = attachmentHandler,
        _uuid = uuid ?? const Uuid();

  final AiChatService _aiChatService;
  final ChatThreadRepository _chatThreadRepository;
  final AiConsentRepository _consentRepository;
  final MessageAttachmentHandler _attachmentHandler;
  final Uuid _uuid;

  /// Sends a message and returns the AI-generated response message.
  ///
  /// Throws [AiConsentRequiredException] if consent is missing and propagates
  /// AI provider failures after marking the user message as failed.
  Future<ChatMessage> execute({
    required String threadId,
    required SpaceContext spaceContext,
    required String messageContent,
    List<ChatAttachmentInput> attachments = const [],
    int maxHistoryMessages = 10,
  }) async {
    if (messageContent.trim().isEmpty && attachments.isEmpty) {
      throw ArgumentError('Message must include text or at least one attachment.');
    }

    final hasConsent = await _consentRepository.hasConsent();
    if (!hasConsent) {
      throw AiConsentRequiredException();
    }

    final opId = AppLogger.startOperation('send_chat_message');
    try {
      // Ensure thread exists.
      final existingThread = await _chatThreadRepository.getById(threadId);
      final thread = existingThread ??
          ChatThread(
            id: threadId,
            spaceId: spaceContext.spaceId,
            messages: const [],
          );
      if (existingThread == null) {
        await _chatThreadRepository.saveThread(thread);
      }

      // Process attachments.
      final processedAttachments = <MessageAttachment>[];
      for (final input in attachments) {
        final processed = await _attachmentHandler.processAttachment(
          sourceFile: input.file,
          type: input.type,
          targetThreadId: threadId,
        );
        processedAttachments.add(processed);
      }

      // Persist user message as sending.
      final userMessage = ChatMessage(
        id: _uuid.v4(),
        threadId: threadId,
        sender: MessageSender.user,
        content: messageContent,
        attachments: processedAttachments,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
      );
      await _chatThreadRepository.addMessage(threadId, userMessage);

      // Build request with limited history including the new message.
      final history = <ChatMessage>[
        ...thread.messages,
        userMessage,
      ];
      final request = ChatRequest(
        threadId: threadId,
        messageContent: messageContent,
        attachments: processedAttachments,
        spaceContext: spaceContext,
        messageHistory: history,
        maxHistoryMessages: maxHistoryMessages,
      );

      final ChatResponse response;
      try {
        response = await _aiChatService.sendMessage(request);
      } on AiServiceException catch (e) {
        await _chatThreadRepository.updateMessageStatus(
          threadId,
          userMessage.id,
          MessageStatus.failed,
          errorMessage: e.error?.message ?? e.message,
          errorCode: e.error?.code,
          errorRetryable: e.error?.isRetryable,
        );
        rethrow;
      } catch (e) {
        await _chatThreadRepository.updateMessageStatus(
          threadId,
          userMessage.id,
          MessageStatus.failed,
          errorMessage: e.toString(),
          errorRetryable: false,
        );
        rethrow;
      }
      if (!response.isSuccess) {
        await _chatThreadRepository.updateMessageStatus(
          threadId,
          userMessage.id,
          MessageStatus.failed,
          errorMessage: response.error?.message,
          errorCode: response.error?.code,
          errorRetryable: response.error?.isRetryable,
        );
        throw AiServiceException(
          response.error?.message ?? 'AI response contained an error',
          error: response.error,
        );
      }

      // Mark user message sent and append AI response.
      await _chatThreadRepository.updateMessageStatus(
        threadId,
        userMessage.id,
        MessageStatus.sent,
      );

      final aiMessage = ChatMessage(
        id: _uuid.v4(),
        threadId: threadId,
        sender: MessageSender.ai,
        content: response.messageContent,
        attachments: const [],
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        actionHints: response.actionHints,
        aiMetadata: response.metadata,
        error: response.error,
      );
      await _chatThreadRepository.addMessage(threadId, aiMessage);

      await AppLogger.info(
        'Chat message sent successfully',
        context: {
          'threadId': threadId,
          'spaceId': spaceContext.spaceId,
          'attachmentCount': processedAttachments.length,
          'provider': response.metadata.provider,
        },
        correlationId: opId,
      );

      return aiMessage;
    } catch (e, stackTrace) {
      await AppLogger.error(
        'Chat message send failed',
        error: e,
        stackTrace: stackTrace,
        context: {'threadId': threadId, 'spaceId': spaceContext.spaceId},
        correlationId: opId,
      );
      rethrow;
    } finally {
      await AppLogger.endOperation(opId);
    }
  }
}

/// Simple attachment input used to capture source file + type for processing.
class ChatAttachmentInput {
  ChatAttachmentInput({required this.file, required this.type});

  final File file;
  final AttachmentType type;
}
