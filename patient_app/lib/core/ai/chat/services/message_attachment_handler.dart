import 'dart:io';

import 'package:patient_app/core/ai/chat/models/message_attachment.dart';

/// Service responsible for managing chat message attachments.
///
/// Handles saving files to local storage, generating metadata, and cleaning up
/// files when they are no longer needed.
abstract class MessageAttachmentHandler {
  /// Processes a file from a temporary path and moves/copies it to permanent storage.
  ///
  /// [sourceFile] The file to process.
  /// [type] The type of attachment (photo, voice, file).
  /// [targetThreadId] The ID of the thread this attachment belongs to (for organization).
  ///
  /// Returns a [MessageAttachment] with the local path and metadata populated.
  Future<MessageAttachment> processAttachment({
    required File sourceFile,
    required AttachmentType type,
    required String targetThreadId,
  });

  /// Deletes the physical file associated with an attachment.
  ///
  /// [attachment] The attachment to delete.
  Future<void> deleteAttachment(MessageAttachment attachment);

  /// Validates if a file is suitable for attachment (size limits, allowed types).
  ///
  /// Throws an exception if validation fails.
  Future<void> validateAttachment(File file, AttachmentType type);
}
