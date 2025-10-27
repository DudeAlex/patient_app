import 'dart:typed_data';

/// Web stub: browsers cannot access the app documents directory.
class BackupService {
  static Future<Uint8List> exportZip() async =>
      throw UnsupportedError('Backup not supported on web');
  static Future<void> importZip(Uint8List bytes) async =>
      throw UnsupportedError('Restore not supported on web');
  static Future<Uint8List> exportEncrypted(Uint8List key) async =>
      throw UnsupportedError('Backup not supported on web');
  static Future<void> importEncrypted(Uint8List encrypted, Uint8List key) async =>
      throw UnsupportedError('Restore not supported on web');
}
