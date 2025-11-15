# M5 – Multi-Modal Capture & Accessibility Plan

**Status:** In Progress (Phase 5 - File Upload Complete, Polish Remaining)
**Last Updated:** 2025-11-13
**Completion:** 18/27 tasks (67%)

Bring the add-record experience from a simple form to a patient-friendly capture assistant that supports photos, scans, audio dictation, keyboard entry, file uploads, and Gmail imports. The MVP focuses on delivering a cohesive flow on mobile (Android first) with accessible defaults and a path toward web parity where feasible.

## For AI Agents

**Context needed before starting:**
1. `CLEAN_ARCHITECTURE_GUIDE.md` - Layer responsibilities and dependency rules
2. `ARCHITECTURE.md` - Module boundaries and capture architecture
3. `SPEC.md` sections 4.6, 9 - Multi-modal requirements and accessibility
4. `M5_MULTI_MODAL_PLAN.md` (this file) - Task breakdown

**Entry points:**
- Capture launcher: `lib/features/capture_core/ui/capture_launcher_screen.dart`
- Photo mode: `lib/features/capture_modes/photo/`
- Document scan: `lib/features/capture_modes/document_scan/`
- Voice mode: `lib/features/capture_modes/voice/`
- UI mockups: `UI Design Samples/` (reference designs for visual guidance)

**Validation after each task:**
1. Run `flutter analyze` (must be clean)
2. Run relevant unit tests: `flutter test test/features/capture_*`
3. Manual test on Android emulator (log in TESTING.md)
4. Update this plan's completion count

**Common pitfalls:**
- Don't import `AttachmentsStorage` directly in modes - use capture storage ports
- Don't put business logic in UI widgets - use use cases
- Don't skip consent/permission checks for camera/mic
- Don't hard-code strings - prepare for localization
- Always preserve original artifacts before AI processing

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
- [x] Add baseline clarity checks (Laplacian blur detection + retry prompts); allow override if the patient insists on keeping a blurry image.
- [x] Implement baseline document scan flow (multi-page capture with grayscale enhancement) using the camera; persist both original and cleaned page images (edge detection/advanced cleanup remains TODO).
- [ ] Use AI vision/LLM extraction to produce structured text/summary for review; surface in the review UI for editing/tagging.
- [x] Expose AI-assist hooks (clarity scoring, document analysis pipeline stubs) through replaceable interfaces documented in the module README.

### 4. Voice Dictation & Assistant Audio Pipeline
- Capture UX
  - [x] Add voice capture module with consent-first controls and start/stop UI scaffold (waveform and input level TBD).
  - [x] Persist recorded audio in the session directory with duration metadata; plan waveform stats extraction as a follow-up.
  - [x] Convert audio to text via an injectable `VoiceTranscriptionPipeline` (stubbed for now, ready for providers).
  - [x] Feed transcription results into the review screen (suggested details/tags) with retry/discard options.
- Assistant & Command Layer
  - [ ] Define a shared `VoiceIntentRouter` so recorded snippets can either populate dictation, trigger app commands (“start scan”), or forward to the AI companion for dialogue.
  - [ ] Expose streaming APIs for future real-time conversations (LLM request/response, optional TTS playback).
  - [ ] Document required permissions, privacy copy, and opt-in flows for always-on voice interactions.

### 5. Keyboard/Text Entry Enhancements
- [ ] Modernise the existing form for the new flow (step-by-step layout, better defaults, quick tag suggestions).
- [ ] Share validation and field widgets across capture modes to ensure consistent error handling.
- [ ] Ensure offline persistence and recovery (drafts survive app backgrounding).

### 6. File Upload & Email Import
- [x] Implement local file picker (PDF/images) with clear copy about storage location and size limits.
  - File picker integrated with type filtering (PDF, JPEG, PNG)
  - 50 MB size limit enforced with user-friendly error messages
  - Files copied to session directory with timestamped names
  - Original files preserved in source location
- [x] Store imported files as attachments with MIME metadata; generate thumbnails/previews where possible.
  - Attachments saved with complete metadata: path, MIME type, size, timestamps
  - Artifact type inference: PDF → documentScan, images → photo
  - Linked to records via recordId foreign key
  - Metadata includes originalFileName for reference
- [ ] Prototype Gmail label-based import: OAuth scopes, label selection, metadata capture (subject, sender, receivedAt); save fetched content locally without retaining credentials in plaintext.
- [ ] Provide patient controls to disconnect Gmail and purge imported artefacts.

### 7. Unified Review & Save Flow
- [x] Build review panel that merges captured artefacts, extracted text, suggested tags, and patient edits before saving.
  - Editable review screen implemented with form validation, type selector, date picker, and save functionality.
- [ ] Allow reordering or removing attachments and editing metadata prior to commit.
- [x] Ensure saving creates/updates Record + Attachment documents atomically; hook dirty tracking for auto-sync when that feature resumes.
  - Attachments now saved with recordId, path, metadata (kind, mimeType, sizeBytes, durationMs, pageCount, capturedAt, source, metadataJson).
- [x] Surface success/Failure feedback that meets accessibility guidelines (snackbar, haptics, voice prompt).

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

## Platform-Specific Limitations

### File Upload
- **Android**: Fully supported with native file picker
- **iOS**: Supported via file_picker package (requires testing)
- **Web**: Supported via browser file input (limited to browser-accessible files)
- **File Types**: Restricted to PDF, JPEG, PNG for MVP
- **Size Limit**: 50 MB maximum per file
- **Storage**: Files copied to app-private storage (attachments/sessions/{sessionId}/)
- **Permissions**: Handled automatically by file_picker package on mobile

### Known Limitations
- No multi-file selection (single file per upload operation)
- No file preview in review screen (shows metadata only)
- No automatic image compression (large photos stored as-is)
- No duplicate detection (user can upload same file multiple times)
- Session cleanup not automatic (temporary files persist if user cancels before save)

## Open Questions / Risks
- Package choices for document scanning and STT (licensing, size, offline capability).
- Gmail API quota and security review requirements; need for proxy service.
- Storage footprint management: retention policy, compression, deletion workflow.
- Encryption-at-rest decision for attachments (currently plaintext on device).
- How to gate advanced modes on low-end devices (performance, storage).

