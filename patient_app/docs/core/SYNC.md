Status: ACTIVE

# Sync & Backup

## Goal
- Zero-server backup to Drive App Data; privacy-first defaults; AI assistance remains opt-in.

## Mobile Backup (v1)
- File: `patient-backup-v1.enc`; content: ZIP of docs dir (Isar + attachments + chat data); AES-GCM with 12B nonce; key from `flutter_secure_storage`.

## Operations
- Backup: zip -> encrypt -> upload (create/update).
- Restore: download -> decrypt -> unzip replace.
- Assets included: photos, scans, uploads, email attachments, audio, chat artefacts.

## Auto Sync Behavior
- Toggle in Settings; presets: 6h/12h/daily/weekly/manual (manual disables auto).
- Runs only on Wi-Fi/ethernet; weekly default; resume triggers when cadence elapsed + pending changes + signed in.
- Backoff on failures (start ~5m, cap ~2h); log next retry.
- Manual backup always available; toggle off stops auto runs.
- Production blocker: key portability (passphrase/QR/platform key backup).

## Implementation (Phase 2)
- Domain: `AutoSyncStatus` enforces counters/device id.
- Application: use cases (`SetAutoSyncEnabled`, `RecordAutoSyncChange`, `MarkAutoSyncSuccess`, `PromoteRoutineChanges`, `Read/WatchAutoSyncStatus`).
- Adapters: `IsarSyncStateRepository` for `SyncState`.
- Framework: `AutoSyncDirtyTracker` classifies mutations -> use case; `AutoSyncCoordinator` subscribes to watch/promotion; `AutoSyncRunner` calls `AutoSyncBackupService` then marks success; Settings uses read/toggle use cases.

## Auth
- Google Sign-In v7: `initialize`, `authenticate`, `authorizationHeaders` with Drive appData scope.
- Android requires Web OAuth client id via `--dart-define=GOOGLE_ANDROID_SERVER_CLIENT_ID=...`; use Google Play AVD with signed-in account.
- Settings -> Run Auth Diagnostics for safe header checks.

## Conflict Policy
- MVP: manual operations; future auto-sync may use Drive `modifiedTime` vs `SyncState` (LWW).

## Web
- Backup/restore stubbed and hidden; future optional JSON export/import with distinct filename.

## AI Queue (Planned)
- `AiProcessingService` stores tasks in Isar (photo/scan/voice/keyboard/file/email/vitals); included in backup.
- Online + consent: send to Together AI; persist responses/confidence/prompts; retries on failure; originals untouched.
- Email tasks keep headers/message ids/labels; vitals retain raw traces locally for AI annotations.

## Consent & Privacy
- Local-only mode never sends PHI.
- AI-assisted mode: explicit toggle + per-request notices; secure API key storage/proxy; redact logs (request id/duration/error only).
- Email import minimal scopes; audit via headers; vitals remind informational-only; raw streams stay local unless consented.
