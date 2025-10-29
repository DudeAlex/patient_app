# Sync & Backup

Goal
- Provide zero-cost sync using the user's Google Drive App Data folder without running servers.
- Maintain privacy-first defaults while allowing patients to opt into cloud AI assistance with clear consent.

Mobile Backup Format (v1)
- Filename: `patient-backup-v1.enc`
- Content: ZIP of the entire app documents directory (Isar DB files + attachments)
- Encryption: AES-GCM, 12-byte random nonce, key from `flutter_secure_storage`

Operations
- Backup (export):
  1) Zip app docs dir
  2) Encrypt bytes
  3) Upload to Drive App Data (create or update)
- Restore (import):
  1) Download from Drive App Data
  2) Decrypt bytes
  3) Unzip to app docs dir (replace)

Auth
- Google Sign-In v7 API
  - Initialize via `GoogleSignIn.instance.initialize`
  - Interactive login via `authenticate`
  - Headers via `authorizationClient.authorizationHeaders([Drive appData scope])`
  - Android requires a Web OAuth client id passed as `--dart-define=GOOGLE_ANDROID_SERVER_CLIENT_ID=...`
  - Use a Google Play AVD and sign into a Google account on the emulator
  - In‑app: use Settings → Run Auth Diagnostics to test auth flows and header retrieval (safe logs, no tokens)

Conflict Policy (MVP)
- Manual: user triggers backup or restore
- Future auto-sync: last-write-wins using Drive `modifiedTime` vs local `SyncState`

Web Behavior
- Web uses a stub: backup/restore hidden by default (browser FS sandbox)
- Optional future: JSON-only export/import of records with a distinct filename

AI Processing Queue (Planned)
- `AiProcessingService` stores pending tasks in local Isar so requests survive restarts and are included in backups.
- Each task references source artefacts (photo, audio, text) and the mode (photo/voice/keyboard).
- When online and consented, the queue sends payloads to Together AI and persists structured responses + confidence + prompts.
- Failures mark tasks for retry and notify the patient; originals remain untouched.

Consent & Privacy
- Local-only mode never transmits PHI off-device.
- AI-assisted mode requires explicit toggle and displays per-request notices (“This photo will be analysed via Together AI”).
- API keys are stored in secure storage or mediated via a proxy; never shipped in binaries.
- Logs capture only non-PII telemetry (request ids, durations, error codes) to aid troubleshooting.
