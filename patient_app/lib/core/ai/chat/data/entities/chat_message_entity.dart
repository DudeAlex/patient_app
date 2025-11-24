import 'package:isar/isar.dart';

import '../../models/chat_message.dart';
import 'message_attachment_entity.dart';

part 'chat_message_entity.g.dart';

/// Embedded message persisted inside a chat thread.
@embedded
class ChatMessageEntity {
  ChatMessageEntity({
    this.id = '',
    this.sender = MessageSender.user,
    this.timestamp,
    this.content = '',
    this.attachments = const [],
    this.status = MessageStatus.sending,
    this.actionHints = const [],
    this.tokensUsed,
    this.latencyMs,
    this.provider,
    this.confidence,
    this.errorMessage,
    this.errorCode,
    this.errorRetryable,
  });

  /// Stable message id (matches domain model).
  String id;

  /// Sender role to support persona styling.
  @Enumerated(EnumType.name)
  MessageSender sender;

  /// Message body (may be empty for attachment-only sends).
  String content;

  /// UTC timestamp for ordering.
  DateTime? timestamp;

  /// Metadata-only attachments.
  List<MessageAttachmentEntity> attachments;

  /// Delivery status for rendering retries/errors.
  @Enumerated(EnumType.name)
  MessageStatus status;

  /// AI-suggested action hints (metadata only).
  List<String> actionHints;

  /// Provider metrics for diagnostics.
  int? tokensUsed;
  int? latencyMs;
  String? provider;
  double? confidence;

  /// Captured error context (safe to show in UI).
  String? errorMessage;
  String? errorCode;
  bool? errorRetryable;
}
