# File Upload Feature Documentation

## Overview

The File Upload feature allows patients to import existing digital files (PDFs and images) from device storage into their health records. This complements other capture modes (photo, scan, voice) and provides a pathway for importing lab results, medical reports, prescriptions, and other health documents received electronically.

## Features

### Supported File Types
- **PDF** (`.pdf`) - Lab results, medical reports, prescriptions
- **JPEG** (`.jpg`, `.jpeg`) - Photos of documents, insurance cards
- **PNG** (`.png`) - Screenshots, digital documents

### File Size Limit
- Maximum: **50 MB** per file
- User-friendly error message displays actual file size when limit exceeded

### Storage & Privacy
- Files copied to app-private storage: `attachments/sessions/{sessionId}/`
- Original files remain in source location (copy, not move)
- Timestamped filenames prevent conflicts: `file_{timestamp}_{originalName}`
- Local-first architecture: no network transmission

### Metadata Preservation
All uploaded files are saved with complete metadata:
- **Path**: Relative path in attachments directory
- **MIME Type**: Detected from file extension
- **Size**: File size in bytes
- **Timestamps**: Upload time and save time
- **Source**: Capture mode identifier (`file`)
- **Original Filename**: Preserved for reference
- **Record Link**: Foreign key to parent health record

## User Flow

1. **Launch**: Tap "Upload File" in capture launcher
2. **Select**: Choose file from device storage via native picker
3. **Validate**: System checks file type and size
4. **Copy**: File copied to session directory with timestamped name
5. **Review**: Edit record details (title, type, date, notes, tags)
6. **Save**: Record and attachment saved to database

## Error Handling

### User Cancellation
- User dismisses file picker without selection
- Returns to capture launcher without error message

### File Size Exceeded
- Error: "File too large (X MB). Maximum size is 50 MB."
- User can select a different file

### File Access Error
- Error: "Could not access selected file"
- Occurs when file path is inaccessible or permissions denied

### Copy Failure
- Error: "Failed to copy file: {exception details}"
- Occurs when storage is full or permissions issue

## Technical Implementation

### Architecture
```
FileUploadMode (CaptureMode implementation)
  ↓
CaptureFileUseCase (Application layer)
  ↓
FileUploadService (Gateway implementation)
  ↓
file_picker package (Platform integration)
```

### Key Components

**FileUploadMode**
- Implements `CaptureMode` interface
- Provides mode metadata (id, displayName, iconName)
- Delegates to `CaptureFileUseCase`

**CaptureFileUseCase**
- Orchestrates file upload flow
- Creates `CaptureArtifact` with metadata
- Infers artifact type (PDF → documentScan, images → photo)

**FileUploadService**
- Implements `FileUploadGateway` port
- Handles file picker integration
- Validates file size and type
- Copies file to session directory
- Detects MIME type from extension

**FileUploadResult**
- Value object for upload outcomes
- States: success, cancelled, error

### Database Schema

**Attachment Model** (Isar collection)
```dart
@collection
class Attachment {
  Id id = Isar.autoIncrement;
  late int recordId;           // Foreign key to Record
  late String path;            // Relative path
  late String kind;            // "pdf" or "image"
  String? mimeType;            // "application/pdf", "image/jpeg", etc.
  int? sizeBytes;              // File size
  DateTime? capturedAt;        // Upload timestamp
  String? source;              // "file"
  String? metadataJson;        // {"originalFileName": "..."}
  late DateTime createdAt;     // Save timestamp
  
  @Index()
  int get recordIndex => recordId;
}
```

## Platform Support

### Android
- ✅ Fully supported
- Native file picker via `file_picker` package
- Permissions handled automatically

### iOS
- ⚠️ Supported (requires testing)
- Native file picker via `file_picker` package
- May require `NSPhotoLibraryUsageDescription` for photo access

### Web
- ✅ Supported
- Browser file input via `file_picker` package
- Limited to browser-accessible files
- No special permissions required

## Testing

### Manual Test Scenarios
See `test_file_upload_persistence.md` for comprehensive test plan:
1. File copy to session directory
2. Original file preservation
3. Record-attachment linking
4. Metadata completeness
5. Multiple uploads
6. Persistence after restart

### Debug Utility
Run `dart run tool/verify_attachment_persistence.dart` to:
- Inspect database attachments
- Verify file existence
- Check recordId links
- Detect orphaned attachments

### Automated Tests
- `test/features/capture_modes/file/application/capture_file_use_case_test.dart`
- Unit tests for use case, service, and mode components

## Known Limitations

1. **Single File Selection**: Only one file per upload operation
2. **No Preview**: Review screen shows metadata only (no thumbnail/preview)
3. **No Compression**: Large images stored as-is (no automatic compression)
4. **No Duplicate Detection**: User can upload same file multiple times
5. **Session Cleanup**: Temporary files persist if user cancels before save

## Future Enhancements

### Planned
- Multi-file selection (batch upload)
- File preview in review screen (thumbnails for images, first page for PDFs)
- Automatic image compression for large photos
- Duplicate detection based on file hash
- Session cleanup on cancellation

### Under Consideration
- Cloud import (Google Drive, Dropbox)
- OCR for uploaded documents
- PDF optimization
- Video file support
- Compression quality settings

## Requirements Coverage

| Requirement | Status | Notes |
|-------------|--------|-------|
| 1.1 - Display in launcher | ✅ Complete | "Upload File" with upload icon |
| 1.2 - File picker | ✅ Complete | Platform-native picker, filtered types |
| 1.3 - Copy to session directory | ✅ Complete | Timestamped filenames |
| 1.4 - Create attachment | ✅ Complete | Full metadata preservation |
| 1.5 - Navigate to review | ✅ Complete | Unified review flow |
| 2.1 - Accept images | ✅ Complete | JPEG and PNG supported |
| 2.2 - MIME type detection | ✅ Complete | Based on file extension |
| 2.3 - Image artifact type | ✅ Complete | Images → photo type |
| 2.4 - PDF artifact type | ✅ Complete | PDF → documentScan type |
| 3.1 - Size limit | ✅ Complete | 50 MB enforced |
| 3.2 - Size error message | ✅ Complete | Shows actual and max size |
| 3.3 - Return to picker | ✅ Complete | Error returns to launcher |
| 3.4 - Cancellation handling | ✅ Complete | No error on cancel |
| 4.1 - Access error | ✅ Complete | Clear error message |
| 4.2 - Copy error | ✅ Complete | Includes failure reason |
| 4.3 - Preserve original | ✅ Complete | No partial artifacts |
| 4.4 - Retry option | ✅ Complete | Can retry from launcher |
| 5.1 - Private storage | ✅ Complete | App-private directory |
| 5.2 - Preserve original | ✅ Complete | Copy operation |
| 5.3 - Unique filenames | ✅ Complete | Timestamp-based |
| 5.4 - Record linking | ✅ Complete | recordId foreign key |
| 6.1 - Android support | ✅ Complete | Fully functional |
| 6.2 - Web support | ✅ Complete | Browser file input |
| 6.3 - Platform detection | ✅ Complete | Always available (MVP) |
| 6.4 - Platform-appropriate UI | ✅ Complete | Native pickers |

## Related Documentation

- **Requirements**: `.kiro/specs/file-upload-capture/requirements.md`
- **Design**: `.kiro/specs/file-upload-capture/design.md`
- **Tasks**: `.kiro/specs/file-upload-capture/tasks.md`
- **Manual Tests**: `test_file_upload_persistence.md`
- **Verification Report**: `ATTACHMENT_PERSISTENCE_VERIFICATION.md`
- **Testing Log**: `TESTING.md` (search for "File Upload")
- **Milestone Plan**: `M5_MULTI_MODAL_PLAN.md`

## Support

For issues or questions:
1. Check `TROUBLESHOOTING.md` for common problems
2. Review test scenarios in `test_file_upload_persistence.md`
3. Run debug utility: `dart run tool/verify_attachment_persistence.dart`
4. Check app logs for `[FileUpload]` or `[Capture]` tags
