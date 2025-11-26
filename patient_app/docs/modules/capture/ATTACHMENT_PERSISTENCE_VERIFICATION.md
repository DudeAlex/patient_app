Status: ACTIVE

# Attachment Persistence Verification (File Upload)

## Purpose
Verify requirements 1.3, 1.4, 5.2, 5.4 for file upload persistence.

## Evidence Summary
- **Timestamped copy (1.3/5.1/5.3)**: `FileUploadService.pickAndCopyFile` generates `file_<ts>_<name>`, allocates via `CaptureArtifactStorage`, copies with `File.copy` to `attachments/sessions/<sessionId>/...`.
- **Original preserved (5.2)**: uses `copy()` (not move); source untouched.
- **Record linkage (1.4/5.4)**: `CaptureReviewScreen._saveAttachments` maps `CaptureArtifact` to `Attachment` with `recordId`, `path`, `kind`, `mimeType`, `sizeBytes`, `capturedAt`, `source`, `metadataJson`, `createdAt`; saved after record creation.
- **Metadata completeness (1.4/5.4)**: `CaptureFileUseCase` sets relativePath, mimeType (pdf/image), sizeBytes, createdAt, originalFileName metadata; `_inferArtifactType` maps pdf->documentScan, images->photo; `_mapArtifactTypeToKind` maps to attachment kind.
- **Path structure**: `{appDocs}/attachments/sessions/<sessionId>/file_<ts>_<original>`.

## Manual Tests to Run
- See `test_file_upload_persistence.md` (copy to session, original preserved, record link, metadata correctness, multi-upload, restart persistence).
- Use `tool/verify_attachment_persistence.dart` to inspect DB/files; log results in TESTING.md.

## Improvement Ideas
- Cleanup abandoned session dirs, add previews/duplicate detection/compression; keep parity with other capture modes.

## References
- Requirements/design/tasks under `.kiro/specs/file-upload-capture/*`
- Manual tests: `test_file_upload_persistence.md`
- Debug utility: `tool/verify_attachment_persistence.dart`
