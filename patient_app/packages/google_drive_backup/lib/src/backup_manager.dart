import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'auth/auth_client.dart'
    if (dart.library.html) 'auth/auth_client_web.dart';
import 'auth/google_auth.dart'
    if (dart.library.html) 'auth/google_auth_web.dart';
import 'backup/backup_service.dart'
    if (dart.library.html) 'backup/backup_service_web.dart';
import 'crypto/key_manager.dart';
import 'drive/drive_sync.dart';

/// Convenience wrapper that wires auth, key management, local encryption, and
/// Drive upload/download into a single object suitable for UI layers.
class DriveBackupManager {
  DriveBackupManager({GoogleAuthService? auth})
      : auth = auth ?? GoogleAuthService();

  final GoogleAuthService auth;

  Future<String?> restoreAccount() => auth.tryGetEmail();

  Future<Uint8List> _ensureEncryptedExport() async {
    final key = await KeyManager.getOrCreateKey();
    return await BackupService.exportEncrypted(key);
  }

  Future<void> backupToDrive({bool promptIfNecessary = true}) async {
    final encrypted = await _ensureEncryptedExport();
    final headersProvider = () =>
        auth.getAuthHeaders(promptIfNecessary: promptIfNecessary);
    final client = GoogleAuthClient(headersProvider, http.Client());
    try {
      final drive = DriveSyncService(client);
      await drive.uploadEncrypted(encrypted);
    } finally {
      client.close();
    }
  }

  Future<void> restoreFromDrive({bool promptIfNecessary = true}) async {
    final headersProvider = () =>
        auth.getAuthHeaders(promptIfNecessary: promptIfNecessary);
    final client = GoogleAuthClient(headersProvider, http.Client());
    try {
      final drive = DriveSyncService(client);
      final bytes = await drive.downloadEncrypted();
      if (bytes == null) {
        throw StateError('No backup found in Google Drive App Data');
      }
      final key = await KeyManager.getOrCreateKey();
      await BackupService.importEncrypted(bytes, key);
    } finally {
      client.close();
    }
  }
}
