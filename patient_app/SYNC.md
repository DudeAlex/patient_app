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
  - Imported assets now include scanned PDFs, uploaded documents, email attachments, and audio clips alongside photos.
- Patients can disable auto backup entirely from Settings; when the toggle is off, only manual backups and restores run.
- Auto sync batches critical-only edits by throttling background backups to at most once every six hours; pending changes remain queued until the next run or a manual backup.
- Auto backup toggle lives in Settings (Android/iOS). Product target is a weekly background backup by default with patient-configurable cadence; the current implementation still uses resume-after-critical-change triggers and will be refactored to the weekly scheduler in a follow-up.
- Future production UX: a minimal profile panel should expose the manual “Backup now” button plus a small set of cadence presets (6h/12h/daily/weekly/manual), alongside display preferences (light/dark/auto theme and small/medium/large text size), so patients control cadence and readability without extra screens.
- Production blocker: implement a secure key portability flow so the AES encryption key travels with the patient when they replace or reset devices; Drive restores currently work only on the original device. Consider patient-held passphrases/mnemonics, offline QR/file exports, and optional platform key backup integration (Android Keystore/iCloud Keychain).

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
- Each task references source artefacts (photo, audio, text) and the mode (photo/scan/voice/keyboard/file/email/vitals).
- When online and consented, the queue sends payloads to Together AI and persists structured responses + confidence + prompts.
- Failures mark tasks for retry and notify the patient; originals remain untouched.
  - Email-derived tasks capture headers, message ids, and source mailbox labels for traceability.
  - Vitals readings keep raw sensor traces local while enqueueing structured pulse/blood-pressure data for AI annotations.

Consent & Privacy
- Local-only mode never transmits PHI off-device.
- AI-assisted mode requires explicit toggle and displays per-request notices ("This photo will be analysed via Together AI").
- API keys are stored in secure storage or mediated via a proxy; never shipped in binaries.
- Logs capture only non-PII telemetry (request ids, durations, error codes) to aid troubleshooting.
- Email import uses minimal scopes (read-only forwarding label) and records headers so patients can audit access.
- Phone-based vitals capture reminds patients readings are informational and keeps raw video streams on-device unless consented for diagnostics.
