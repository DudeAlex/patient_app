library google_drive_backup;

export 'src/auth/auth_client.dart'
    if (dart.library.html) 'src/auth/auth_client_web.dart';
export 'src/auth/google_auth.dart'
    if (dart.library.html) 'src/auth/google_auth_web.dart';
export 'src/backup/backup_service.dart'
    if (dart.library.html) 'src/backup/backup_service_web.dart';
export 'src/backup_manager.dart';
export 'src/crypto/encryption.dart';
export 'src/crypto/key_manager.dart';
export 'src/drive/drive_sync.dart';
