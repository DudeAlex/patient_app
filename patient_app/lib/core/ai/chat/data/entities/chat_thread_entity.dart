import 'package:isar/isar.dart';

import 'chat_message_entity.dart';

part 'chat_thread_entity.g.dart';

/// Isar collection storing chat threads scoped to a Space (and optional record).
@collection
class ChatThreadEntity {
  ChatThreadEntity({
    this.id = Isar.autoIncrement,
    required this.threadId,
    required this.spaceId,
    this.recordId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessageEntity>? messages,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        messages = messages ?? [];

  Id id;

  /// Stable thread identifier used across devices/backups.
  @Index(unique: true, replace: true)
  String threadId;

  /// Space scope for persona/context filtering.
  @Index()
  String spaceId;

  /// Optional record association for record-scoped chats.
  String? recordId;

  DateTime createdAt;

  DateTime updatedAt;

  List<ChatMessageEntity> messages;
}
