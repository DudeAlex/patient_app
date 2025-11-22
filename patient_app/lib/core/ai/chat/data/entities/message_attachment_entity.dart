import 'package:isar/isar.dart';

import '../../models/message_attachment.dart';

part 'message_attachment_entity.g.dart';

/// Embedded attachment metadata stored with a chat message.
@embedded
class MessageAttachmentEntity {
  MessageAttachmentEntity({
    this.id = '',
    this.type = AttachmentType.photo,
    this.localPath,
    this.fileName,
    this.fileSizeBytes,
    this.mimeType,
    this.transcription,
  });

  /// Stable attachment id (matches domain model).
  String id;

  /// Attachment type for rendering and processing.
  @Enumerated(EnumType.name)
  AttachmentType type;

  /// Local-only path to persisted file (never sent off-device).
  String? localPath;

  String? fileName;

  int? fileSizeBytes;

  String? mimeType;

  /// Transcription for voice notes, when available.
  String? transcription;
}
