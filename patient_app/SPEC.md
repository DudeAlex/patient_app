# Product Specification — Patient App

Status: living document (keep updated with every change)

## 1. Vision
- Local‑first personal health records app.
- User owns their data; no server. Optional encrypted backup to Google Drive App Data.
- Simple, trustworthy UX that prioritizes privacy and portability.

## 2. Scope
In scope (MVP)
- Records: create/read/update/delete structured health records.
- Optional attachments (mobile only initially).
- Backup/restore: manual, encrypted archive to Drive App Data.
- Platforms: Android, iOS (primary), Web (runs without backup/restore).

Out of scope (for MVP)
- Real‑time sync/collaboration, multi‑account.
- Server components.
- OCR pipeline beyond stub.

## 3. Personas & Goals
- Single user managing personal medical notes, lab results, visit summaries.
- Goals: capture records quickly, keep them private, restore on device loss.

## 4. Feature Requirements & Acceptance Criteria
4.1 Settings → Google Sign‑In
- Must allow sign‑in/out using Google Sign‑In v7.
- Shows current email when signed in.
- Errors surface via SnackBar with actionable hints.

4.2 Backup to Google Drive (mobile)
- Preconditions: user signed in; device online.
- Behavior: zips app docs dir → AES‑GCM encrypt → upload to Drive App Data as `patient-backup-v1.enc` (create/update).
- Success criteria: user sees confirmation; Drive file exists; no plaintext written to cloud.
- Failure cases: no auth, network error, quota; show SnackBar with friendly message. No partial restore/overwrite occurs on failure.

4.3 Restore from Google Drive (mobile)
- Preconditions: user signed in; backup exists.
- Behavior: download → AES‑GCM decrypt → unzip into app docs dir, replacing contents.
- Success criteria: local files replaced; user sees confirmation.
- Failure cases: missing file, corrupted payload, wrong key; show SnackBar and do not modify existing files on decrypt failure.

4.4 Web behavior
- App runs without Drive backup/restore UI. Any call to backup/restore surface as unsupported.

4.5 Records CRUD UI (planned M2)
- Home list sorted by date desc with type, title, date.
- Add/Edit: type (lab/visit/med/note), date, title, optional text, tags.
- Detail view; delete moves to trash or sets `deletedAt`.
- Acceptance: operations persist in Isar; list updates; timestamps set appropriately.

## 5. Data Model (Isar)
- Record
  - id (auto), type, date, title, text?, tags[], createdAt, updatedAt, deletedAt?
  - Index: `typeDateIndex`
- Attachment
  - id (auto), recordId, path, kind (image/pdf), ocrText?, createdAt
  - Index: `recordIndex`
- Insight
  - id (auto), recordId?, kind, text, createdAt
- SyncState (singleton id=1)
  - lastSyncedAt?, lastRemoteModified?, localChangeCounter, deviceId

Source of truth: definitions in `lib/features/records/model/*.dart`.

## 6. Backup & Sync Specification
- Filename: `patient-backup-v1.enc` (Drive App Data space)
- Content: ZIP of entire application documents directory (Isar DB files + attachments directory).
- Encryption: AES‑GCM 256‑bit.
  - Nonce: 12 bytes random per export.
  - MAC: 16 bytes appended.
  - Payload layout: `[12B nonce][ciphertext...][16B mac]`.
- Import policy: replace local docs directory contents on successful decrypt/unzip. On any error, abort without modifying existing files.
- Conflict policy (MVP): manual, user‑initiated only. Future: last‑write‑wins using Drive `modifiedTime` vs `SyncState`.

## 7. Security & Privacy
- Encryption key: 32‑byte key stored via `flutter_secure_storage` per device; never uploaded.
- No unencrypted data leaves device for backups.
- Web: backup disabled; web stubs throw `UnsupportedError`.
- Note: README currently states on‑device DB is not encrypted. The `IsarDatabase.open` supports `encryptionKey`—decision needed whether to enable at runtime or keep plaintext for now.

## 8. Platform Matrix
- Android/iOS: full functionality including Drive backup/restore.
- Web (Chrome): records UI only; backup/restore hidden and unsupported.

## 9. Non‑Functional Requirements
- Reliability: backup/restore must be atomic w.r.t. local files (no partial overwrite on failures).
- Performance: backup completes for typical datasets (<200MB) without UI freeze; show progress in future.
- Usability: clear status via SnackBars; confirm completion or actionable errors.

## 10. Error Handling (canonical messages)
- Not signed in → “Please sign in first”.
- No backup found → “No backup found in Drive”.
- Decrypt failure → “Restore failed: invalid backup or key”.
- Network/auth → “Backup/Restore failed: <reason>”.

## 11. Manual Test Plan (MVP)
T‑01 Sign‑In/Out
- Open Settings → Sign in; verify email displayed. Sign out; verify cleared.

T‑02 Backup Success
- With sample data and attachments, tap Backup; verify success SnackBar; confirm Drive has `patient-backup-v1.enc` in App Data.

T‑03 Restore Success
- Modify local data; tap Restore; verify data matches snapshot; success SnackBar shown.

T‑04 Missing Backup
- On a fresh account/device, tap Restore; expect “No backup found in Drive”.

T‑05 Web Behavior
- Run web build; verify backup/restore buttons hidden and calling stubs throws `UnsupportedError` if invoked.

T‑06 Failure Paths
- Simulate offline during backup/restore; expect error SnackBar; local files unchanged.
- Corrupt downloaded file; expect decrypt error; local files unchanged.

## 12. Open Questions / Decisions Log
- Should Isar DB be encrypted at rest using `KeyManager`? Current README says “not encrypted yet”. Decision TBD.
- Auto‑sync triggers (on resume/exit) and dirty tracking semantics (planned M3).
- Web JSON export/import format (optional milestone): filename, schema versioning.

## 13. Release Checklist (MVP)
- Records CRUD UI implemented and validated.
- Backup/restore passes Manual Test Plan.
- README/RUNNING/SPEC/TROUBLESHOOTING updated.
- Google OAuth setup instructions verified.

References
- Code: `lib/core/*`, `lib/ui/*`, `lib/features/records/*`
- Docs: README.md, RUNNING.md, ARCHITECTURE.md, SYNC.md, TROUBLESHOOTING.md, AGENTS.md

