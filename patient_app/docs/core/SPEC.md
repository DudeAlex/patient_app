Status: ACTIVE

# Product Specification - Patient App

## Vision
- Local-first personal health records evolving to universal info system; user-owned data, optional encrypted Drive backup; compassionate, multilingual companion (opt-in AI).

## Scope (MVP)
- Records CRUD with attachments (mobile first), optional backup/restore, multi-modal capture (photo/scan/voice/keyboard/file/email), opt-in AI assist (Together AI), support network contacts, accessibility + multilingual. Out: real-time sync/server, full OCR pipeline.

## Personas & Goals
- Single user managing medical notes/results; goal: capture quickly, keep private, restore on loss.

## Key Requirements & Acceptance
- Settings/Profile: Google sign-in v7, show email, SnackBar errors; compact profile hub with backup button, cadence presets (6h/12h/daily/weekly/manual), AI consent toggle placeholder, display prefs; backup-key portability entry point (placeholder).
- Backup (mobile): zip docs dir -> AES-GCM encrypt -> upload `patient-backup-v1.enc`; confirm success; on failure show friendly error; no partial restores.
- Auto backup (mobile beta): toggle + cadence presets; resume triggers when dirty + cadence elapsed + Wi-Fi/ethernet + auth; minimum 6h spacing; manual backup always available; disable stops auto runs; weekly default; production blocker: key portability.
- Restore (mobile): download/decrypt/unzip; replace local; fail safely on missing/corrupt/wrong key.
- Web: runs without backup/restore (stubs throw UnsupportedError).
- Records UI (M2 delivered): list/search/pagination; add/edit/delete types (lab/visit/med/note) with date/title/text/tags; delete soft.
- Multi-modal add (planned): photo clarity/retake; doc scan auto-crop/clarity; voice dictation with manual edit; keyboard form; file upload (PDF/images); email import (Gmail label); review/merge with contextual prompts.
- AI summaries v1: opt-in, consent-gated; inputs: space/category/title/tags/body/attachment descriptors; outputs: �120-word summary + ≤3 action hints (�12 words), metadata (provider/latency/confidence/tokens); flags: `ai_enabled`, `ai_mode` (fake default, remote placeholder); UI hides when disabled.
- Vitals (planned): pulse/blood pressure capture; store value/confidence/method/timestamp; offline; AI annotations optional.
- AI companion (planned): toggle `AiProcessingMode` localOnly vs aiAssisted; send photos/transcripts with consent; queue offline; suggestions require confirmation; safety disclaimers.
- Support network & emergency (planned): contacts with quick actions; emergency screen with large call/message/share; explicit confirmation and audit.
- Wellness companion (planned): mood/energy check-ins, empathetic suggestions, notifications; localization; caregiver export later.

## Data Model (Isar)
- Record: id, type, date, title, text?, tags[], createdAt, updatedAt, deletedAt?; index `typeDateIndex`.
- Attachment: id, recordId, path, kind (image/pdf/audio/email), ocrText?, createdAt, sourceMetadata?; index `recordIndex`.
- Insight: id, recordId?, kind, text, createdAt.
- Planned: SupportContact, WellnessCheckIn, VitalMeasurement; SyncState singleton (lastSyncedAt?, lastRemoteModified?, localChangeCounter, deviceId).

## Backup & Sync
- File: `patient-backup-v1.enc` in Drive App Data; layout `[nonce][ciphertext][mac]`.
- Operations: backup = zip docs dir -> encrypt -> upload; restore = download -> decrypt -> unzip replace; conflicts manual (future LWW); auto-sync cadence & Wi-Fi gating; key portability TBD.
- AI queue data included in backup.

## Security & Privacy
- 32-byte key in secure storage; no plaintext to cloud; AI opt-in only; HTTPS; redact logging; consent banners; AI payload limited to descriptors.
- Web backup disabled; DB encryption at rest TBD.

## Platform
- Android/iOS full; Web UI only (no backup); AI focuses mobile first.

## Non-Functional
- Reliability: atomic restore/backup; Performance: backup typical <200MB without UI freeze; Usability: clear SnackBars; Accessibility: large type/high contrast/stepwise flows/voice-friendly; Multilingual ready; Offline-first; Safety: disclaimers, escalation hints.

## Error Messages
- Not signed in: "Please sign in first"
- No backup: "No backup found in Drive"
- Decrypt failure: "Restore failed: invalid backup or key"
- Network/auth: "Backup/Restore failed: <reason>"
- AI opt-out: "AI assistance is disabled. You can enable it in Settings."
- AI pending/failure/offline messages as specified.

## Manual Test Plan (current/planned)
- T-01 Sign-In/Out (Settings email reflects state).
- T-02 Backup Success (Drive file exists, SnackBar).
- T-03 Restore Success (data matches snapshot).
- T-04 Missing Backup (friendly message).
- T-05 Web hides backup/restore; stubs throw UnsupportedError.
- T-06 Failure paths: offline/corrupt payload leaves local untouched.
- Future AI/Capture/Vitals tests: consent, offline queue, review merge, accessibility, OCR clarity prompts, email import, file upload, vitals capture, performance, token budgeting, etc.

## Open Questions
- DB encryption at rest via `KeyManager`?
- Backup key portability approach (passphrase/QR/platform key backup).
- Auto-sync triggers semantics; web JSON export format; Together AI pricing/proxy; audio retention; localization workflow; safety escalation rules; Gmail import label/scope; BP accuracy tolerance.

## Release Checklist (MVP)
- Records CRUD; backup/restore passes manual plan; docs updated; OAuth setup verified; AI toggle gated; multi-modal flow usable; gen-l10n ready; support network/emergency implemented with audit; localization and wellness per roadmap.
