# M5 – Multi-Modal Capture & Accessibility Plan

Bring the add-record experience from a simple form to a patient-friendly capture assistant that supports photos, scans, audio dictation, keyboard entry, file uploads, and Gmail imports. The MVP focuses on delivering a cohesive flow on mobile (Android first) with accessible defaults and a path toward web parity where feasible.

## MVP Scope (Ship as part of M5)

### 1. Foundational Decisions & Infrastructure
- [ ] Finalise capture UX requirements with design/PM (entry points, modal vs full-screen flow, back/exit affordances).
- [ ] Audit privacy/consent copy for each capture mode (camera/mic/storage/email scopes).
- [ ] Catalogue patient-facing strings and register localisation keys (no hard-coded copy in modules).
- [x] Extend attachments storage to support photos, scans, audio, PDFs, and general files with predictable naming + metadata (size, type, capturedAt).
- [x] Define artefact schema updates in Isar (Attachment model fields, linking to records, OCR transcripts, audio duration).
- [ ] Confirm minimum platform support (Android baseline API, iOS availability, web fallbacks) and flag per-mode limitations.

### 2. Capture Launcher & Accessibility Shell
- [x] Replace current FAB ? `AddRecordScreen` navigation with a multimodal launcher surface (large buttons, high contrast, voice-over friendly).
- [x] Ensure launcher respects accessibility: focus order, screen-reader labels, large text scaling, high contrast theme.
- [x] Provide safe exit and "switch to keyboard entry" fallback at every step.

### 3. Photo & Document Scan Pipelines
- [x] Integrate camera capture (still photo) including permission prompts and local save into attachments storage.
- [ ] Add clarity checks (blur detection + LLM-based guidance) with retry prompts; allow override if the patient insists on keeping a blurry image.
- [ ] Implement document scan flow (edge detection, multi-page support, contrast cleanup) using an appropriate package; persist both original image(s) and cleaned PDF/image output.
- [ ] Use AI vision/LLM extraction to produce structured text/summary for review; surface in the review UI for editing/tagging.
- [ ] Expose AI-assist hooks (clarity scoring, vision LLM, guidance) through replaceable interfaces documented in the module README.

### 4. Voice Dictation Capture
- [ ] Add audio recording UI with large record/stop controls, progress indicator, and explicit consent copy.
- [ ] Convert audio to text (on-device STT if available; otherwise stub & document) while saving the raw audio attachment.
- [ ] Allow manual text editing before review and handle retries or background noise gracefully.

### 5. Keyboard/Text Entry Enhancements
- [ ] Modernise the existing form for the new flow (step-by-step layout, better defaults, quick tag suggestions).
- [ ] Share validation and field widgets across capture modes to ensure consistent error handling.
- [ ] Ensure offline persistence and recovery (drafts survive app backgrounding).

### 6. File Upload & Email Import
- [ ] Implement local file picker (PDF/images) with clear copy about storage location and size limits.
- [ ] Store imported files as attachments with MIME metadata; generate thumbnails/previews where possible.
- [ ] Prototype Gmail label-based import: OAuth scopes, label selection, metadata capture (subject, sender, receivedAt); save fetched content locally without retaining credentials in plaintext.
- [ ] Provide patient controls to disconnect Gmail and purge imported artefacts.

### 7. Unified Review & Save Flow
- [ ] Build review panel that merges captured artefacts, extracted text, suggested tags, and patient edits before saving.
- [ ] Allow reordering or removing attachments and editing metadata prior to commit.
- [ ] Ensure saving creates/updates Record + Attachment documents atomically; hook dirty tracking for auto-sync when that feature resumes.
- [ ] Surface success/Failure feedback that meets accessibility guidelines (snackbar, haptics, voice prompt).

### 8. Accessibility & Internationalisation
- [ ] Run large-font, screen-reader, and colour-contrast audits for each capture mode.
- [ ] Prepare strings for localisation (centralise copy, note pending l10n workflow).
- [ ] Provide optional narration / helper text for complex steps (e.g., “Align the document inside the frame”).

### 9. Testing & Documentation
- [ ] Expand `TESTING.md` with manual scenarios per capture mode (happy path + retries).
- [ ] Update README/TODO/SPEC with delivered capabilities, limitations (e.g., Gmail import Android-only), and follow-ups.
- [ ] Add troubleshooting guidance (permissions denied, camera unavailable, no microphone).
- [ ] Ensure backup/restore includes new attachment types (verify via manual test).

## Deferred Enhancements (Post-MVP)
- Advanced OCR quality scoring with AI-based suggestions and auto-tagging.
- Serverless speech-to-text quality improvements and multi-language dictation.
- Video capture or live photo notes (explicitly out of scope for M5).
- Background upload queue for large files and network resilience.
- Web attachment capture parity (camera, audio) leveraging browser APIs.
- AI-assisted summarisation that drafts structured notes from multi-modal inputs.
- Collaborative review mode for caregivers with consent management.

## Open Questions / Risks
- Package choices for document scanning and STT (licensing, size, offline capability).
- Gmail API quota and security review requirements; need for proxy service.
- Storage footprint management: retention policy, compression, deletion workflow.
- Encryption-at-rest decision for attachments (currently plaintext on device).
- How to gate advanced modes on low-end devices (performance, storage).






