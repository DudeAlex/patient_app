Status: ACTIVE

# File Upload Attachment Persistence Verification

## Prereqs
- Android device/emulator; PDF + JPEG/PNG (<50 MB); file explorer/adb.

## Scenarios (manual)
- **T1 Copy to session dir**: Upload PDF via Upload File -> check `/data/data/com.example.patient_app/app_flutter/attachments/sessions/<uuid>/file_<ts>_<original>` exists; size matches. Verifies 1.3/5.1/5.3.
- **T2 Original preserved**: After upload, original file still in source folder unchanged. Verifies 5.2.
- **T3 Record links attachment**: Save record (title/type/notes). In Records detail attachment shows; Isar: attachment.recordId matches record id, path matches session file. Verifies 1.4/5.4.
- **T4 Metadata**: Attachment fields: path `sessions/<uuid>/file_<ts>_<name>`, kind pdf/image, mimeType application/pdf or image/jpeg/png, sizeBytes matches, capturedAt/save timestamps, source `file`, metadataJson originalFileName. Verifies 1.3/1.4/5.2/5.4.
- **T5 Multiple uploads**: Upload PDF then JPEG in same session (cancel review between). Both files exist with unique timestamps. Verifies 5.3.
- **T6 Persistence after restart**: Save record + attachment, restart app, record detail still shows attachment; file accessible. Verifies 5.1/5.4.

## Troubleshooting
- Missing session dir: check path `/data/data/com.example.patient_app/app_flutter/attachments/sessions/` and correct UUID.
- Attachment not in detail: ensure UI displays attachments; check logs/Isar links.
- DB query issues: confirm Isar init; inspect logs.

## Test Log Template
- Date/Tester/Device/App Version.
- Table of tests with Pass/Fail and notes; overall result + notes.
