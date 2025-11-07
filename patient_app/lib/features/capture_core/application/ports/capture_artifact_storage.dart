import 'dart:io';

/// Abstraction over the attachments filesystem so capture modes can remain
/// storage-agnostic and easier to test.
abstract class CaptureArtifactStorage {
  Future<String> allocateRelativePath({
    required String sessionId,
    required String fileName,
  });

  Future<File> resolveRelativePath(String relativePath);

  Future<Directory> rootDir();

  Future<void> deleteRelativeFile(String relativePath);
}
