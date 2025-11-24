import 'package:flutter/foundation.dart';

import 'chat_message.dart';
import 'message_attachment.dart';
import 'space_context.dart';

/// DTO carrying all inputs needed to send a chat message to an AI provider.
@immutable
class ChatRequest {
  ChatRequest({
    required this.threadId,
    required this.messageContent,
    required this.spaceContext,
    List<MessageAttachment> attachments = const [],
    List<ChatMessage> messageHistory = const [],
    this.maxHistoryMessages = 3,
  })  : assert(threadId.trim().isNotEmpty, 'threadId cannot be empty'),
        assert(
          messageContent.trim().isNotEmpty || attachments.isNotEmpty,
          'Request must include text or at least one attachment.',
        ),
        assert(maxHistoryMessages > 0, 'maxHistoryMessages must be > 0'),
        attachments = List.unmodifiable(attachments),
        messageHistory = List.unmodifiable(messageHistory);

  /// Thread identifier to group related messages.
  final String threadId;

  /// Raw text content supplied by the user.
  final String messageContent;

  /// Space-aware persona and record context.
  final SpaceContext spaceContext;

  /// Attachment metadata associated with the request (no binaries).
  final List<MessageAttachment> attachments;

  /// Prior messages used for grounding (immutable snapshot).
  final List<ChatMessage> messageHistory;

  /// Maximum number of history messages to include in payloads.
  final int maxHistoryMessages;

  /// History trimmed to the configured maximum to avoid token overuse.
  List<ChatMessage> get limitedHistory =>
      messageHistory.take(maxHistoryMessages).toList(growable: false);

  /// JSON payload safe for transport (strips local-only fields).
  Map<String, dynamic> toJson() {
    return {
      'threadId': threadId,
      'message': messageContent,
      'attachments':
          attachments.map((attachment) => attachment.toMetadataJson()).toList(),
      'spaceContext': {
        'spaceId': spaceContext.spaceId,
        'spaceName': spaceContext.spaceName,
        'persona': spaceContext.persona.name,
        'recentRecords':
            spaceContext.limitedRecords.map((r) => r.toJson()).toList(),
      },
      'messageHistory': limitedHistory
          .map(
            (m) => {
              'role': m.sender == MessageSender.ai ? 'assistant' : 'user',
              'content': m.content,
            },
          )
          .toList(),
    };
  }
}
