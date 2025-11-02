import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AttachmentsStorage {
  static const _dirName = 'attachments';
  static const _sessionsDir = 'sessions';

  static Future<Directory> rootDir() async {
    final doc = await getApplicationDocumentsDirectory();
    final dir = Directory('${doc.path}/$_dirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Temporary directory for the given capture session.
  static Future<Directory> sessionDir(String sessionId) async {
    final root = await rootDir();
    final dir = Directory('${root.path}/$_sessionsDir/$sessionId');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Resolves an absolute [File] from a previously stored relative path.
  static Future<File> resolveRelativePath(String relativePath) async {
    final root = await rootDir();
    return File('${root.path}/$relativePath');
  }

  /// Generates a relative path under the attachments directory using the
  /// provided session id and filename.
  static Future<String> allocateRelativePath({
    required String sessionId,
    required String fileName,
  }) async {
    final root = await rootDir();
    final relative = '$_sessionsDir/$sessionId/$fileName';
    final target = File('${root.path}/$relative');
    await target.parent.create(recursive: true);
    return relative;
  }

  /// Deletes all temporary files for a capture session.
  static Future<void> deleteSession(String sessionId) async {
    final dir = await sessionDir(sessionId);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
