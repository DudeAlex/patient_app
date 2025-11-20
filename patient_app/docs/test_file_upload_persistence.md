# File Upload Attachment Persistence Verification

## Test Overview
This document provides manual test scenarios to verify that uploaded files are properly persisted with correct metadata and linked to saved records.

## Prerequisites
- App running on Android device or emulator
- Test files available:
  - A PDF file (< 50 MB)
  - A JPEG/PNG image file (< 50 MB)
- Access to device file system for verification (via Android Studio Device File Explorer or adb)

## Test Scenarios

### Test 1: Verify File Copy to Session Directory with Timestamped Name

**Objective**: Confirm uploaded file is copied to session directory with timestamped filename

**Steps**:
1. Launch the app
2. Navigate to capture launcher (+ button)
3. Select "Upload File" option
4. Choose a PDF file from device storage (note the original filename)
5. Before saving the record, use Device File Explorer to navigate to:
   `/data/data/com.example.patient_app/app_flutter/attachments/sessions/`
6. Locate the session directory (UUID format)
7. Verify a file exists with pattern: `file_<timestamp>_<original_filename>`

**Expected Results**:
- ✓ File exists in session directory
- ✓ Filename starts with `file_` followed by millisecond timestamp
- ✓ Original filename is preserved after timestamp
- ✓ File size matches original file

**Requirements Verified**: 1.3, 5.1, 5.3

---

### Test 2: Verify Original File Remains in Source Location

**Objective**: Confirm the original file is not moved or deleted

**Steps**:
1. Note the location of a test file before upload (e.g., Downloads folder)
2. Launch the app and upload the file via "Upload File" mode
3. After upload completes (review screen appears), navigate back to the original file location
4. Verify the original file still exists

**Expected Results**:
- ✓ Original file remains in source location
- ✓ Original file is unchanged (same size, modification date)
- ✓ Upload created a copy, not a move operation

**Requirements Verified**: 5.2

---

### Test 3: Verify Saved Record Links Attachment with Correct RecordId

**Objective**: Confirm attachment is properly linked to the saved record in the database

**Steps**:
1. Upload a file via "Upload File" mode
2. In the review screen, fill in:
   - Title: "Test File Upload Record"
   - Type: "Lab"
   - Notes: "Testing attachment persistence"
3. Click "Save"
4. Wait for success snackbar
5. Navigate to Records list
6. Find and open "Test File Upload Record"
7. Verify the attachment is displayed in the record detail view

**Database Verification** (optional, requires adb):
```bash
# Pull the Isar database
adb pull /data/data/com.example.patient_app/app_flutter/default.isar

# Use Isar Inspector or query tool to verify:
# - Record exists with correct title
# - Attachment exists with recordId matching the record's id
# - Attachment.path matches the relative path from session directory
```

**Expected Results**:
- ✓ Record is saved successfully
- ✓ Attachment appears in record detail view
- ✓ Attachment.recordId matches the saved record's ID
- ✓ Attachment is queryable via record relationship

**Requirements Verified**: 1.4, 5.4

---

### Test 4: Verify Attachment Metadata (Path, MIME Type, Size, Timestamp)

**Objective**: Confirm all attachment metadata fields are populated correctly

**Steps**:
1. Upload a PDF file (note its size in bytes)
2. Complete the review screen and save the record
3. Query the database or use debug logging to inspect the saved Attachment

**Database Query** (via Isar Inspector or adb):
```dart
// Expected Attachment fields:
// - id: auto-generated
// - recordId: matches parent record
// - path: "sessions/<sessionId>/file_<timestamp>_<filename>"
// - kind: "pdf" (for PDF) or "image" (for JPEG/PNG)
// - mimeType: "application/pdf" or "image/jpeg" or "image/png"
// - sizeBytes: matches original file size
// - capturedAt: timestamp when file was uploaded
// - source: "file" (the capture mode id)
// - createdAt: timestamp when attachment was saved
```

**Expected Results**:
- ✓ `path` contains relative path with session directory structure
- ✓ `kind` is "pdf" for PDF files, "image" for JPEG/PNG
- ✓ `mimeType` matches file type ("application/pdf", "image/jpeg", "image/png")
- ✓ `sizeBytes` matches original file size exactly
- ✓ `capturedAt` is set to upload timestamp
- ✓ `source` is "file"
- ✓ `createdAt` is set to save timestamp
- ✓ `metadataJson` contains originalFileName

**Requirements Verified**: 1.3, 1.4, 5.2, 5.4

---

### Test 5: Verify Multiple File Uploads to Same Session

**Objective**: Confirm multiple files can be uploaded in sequence without conflicts

**Steps**:
1. Upload first file (PDF)
2. Note the session directory and filename
3. Cancel the review screen (don't save)
4. Upload second file (JPEG) in the same session
5. Verify both files exist in the session directory with unique timestamped names

**Expected Results**:
- ✓ Both files exist in same session directory
- ✓ Filenames have different timestamps (no collision)
- ✓ Both files are intact and correct size

**Requirements Verified**: 5.3

---

### Test 6: Verify Attachment Persistence After App Restart

**Objective**: Confirm saved attachments survive app restart

**Steps**:
1. Upload and save a file with a record
2. Note the record title
3. Force close the app
4. Restart the app
5. Navigate to Records list
6. Open the saved record
7. Verify the attachment is still present and accessible

**Expected Results**:
- ✓ Record loads successfully after restart
- ✓ Attachment metadata is intact
- ✓ Attachment file is accessible
- ✓ File path resolves correctly

**Requirements Verified**: 5.1, 5.4

---

## Verification Checklist

After completing all tests, verify:

- [ ] Files are copied to session directory with timestamped names (Test 1)
- [ ] Original files remain in source location (Test 2)
- [ ] Attachments are linked to records with correct recordId (Test 3)
- [ ] All metadata fields are populated correctly (Test 4)
- [ ] Multiple uploads work without filename conflicts (Test 5)
- [ ] Attachments persist after app restart (Test 6)

## Known Limitations

- Session cleanup: Temporary session directories are not automatically cleaned up if the user cancels before saving. This is consistent with other capture modes and will be addressed in a future cleanup task.
- File preview: The review screen does not show a preview of uploaded files. This is a future enhancement.

## Troubleshooting

**Issue**: Cannot find session directory
- **Solution**: Ensure you're looking in the correct path: `/data/data/com.example.patient_app/app_flutter/attachments/sessions/`
- **Note**: Session ID is a UUID generated when capture starts

**Issue**: Attachment not appearing in record detail
- **Solution**: Verify the record detail screen is implemented to display attachments. Check `RecordDetailScreen` implementation.

**Issue**: Database query fails
- **Solution**: Ensure Isar database is properly initialized. Check app logs for any database errors.

## Test Results

### Test Execution Log

**Date**: _____________
**Tester**: _____________
**Device**: _____________
**App Version**: _____________

| Test | Status | Notes |
|------|--------|-------|
| Test 1: File copy to session directory | ⬜ Pass / ⬜ Fail | |
| Test 2: Original file remains | ⬜ Pass / ⬜ Fail | |
| Test 3: Record links attachment | ⬜ Pass / ⬜ Fail | |
| Test 4: Metadata correctness | ⬜ Pass / ⬜ Fail | |
| Test 5: Multiple uploads | ⬜ Pass / ⬜ Fail | |
| Test 6: Persistence after restart | ⬜ Pass / ⬜ Fail | |

**Overall Result**: ⬜ All Pass / ⬜ Some Failures

**Additional Notes**:
_____________________________________________________________________________
_____________________________________________________________________________
