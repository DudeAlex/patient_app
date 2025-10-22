import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../crypto/encryption.dart';

class BackupService {
  // Creates a ZIP of the app documents directory (including Isar DB and attachments).
  static Future<Uint8List> exportZip() async {
    final doc = await getApplicationDocumentsDirectory();
    final root = Directory(doc.path);
    final archive = Archive();
    if (!await root.exists()) return Uint8List(0);

    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final rel = p.relative(entity.path, from: root.path);
        final data = await entity.readAsBytes();
        archive.addFile(ArchiveFile(rel, data.length, data));
      }
    }
    final zipData = ZipEncoder().encode(archive) ?? <int>[];
    return Uint8List.fromList(zipData);
  }

  static Future<void> importZip(Uint8List zipBytes) async {
    final doc = await getApplicationDocumentsDirectory();
    final root = Directory(doc.path);
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    final archive = ZipDecoder().decodeBytes(zipBytes);
    for (final file in archive) {
      final outPath = p.normalize(p.join(root.path, file.name));
      if (file.isFile) {
        final outFile = File(outPath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        final dir = Directory(outPath);
        await dir.create(recursive: true);
      }
    }
  }

  static Future<Uint8List> exportEncrypted(Uint8List key) async {
    final zip = await exportZip();
    return await CryptoHelper.encrypt(zip, key);
  }

  static Future<void> importEncrypted(Uint8List encrypted, Uint8List key) async {
    final zip = await CryptoHelper.decrypt(encrypted, key);
    await importZip(zip);
  }
}

