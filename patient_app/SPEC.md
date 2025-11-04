# Product Specification — Patient App

Status: living document (keep updated with every change)

## 1. Vision
- Local-first personal health records app.
- User owns their data; no server. Optional encrypted backup to Google Drive App Data.
- Simple, trustworthy UX that prioritizes privacy and portability.
- Compassionate, multilingual companion that can optionally leverage AI to organise data, surface insights, and encourage patients respectfully.

## 2. Scope
In scope (MVP)
- Records: create/read/update/delete structured health records.
- Optional attachments (mobile only initially).
- Backup/restore: manual, encrypted archive to Drive App Data.
- Platforms: Android, iOS (primary), Web (runs without backup/restore).
- Support for multi-modal record creation (photo, document scan, dictation, keyboard, file upload, email import) with a unified review step.
- Optional AI-assisted mode (Together AI) that patients may opt into for extraction, organisation, and wellness guidance.
- Support network contact storage with quick emergency access.
- Accessibility-first UX tuned for older, non-technical users.
- Multilingual UX (English + Russian first; pathway to Central Asian languages).
- Phone-based vitals capture (pulse and blood pressure) using camera PPG or connected peripherals (planned extension).

Out of scope (for MVP)
- Real-time sync/collaboration, multi-account.
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

4.2a Auto Backup Toggle (mobile, beta)
- Settings exposes “Auto backup” switch (default off) when Drive backup is supported.
- Default cadence: one automatic backup per week. Patients can opt into alternative triggers (e.g., on-resume after critical changes) once the scheduling UI ships.
- Current implementation (Nov 2025) still relies on resume-after-critical-change triggers; moving to weekly cadence requires refactoring the lifecycle coordinator and scheduler.
- When the weekly cadence lands and the patient is signed in, the app silently attempts a Drive backup using the configured schedule; ad-hoc triggers should remain available.
- Resume trigger must skip if no critical changes are pending, another backup is running, or auth headers would prompt UI.
- Auto backup writes `lastSyncedAt` on success so Settings can display “Last sync” timestamp and pending change counts.
- Failure: log debug output and leave dirty counters intact for the next attempt; UI feedback for failures is planned in later M4 tasks.

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

4.6 Multi-Modal "Add Record" Flow (planned M2+)
- Entry modal offers: Photo/Image, Document Scan, Voice Dictation, Keyboard/Text, File Upload, and Email Import.
- Each capture or import mode stores raw artefacts locally, then funnels into a unified review panel.
- Voice dictation provides live transcription (where supported) and allows manual corrections.
- Photo capture runs instant clarity/OCR checks; if text or key fields are unreadable, prompt the patient to retake before leaving the flow.
- Document scan auto-detects edges, cleans glare, and extracts text for review; if OCR confidence is low, offer guided rescan before continuing, with manual adjustments as fallback.
- File upload supports PDFs and common image formats, preserving attachments for mobile and web parity.
- Email import connects to a patient-approved Gmail account via the Gmail API (read-only, restricted label), parses medical summaries, and surfaces source metadata.
- Contextual follow-up prompts request missing details; patients can skip or answer later.
- Save step confirms merged data, tags, attachments, and shows accessible success feedback.
- No video capture is planned for this milestone.

4.7 Phone-Based Vitals Capture (planned M3+)
- Patients can measure pulse and blood pressure directly on supported phones (camera-based PPG or connected peripherals).
- Flow guides placement (finger over camera/flash or cuff pairing), validates signal quality, and shares safety disclaimers.
- Measurements persist as structured records with timestamp, method, and confidence score; readings can be linked to existing records.
- Offline operation required; AI suggestions may annotate results when assistance is enabled.

4.8 AI-Assisted Companion (Opt-In, planned M3)
- Settings exposes `AiProcessingMode` toggle: Local Only (default), AI Assisted.
- When enabled (with explicit consent), photos and transcripts may be sent to Together AI (Llama 70B text, Apriel image) via `AiProcessingService`.
- AI returns structured fields, suggested tags, safety notes, confidence scores, and compassionate messages.
- Raw inputs are saved before AI processing; suggestions require patient confirmation before overwriting.
- Offline behaviour: queue requests and notify the patient; manual completion is always available.

4.9 Support Network & Emergency Assist (planned M3)
- Patients can store trusted contacts (name, relationship, phone, preferred channel, priority).
- Home dashboard shows quick actions for top contacts; dedicated emergency screen with large “Call / Message / Share summary” buttons and optional countdown auto-call.
- Sharing requires explicit confirmation; audit log records who was notified and when.

4.10 Wellness Companion & Check-Ins (planned M4)
- Daily/weekly prompts capture mood, energy, concerns (voice or text).
- AI generates empathetic encouragement, practical suggestions, and curated resources (e.g., breathing exercises).
- Notifications use friendly tone, can be snoozed or muted.
- Future: share check-ins with caregivers (with consent) or export summaries.

## 5. Data Model (Isar)
- Record
  - id (auto), type, date, title, text?, tags[], createdAt, updatedAt, deletedAt?
  - Index: `typeDateIndex`
  - Attachment
    - id (auto), recordId, path, kind (image/pdf/audio/email), ocrText?, createdAt, sourceMetadata?
  - Index: `recordIndex`
- Insight
  - id (auto), recordId?, kind, text, createdAt
- SupportContact (planned)
  - id (auto), name, relationship, priority, preferredChannel, phone?, messagingHandle?, timeZone?, notes?, createdAt, updatedAt
  - WellnessCheckIn (planned)
    - id (auto), moodScore?, energyScore?, notes, createdAt, aiSummary?, aiConfidence?
  - VitalMeasurement (planned)
    - id (auto), kind (`pulse` | `blood_pressure`), primaryValue, secondaryValue?, unit, method, confidence?, capturedAt, linkedRecordId?
  - SyncState (singleton id=1)
  - lastSyncedAt?, lastRemoteModified?, localChangeCounter, deviceId

Source of truth: definitions in `lib/features/records/model/*.dart`.

## 6. Backup & Sync Specification
- Filename: `patient-backup-v1.enc` (Drive App Data space)
- Content: ZIP of entire application documents directory (Isar DB files + attachments directory).
- Encryption: AES-GCM 256-bit.
  - Nonce: 12 bytes random per export.
  - MAC: 16 bytes appended.
  - Payload layout: `[12B nonce][ciphertext...][16B mac]`.
- Import policy: replace local docs directory contents on successful decrypt/unzip. On any error, abort without modifying existing files.
- Conflict policy (MVP): manual, user-initiated only. Future: last-write-wins using Drive `modifiedTime` vs `SyncState`.
- AI queue data (if present) is stored locally alongside records and included in backups so pending requests persist across reinstalls.

## 7. Security & Privacy
- Encryption key: 32-byte key stored via `flutter_secure_storage` per device; never uploaded.
- No unencrypted data leaves device for backups.
- Web: backup disabled; web stubs throw `UnsupportedError`.
- AI-assisted mode is opt-in: patients must grant explicit consent before any PHI is sent to Together AI.
- AI requests travel over HTTPS using temporary tokens/API key stored securely (never bundled in-app binaries).
- Provide per-request banners indicating when external processing occurs; allow cancel.
- Log only non-PII telemetry (request ids, duration, error codes).
- Note: README currently states on-device DB is not encrypted. The `IsarDatabase.open` supports `encryptionKey`-decision needed whether to enable at runtime or keep plaintext for now.

## 8. Platform Matrix
- Android/iOS: full functionality including Drive backup/restore.
- Web (Chrome): records UI only; backup/restore hidden and unsupported.
- AI-assisted features roll out to Android/iOS first; web companion requires additional consent flow and is TBD.

## 9. Non-Functional Requirements
- Reliability: backup/restore must be atomic w.r.t. local files (no partial overwrite on failures).
- Performance: backup completes for typical datasets (<200MB) without UI freeze; show progress in future.
- Usability: clear status via SnackBars; confirm completion or actionable errors.
- Accessibility: large typography, high-contrast themes, step-by-step flows, voice narration options suitable for older users unfamiliar with smartphones.
- Multilingual: all UI copy, notifications, AI prompts/responses localised (starting with English/Russian; extendable to Central Asian languages). Ensure layouts adapt to longer strings.
- Offline-first: core record capture works without network; AI features degrade gracefully, queueing work and keeping patients informed.
- Empathy & Safety: AI-generated advice must include disclaimers, cite source records, and escalate red flags (e.g., suggest contacting doctor/emergency services) without inducing panic.

## 10. Error Handling (canonical messages)
- Not signed in: "Please sign in first".
- No backup found: "No backup found in Drive".
- Decrypt failure: "Restore failed: invalid backup or key".
- Network/auth: "Backup/Restore failed: <reason>".
- AI opt-out: "AI assistance is disabled. You can enable it in Settings."
- AI pending: "Processing with AI; we'll notify you soon."
- AI failure: "AI review failed: <reason>. Your original record is saved."

## 11. Manual Test Plan (MVP + Planned Extensions)
T-01 Sign-In/Out
- Open Settings → Sign in; verify email displayed. Sign out; verify cleared.

T‑02 Backup Success
- With sample data and attachments, tap Backup; verify success SnackBar; confirm Drive has `patient-backup-v1.enc` in App Data.

T‑03 Restore Success
- Modify local data; tap Restore; verify data matches snapshot; success SnackBar shown.

T‑04 Missing Backup
- On a fresh account/device, tap Restore; expect “No backup found in Drive”.

T‑05 Web Behavior
- Run web build; verify backup/restore buttons hidden and calling stubs throws `UnsupportedError` if invoked.

T-06 Failure Paths
- Simulate offline during backup/restore; expect error SnackBar; local files unchanged.
- Corrupt downloaded file; expect decrypt error; local files unchanged.
- Future AI & Capture Tests (outline)
    - AI-01 Consent Opt-In: enable AI mode, capture record, verify consent banner and toggle persistence.
    - AI-02 Offline Queue: disable network, capture record, ensure AI task queues and manual record saved.
    - AI-03 Review Merge: accept/reject AI suggestions and confirm original artefacts remain accessible.
    - ACC-01 Accessibility Audit: run with large fonts/screen reader to ensure multi-modal flow is usable.
    - CAP-01 Document Scan: scan a paper record, verify auto-crop, OCR text, and attachment persistence.
    - CAP-02 Email Import: import a forwarded visit summary, confirm metadata attribution and record creation.
    - CAP-03 File Upload (Web/Mobile): attach PDF lab results, ensure backup includes the file.
    - CAP-04 Photo Retake Prompt: capture a blurry photo, confirm the flow requests a retake until clarity/OCR thresholds pass or manual override selected.
    - VIT-01 Pulse Capture: measure pulse via camera, verify value, timestamp, and confidence stored.
    - VIT-02 Blood Pressure Capture: pair or simulate cuff input, ensure readings link to the correct record.

## 12. Open Questions / Decisions Log
- Should Isar DB be encrypted at rest using `KeyManager`? Current README says "not encrypted yet". Decision TBD.
- Auto-sync triggers (on resume/exit) and dirty tracking semantics (planned M3).
- Web JSON export/import format (optional milestone): filename, schema versioning.
- Together AI usage limits/pricing strategy and whether a proxy service is required.
- How to store/share audio recordings securely (encryption at rest, retention policy).
- Approach for multilingual medical terminology (glossary ownership, translator workflow).
- Rules for AI-triggered safety escalations (when to prompt emergency contact suggestions).
- Gmail import implementation: define required label/forwarding setup, retained message window, and consent copy for scoped read-only access.
- Camera-based blood pressure accuracy: acceptable error tolerance, calibration flow, and device compatibility matrix.

## 13. Release Checklist (MVP)
- Records CRUD UI implemented and validated.
- Backup/restore passes Manual Test Plan.
- README/RUNNING/SPEC/TROUBLESHOOTING updated.
- Google OAuth setup instructions verified.
- AI-assisted mode gated behind consent toggle and feature flag.
- Multi-modal Add Record flow passes usability testing with older adults.
- Localization pipeline established (`gen-l10n`), English/Russian strings complete.
- Support network data model and emergency actions implemented with audit logging.

References
- Code: `lib/core/*`, `lib/ui/*`, `lib/features/records/*`
- Docs: README.md, RUNNING.md, ARCHITECTURE.md, SYNC.md, TROUBLESHOOTING.md, TODO.md, AGENTS.md, AI_ASSISTED_PATIENT_APP_PLAN.md
