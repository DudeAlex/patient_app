import 'dart:io';

import '../../../../core/storage/attachments.dart';
import '../../application/ports/capture_artifact_storage.dart';

/// Adapter that routes capture artifact storage calls to [AttachmentsStorage].
class AttachmentsCaptureArtifactStorage implements CaptureArtifactStorage {
  const AttachmentsCaptureArtifactStorage();

  @override
  Future<String> allocateRelativePath({
    required String sessionId,
    required String fileName,
  }) {
    return AttachmentsStorage.allocateRelativePath(
      sessionId: sessionId,
      fileName: fileName,
    );
  }

  @override
  Future<Directory> rootDir() => AttachmentsStorage.rootDir();

  @override
  Future<File> resolveRelativePath(String relativePath) {
    return AttachmentsStorage.resolveRelativePath(relativePath);
  }

  @override
  Future<void> deleteRelativeFile(String relativePath) {
    return AttachmentsStorage.deleteRelativeFile(relativePath);
  }
}
