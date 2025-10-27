# Google Drive Backup (Flutter)

Helpers that make it easy for a Flutter app to:

- authenticate with Google Sign-In v7 (Android/web)
- encrypt the app documents directory using AES-GCM
- upload/download the encrypted archive to Google Drive App Data

## Usage

1. Add the package as a dependency (path or git for now):

```yaml
dependencies:
  google_drive_backup:
    path: ../packages/google_drive_backup
```

2. Pass your OAuth client ids when running the app:

```bash
flutter run -d emulator-5554 \
  --dart-define=GOOGLE_ANDROID_SERVER_CLIENT_ID=<WEB_CLIENT_ID>
```

3. Use `DriveBackupManager` in your UI layer:

```dart
final manager = DriveBackupManager();
final email = await manager.restoreAccount();
await manager.backupToDrive();
await manager.restoreFromDrive();
```

The manager exposes the underlying building blocks if you want more control:

- `GoogleAuthService` (sign-in, diagnostics, cached email)
- `BackupService` (zip/encrypt the documents directory)
- `DriveSyncService` (upload/download)
- `KeyManager` (persist the AES key in secure storage)

## Example

See `example/` for a minimal Flutter app that signs in and triggers backup/restore.
