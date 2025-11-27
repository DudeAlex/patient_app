import 'package:flutter/foundation.dart';

import 'chat_message.dart';
import 'context_filters.dart';
import 'message_attachment.dart';
import 'space_context.dart';
import 'token_allocation.dart';

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
    this.filters,
    this.tokenBudget,
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

  /// Optional filters applied during context assembly (Stage 4).
  final ContextFilters? filters;

  /// Optional token allocation for this request (Stage 4).
  final TokenAllocation? tokenBudget;

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
        'description': spaceContext.description,
        'categories': spaceContext.categories,
        'persona': spaceContext.persona.name,
        'recentRecords':
            spaceContext.limitedRecords.map((r) => r.toJson()).toList(),
        'maxContextRecords': spaceContext.maxContextRecords,
        if (spaceContext.filters != null) 'filters': spaceContext.filters,
        if (spaceContext.tokenAllocation != null)
          'tokenAllocation': spaceContext.tokenAllocation,
        if (spaceContext.stats != null) 'stats': spaceContext.stats,
      },
      'messageHistory': limitedHistory
          .map(
            (m) => {
              'role': m.sender == MessageSender.ai ? 'assistant' : 'user',
              'content': m.content,
            },
          )
          .toList(),
      if (filters != null) 'filters': filters!.toJson(),
      if (tokenBudget != null) 'tokenBudget': tokenBudget!.toJson(),
    };
  }
}
