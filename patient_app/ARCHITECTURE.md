# Architecture

Overview
- Local-first app with Isar for structured data and file storage for attachments (mobile)
- Optional encrypted backup to Google Drive App Data (mobile)
- Web build runs with IndexedDB-backed Isar; backup disabled by default

Key Modules
- `lib/ui/` app shell and screens
  - `ui/app.dart` Material app + Settings entry
  - `ui/settings/settings_screen.dart` wires UI to the reusable backup manager
- `lib/core/`
  - `core/db/isar.dart` open Isar with schemas
  - `core/storage/attachments.dart` manage attachments directory
- `packages/google_drive_backup/`
  - `auth/` Google Sign-In wrapper + injected HTTP client (v7 API)
  - `crypto/` AES-GCM helpers + secure key management
  - `backup/` zip/encrypt/export + decrypt/unzip/import (with web stubs)
  - `drive/` Drive API upload/download in appData
  - `backup_manager.dart` orchestrates auth, encryption, and Drive sync for consumers
- `lib/features/records/`
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
