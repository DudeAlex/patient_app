import 'package:flutter/foundation.dart';

import 'chat_message.dart';

/// Aggregate representing a conversation scoped to a Space (and optionally a record).
@immutable
class ChatThread {
  ChatThread({
    required this.id,
    required this.spaceId,
    this.recordId,
    List<ChatMessage> messages = const [],
    DateTime? createdAt,
    DateTime? lastUpdated,
  })  : assert(id.trim().isNotEmpty, 'Thread id cannot be empty'),
        assert(spaceId.trim().isNotEmpty, 'spaceId cannot be empty'),
        messages = List.unmodifiable(messages),
        createdAt = createdAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? DateTime.now();

  /// Unique identifier for the thread.
  final String id;

  /// Space identifier used to scope persona/context.
  final String spaceId;

  /// Optional record identifier if the chat is tied to a specific item.
  final String? recordId;

  /// Immutable snapshot of messages in this thread.
  final List<ChatMessage> messages;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime lastUpdated;

  bool get isEmpty => messages.isEmpty;

  /// Returns a new thread with the appended message and updated timestamp.
  ChatThread addMessage(ChatMessage message) {
    final updatedMessages = List<ChatMessage>.from(messages)..add(message);
    return copyWith(
      messages: updatedMessages,
      lastUpdated: message.timestamp,
    );
  }

  /// Creates a copy with selective overrides.
  ChatThread copyWith({
    String? id,
    String? spaceId,
    String? recordId,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return ChatThread(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      recordId: recordId ?? this.recordId,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
