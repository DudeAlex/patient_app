import 'package:flutter/foundation.dart';

import '../../models/ai_error.dart';
import 'chat_response.dart';
import 'message_attachment.dart';

/// Immutable chat message stored per thread.
///
/// Validation enforces that each message has either text content or at least
/// one attachment so we never persist empty entries.
@immutable
class ChatMessage {
  ChatMessage({
    required this.id,
    required this.threadId,
    required this.sender,
    required this.content,
    required this.timestamp,
    List<MessageAttachment> attachments = const [],
    this.status = MessageStatus.sending,
    List<String> actionHints = const [],
    this.aiMetadata,
    this.error,
    this.feedback,
    this.feedbackTimestamp,
  })  : assert(id.trim().isNotEmpty, 'id cannot be empty'),
        assert(threadId.trim().isNotEmpty, 'threadId cannot be empty'),
        assert(
          content.trim().isNotEmpty || attachments.isNotEmpty,
          'Message must include text or at least one attachment.',
        ),
        attachments = List.unmodifiable(attachments),
        actionHints = List.unmodifiable(actionHints);

  /// Unique message identifier.
  final String id;

  /// Owning thread identifier.
  final String threadId;

  /// Sender of the message (user vs AI).
  final MessageSender sender;

  /// Text content. May be empty when sending attachments only.
  final String content;

  /// Timestamp for ordering and display.
  final DateTime timestamp;

  /// Attachments associated with this message (metadata only).
  final List<MessageAttachment> attachments;

  /// Current delivery status.
  final MessageStatus status;

  /// Optional action hints returned by the AI for follow-ups.
  final List<String> actionHints;

  /// Provider metadata for AI-generated messages.
  final AiMessageMetadata? aiMetadata;

  /// Error context for failed sends/responses.
  final AiError? error;

  /// User feedback for AI responses (thumbs up/down).
  final MessageFeedback? feedback;

  /// Timestamp when feedback was provided.
  final DateTime? feedbackTimestamp;

  bool get hasAttachments => attachments.isNotEmpty;
  bool get isUserMessage => sender == MessageSender.user;
  bool get isAiMessage => sender == MessageSender.ai;
  bool get isFailed => status == MessageStatus.failed;
  bool get hasFeedback => feedback != null;

  ChatMessage copyWith({
    String? id,
    String? threadId,
    MessageSender? sender,
    String? content,
    DateTime? timestamp,
    List<MessageAttachment>? attachments,
    MessageStatus? status,
    List<String>? actionHints,
    AiMessageMetadata? aiMetadata,
    AiError? error,
    MessageFeedback? feedback,
    DateTime? feedbackTimestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      attachments: attachments ?? this.attachments,
      status: status ?? this.status,
      actionHints: actionHints ?? this.actionHints,
      aiMetadata: aiMetadata ?? this.aiMetadata,
      error: error ?? this.error,
      feedback: feedback ?? this.feedback,
      feedbackTimestamp: feedbackTimestamp ?? this.feedbackTimestamp,
    );
  }
}

/// Sender roles in a chat thread.
enum MessageSender { user, ai }

/// Delivery status for messages.
enum MessageStatus { sending, sent, failed }

/// User feedback rating for AI messages.
enum MessageFeedback {
  positive, // Thumbs up
  negative, // Thumbs down
}
