import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AttachmentsStorage {
  static const _dirName = 'attachments';

  static Future<Directory> rootDir() async {
    final doc = await getApplicationDocumentsDirectory();
    final dir = Directory('${doc.path}/$_dirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}

