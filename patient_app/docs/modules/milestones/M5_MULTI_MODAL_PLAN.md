Status: ACTIVE

# M5 - Multi-Modal Capture & Accessibility Plan

**Status:** In progress (Phase 5) — 18/27 tasks (~67%) as of 2025-11-13.  
Goal: patient-friendly add-record flow with photo/scan/voice/keyboard/file/email capture, unified review, accessibility-first (Android first, web parity later).

## References
- Clean architecture/layering: `CLEAN_ARCHITECTURE_GUIDE.md`, `ARCHITECTURE.md`, `SPEC` §4.6/9.
- Entry points: launcher (`capture_core/ui/capture_launcher_screen.dart`), photo (`capture_modes/photo/`), scan (`capture_modes/document_scan/`), voice (`capture_modes/voice/`); UI samples in `UI Design Samples/`.

## Validation per Task
1) `flutter analyze` clean. 2) Relevant `flutter test test/features/capture_*`. 3) Manual Android check + log in TESTING.md. 4) Update completion count.

## Pitfalls
- Modes must use capture storage ports (no direct `AttachmentsStorage`).
- Keep business logic in use cases/presenters, not widgets.
- Honor camera/mic permissions/consent; preserve originals before AI.
- Avoid hard-coded strings; prep for localization.

## MVP Scope (ship)
- Capture launcher + unified review.
- Photo capture with clarity/retake prompts.
- Document scan with multi-page + enhancement/clarity prompts.
- Voice dictation with transcription + manual edit.
- Keyboard entry improvements.
- File upload (PDF/images) — completed.
- Email import (Gmail label) path + metadata transparency.
- Accessibility audit and localization prep.

## Tasks (condensed)
- **Core/capture**: controller + registry; storage ports/adapters; review screen; dirty tracking hooks.
- **Photo**: use case + gateway; blur/clarity prompts; metadata tagging; tests.
- **Document scan**: multi-page flow; enhancement; clarity/rescan guidance; tests.
- **Voice**: capture + transcription pipeline; error/retry handling; tests.
- **Keyboard**: form validation/UX tweaks.
- **File upload**: picker/size/type validation; copy to session; metadata; persistence tests (done).
- **Email import**: Gmail label ingest; headers for transparency; parsing; consent copy.
- **Review**: merge artifacts, edit title/type/date/notes/tags; accessible success feedback.
- **Performance**: lazy lists, logging for capture/review performance.
- **Accessibility/localization**: large touch targets, contrast, a11y labels; prep strings for l10n.

## Manual Tests (examples)
- Capture each mode -> review -> save; verify attachments + metadata and record list updates.
- Clarity prompts fire on blurry photos/scans; retake flow works.
- Voice dictation permissions/denial handling; transcription editable.
- File upload size/type errors; original preserved.
- Email import shows source metadata; handles missing auth/label gracefully.
- Review validation; success SnackBar; log entries.

## Completion Tracking
- Update this file + TESTING.md as tasks finish; note analyzer/test/manual runs.
