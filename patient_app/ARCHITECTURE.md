# Architecture

Overview
- Local-first app with Isar for structured data and file storage for attachments (mobile)
- Optional encrypted backup to Google Drive App Data (mobile)
- Web build runs with IndexedDB-backed Isar; backup disabled by default

Key Modules (lib/)
- `ui/` app shell and screens
  - `ui/app.dart` Material app + Settings entry
  - `ui/settings/settings_screen.dart` Google sign-in + backup/restore UI
- `core/`
  - `core/db/isar.dart` open Isar with schemas
  - `core/crypto/encryption.dart` AES-GCM helpers (PBKDF2, encrypt/decrypt)
  - `core/crypto/key_manager.dart` secure 32-byte key using flutter_secure_storage
  - `core/auth/google_auth.dart` Google Sign-In v7 API usage
  - `core/auth/auth_client.dart` HTTP client that injects OAuth headers
  - `core/sync/drive_sync.dart` Drive API upload/download in appData
  - `core/backup/backup_service.dart` zip+encrypt/export, decrypt+unzip/import
  - `core/backup/backup_service_web.dart` web stub
- `features/records/`
  - `model/record.dart`, `attachment.dart`, `insight.dart`, `sync_state.dart`
  - `repo/records_repo.dart`

Data Model (Isar)
- Record: id, type, date, title, text?, tags[], createdAt, updatedAt, deletedAt?
- Attachment: id, recordId, path, kind, ocrText?, createdAt
- Insight: id, recordId?, kind, text, createdAt
- SyncState (singleton): lastSyncedAt?, lastRemoteModified?, localChangeCounter, deviceId

Security
- Backup encryption: AES-GCM with random nonce; key stored in platform secure storage
- No data leaves device unencrypted for backups

Platform Behavior
- Android/iOS: full backup/restore via Drive appData (`patient-backup-v1.enc`)
- Web: no backup (stub), app runs with UI and IndexedDB-backed Isar

