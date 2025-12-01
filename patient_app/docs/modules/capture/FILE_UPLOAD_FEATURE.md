Status: ACTIVE

# File Upload Feature

## Overview
- Import PDFs/images from device storage into records; complements photo/scan/voice capture. Local-only copy; originals unchanged.

## Support & Limits
- Types: PDF, JPEG/JPG, PNG.
- Max size: 50 MB; friendly error with actual size.

## Storage & Metadata
- Copy to `attachments/sessions/{sessionId}/` with timestamped filename.
- Metadata: path, mime/type, size, timestamps, source=`file`, original filename, record link.

## Flow
1) Launch from capture launcher ("Upload File").  
2) Pick file (native picker).  
3) Validate type/size.  
4) Copy to session dir; infer artifact type (PDF -> documentScan, images -> photo).  
5) Review/edit record; save record + attachment.

## Errors
- Cancel: return silently.
- Size error: "File too large (X MB). Maximum 50 MB."
- Access/copy errors: clear message; allow retry from launcher.

## Architecture
```
FileUploadMode (CaptureMode)
 -> CaptureFileUseCase
 -> FileUploadService (gateway) -> file_picker
```
- Use case creates `CaptureArtifact`; gateway validates, copies, detects MIME.
- `FileUploadResult`: success/cancel/error.

## Attachment Schema (Isar)
- id (auto), recordId (FK), path, kind ("pdf"/"image"), mimeType, sizeBytes, capturedAt, source ("file"), metadataJson (originalFileName), createdAt; index on recordId.

## Platform
- Android/iOS/Web supported via `file_picker`; iOS may need `NSPhotoLibraryUsageDescription`.

## Testing
- Manual: copy/preserve originals, metadata completeness, multi-upload, persistence after restart (see `test_file_upload_persistence.md`).
- Automated: `capture_file_use_case_test.dart` etc.
- Debug: `dart run tool/verify_attachment_persistence.dart`.

## Limitations / Future
- Single file per upload; no preview/dup detection/compression; session temp files may persist on cancel.
- Future: multi-select, previews, compression, duplicate detection, cleanup, cloud import, OCR, video support.
