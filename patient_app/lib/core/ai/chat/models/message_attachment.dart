import 'package:flutter/foundation.dart';

/// Metadata for an attachment associated with a chat message.
///
/// Binary payloads and local paths should never be sent off-device; use
/// [toMetadataJson] when building network payloads to strip local-only fields.
@immutable
class MessageAttachment {
  MessageAttachment({
    required this.id,
    required this.type,
    this.localPath,
    this.fileName,
    this.fileSizeBytes,
    this.mimeType,
    this.transcription,
  })  : assert(id.trim().isNotEmpty, 'Attachment id cannot be empty'),
        assert(
          fileSizeBytes == null || fileSizeBytes >= 0,
          'fileSizeBytes cannot be negative',
        );

  /// Stable identifier for the attachment.
  final String id;

  /// Attachment classification (photo, voice, file).
  final AttachmentType type;

  /// Local path to the stored attachment (never transmitted to providers).
  final String? localPath;

  /// Optional human-friendly name (e.g., filename).
  final String? fileName;

  /// File size in bytes, when known.
  final int? fileSizeBytes;

  /// MIME type (e.g., image/jpeg, audio/mpeg).
  final String? mimeType;

  /// Transcribed text for voice notes, when available.
  final String? transcription;

  /// Returns a new attachment with updated fields.
  MessageAttachment copyWith({
    String? id,
    AttachmentType? type,
    String? localPath,
    String? fileName,
    int? fileSizeBytes,
    String? mimeType,
    String? transcription,
  }) {
    return MessageAttachment(
      id: id ?? this.id,
      type: type ?? this.type,
      localPath: localPath ?? this.localPath,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      transcription: transcription ?? this.transcription,
    );
  }

  /// JSON-safe metadata (excludes local paths and binary content).
  Map<String, dynamic> toMetadataJson() {
    return {
      'id': id,
      'type': type.name,
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
      'mimeType': mimeType,
      'transcription': transcription,
    };
  }
}

/// Supported attachment types for chat messages.
enum AttachmentType { photo, voice, file }
