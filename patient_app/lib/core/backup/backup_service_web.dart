// Web stub: Browser sandbox prevents filesystem-wide zipping.
// These methods throw to indicate backup/restore is not supported on web.

import 'dart:typed_data';

class BackupService {
  static Future<Uint8List> exportZip() async => throw UnsupportedError('Backup not supported on web');
  static Future<void> importZip(Uint8List bytes) async => throw UnsupportedError('Restore not supported on web');
  static Future<Uint8List> exportEncrypted(Uint8List key) async => throw UnsupportedError('Backup not supported on web');
  static Future<void> importEncrypted(Uint8List encrypted, Uint8List key) async => throw UnsupportedError('Restore not supported on web');
}
