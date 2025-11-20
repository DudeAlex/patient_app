# Design Document

## Overview

The File Upload Capture feature extends the multi-modal capture system to support importing existing digital files (PDFs and images) from device storage. This design follows the established clean architecture patterns used by other capture modes (photo, document scan, voice) and integrates seamlessly with the existing capture launcher and review flow.

The implementation leverages the `file_picker` package for platform-native file selection and reuses the existing attachment storage infrastructure. All business logic resides in use cases and services, with clear separation between domain concerns, application orchestration, and framework-specific adapters.

## Architecture

### Layer Structure

Following the clean architecture dependency rule, the file upload feature is organized into:

```
lib/features/capture_modes/file/
  application/
    ports/
      file_upload_gateway.dart          # Port interface for file operations
    use_cases/
      capture_file_use_case.dart        # Orchestrates file upload flow
  models/
    file_upload_result.dart             # Value object for upload outcomes
  file_upload_service.dart              # Gateway implementation
  file_upload_mode.dart                 # CaptureMode implementation (NEW)
  file_upload_module.dart               # Module registration
```

### Dependencies

- **Inward**: `capture_core` API (CaptureMode, CaptureResult, CaptureArtifact, CaptureContext)
- **External**: `file_picker` package for platform file selection
- **Peer**: None (file upload is independent of other capture modes)

## Components and Interfaces

### 1. FileUploadMode (NEW Component)

**Purpose**: Implements the `CaptureMode` interface to integrate file upload into the capture launcher.

**Responsibilities**:
- Provide mode metadata (id, displayName, iconName)
- Check platform availability
- Delegate capture execution to `CaptureFileUseCase`

**Interface**:
```dart
class FileUploadMode implements CaptureMode {
  FileUploadMode(this._useCase);
  
  final CaptureFileUseCase _useCase;
  
  @override
  String get id => 'file';
  
  @override
  String get displayName => 'Upload File';
  
  @override
  String get iconName => 'upload_file';
  
  @override
  bool isAvailable() => true; // Platform check can be added later
  
  @override
  Future<CaptureResult> startCapture(CaptureContext context) async {
    return _useCase.execute(context.sessionId);
  }
}
```

**Design Decisions**:
- Simple delegation pattern matches photo and voice modes
- `isAvailable()` returns true for MVP; can be enhanced with platform detection
- Uses `context.sessionId` to determine storage path (consistent with other modes)

### 2. CaptureFileUseCase (Existing - Minor Enhancement)

**Current State**: Already implemented with core logic for file selection, validation, and artifact creation.

**Enhancement Needed**: Update signature to accept `CaptureContext` instead of raw `sessionPath` for consistency with other capture modes.

**Updated Interface**:
```dart
class CaptureFileUseCase {
  CaptureFileUseCase(this._gateway);
  
  final FileUploadGateway _gateway;
  
  Future<CaptureResult> execute(CaptureContext context) async {
    final sessionPath = _resolveSessionPath(context.sessionId);
    final uploadResult = await _gateway.pickAndCopyFile(sessionPath);
    
    // Existing logic for result handling and artifact creation
    // ...
  }
  
  String _resolveSessionPath(String sessionId) {
    // Convert sessionId to actual file system path
    // This logic should match other capture modes
  }
}
```

**Alternative**: Keep current signature and let `FileUploadMode` handle path resolution. This maintains simpler use case interface but adds responsibility to the mode.

**Recommendation**: Use alternative approach to minimize changes to existing tested code.

### 3. FileUploadGateway (Existing - No Changes)

**Purpose**: Port interface for file selection and copying operations.

**Current Implementation**: Already complete with `pickAndCopyFile` method.

### 4. FileUploadService (Existing - No Changes)

**Purpose**: Concrete implementation of `FileUploadGateway` using `file_picker` package.

**Current Features**:
- File type filtering (PDF, JPEG, PNG)
- Size validation (50 MB limit)
- MIME type detection
- Timestamped file naming
- Error handling for access and copy failures

**Status**: Implementation is complete and follows clean architecture patterns.

### 5. FileUploadResult (Existing - No Changes)

**Purpose**: Value object representing upload operation outcomes.

**States**:
- Success (with file metadata)
- Cancelled (user dismissed picker)
- Error (with message)

**Status**: Implementation is complete.

### 6. FileUploadModule (Existing - Minor Update)

**Current State**: Module registration structure exists but references missing `FileUploadMode`.

**Required Update**: Import and instantiate `FileUploadMode` with the use case.

```dart
class FileUploadModule implements CaptureModule {
  FileUploadModule({FileUploadService? service})
      : this._(service ?? FileUploadService());

  FileUploadModule._(FileUploadService service)
      : _useCase = CaptureFileUseCase(service);

  final CaptureFileUseCase _useCase;

  @override
  void registerModes(CaptureModeRegistry registry) {
    registry.registerMode(FileUploadMode(_useCase)); // Add this line
  }
}
```

## Data Models

### CaptureArtifact Mapping

File uploads create `CaptureArtifact` instances with type inference:

| File Type | MIME Type | CaptureArtifactType | Display Context |
|-----------|-----------|---------------------|-----------------|
| PDF | application/pdf | documentScan | Groups with scanned documents |
| JPEG/JPG | image/jpeg | photo | Groups with camera photos |
| PNG | image/png | photo | Groups with camera photos |
| Other | application/octet-stream | file | Generic file display |

**Metadata Fields**:
- `id`: Generated as `file_{timestamp}`
- `relativePath`: Timestamped filename in session directory
- `createdAt`: Upload timestamp
- `mimeType`: Detected from file extension
- `sizeBytes`: File size in bytes
- `metadata.originalFileName`: Preserves user's original filename

## Error Handling

### Error Categories

1. **User Cancellation**
   - Trigger: User dismisses file picker without selection
   - Handling: Return `CaptureResult.cancelled()`, navigate back to launcher
   - User Feedback: None (expected behavior)

2. **File Access Errors**
   - Trigger: Selected file path is null or inaccessible
   - Handling: Return `CaptureResult.error("Could not access selected file")`
   - User Feedback: Error snackbar with message, option to retry

3. **File Size Exceeded**
   - Trigger: Selected file > 50 MB
   - Handling: Return `CaptureResult.error("File too large (X MB). Maximum size is 50 MB.")`
   - User Feedback: Error snackbar with specific size, option to retry

4. **Copy Failures**
   - Trigger: IOException during file copy operation
   - Handling: Return `CaptureResult.error("Failed to copy file: {exception}")`
   - User Feedback: Error snackbar with technical details, option to retry

### Error Flow

```
FileUploadMode.startCapture()
  -> CaptureFileUseCase.execute()
    -> FileUploadService.pickAndCopyFile()
      [Error occurs]
      <- FileUploadResult.error(message)
    <- CaptureResult.error(message)
  <- CaptureResult (error state)
[CaptureLauncherScreen catches and displays snackbar]
```

## Testing Strategy

### Unit Tests

1. **FileUploadMode Tests** (NEW)
   - Verify mode metadata (id, displayName, iconName)
   - Verify `isAvailable()` returns true
   - Verify `startCapture()` delegates to use case with correct session path
   - Mock `CaptureFileUseCase` to test result propagation

2. **CaptureFileUseCase Tests** (Existing - Verify Coverage)
   - Success path: valid file creates correct artifact
   - Cancellation: returns cancelled result
   - Size error: returns error with formatted message
   - Access error: returns error with message
   - Copy error: returns error with exception details
   - MIME type inference: PDF -> documentScan, images -> photo

3. **FileUploadService Tests** (Existing - Verify Coverage)
   - File picker integration (mock `FilePicker.platform`)
   - Size validation logic
   - MIME type detection
   - Filename generation with timestamp
   - Error handling for null paths and copy failures

### Integration Tests

1. **Module Registration**
   - Verify `FileUploadModule` registers `FileUploadMode` correctly
   - Verify mode appears in capture launcher when module is loaded

2. **End-to-End Flow** (Manual Testing)
   - Launch capture launcher -> select Upload File
   - Pick PDF -> verify artifact created with documentScan type
   - Pick JPEG -> verify artifact created with photo type
   - Pick large file -> verify size error displayed
   - Cancel picker -> verify return to launcher without error
   - Complete upload -> verify review screen shows file metadata

### Accessibility Testing

1. **Screen Reader**
   - Verify "Upload File" button has proper semantic label
   - Verify file picker is announced correctly
   - Verify error messages are read aloud

2. **Large Text**
   - Verify button text scales appropriately
   - Verify error messages remain readable

3. **High Contrast**
   - Verify upload icon is visible in high contrast mode

## Platform Considerations

### Android
- Uses native file picker via `file_picker` package
- Requires `READ_EXTERNAL_STORAGE` permission (handled by package)
- Session directory: `{appDocumentsDir}/attachments/{sessionId}/`

### Web
- Uses browser file input via `file_picker` package
- No special permissions required
- Session directory: IndexedDB or similar browser storage

### iOS (Future)
- Will use native file picker via `file_picker` package
- May require `NSPhotoLibraryUsageDescription` for photo access
- Session directory: `{appDocumentsDir}/attachments/{sessionId}/`

## Security Considerations

1. **File Validation**
   - Extension-based filtering prevents execution of arbitrary files
   - Size limit prevents storage exhaustion attacks
   - MIME type detection provides additional validation layer

2. **Storage Isolation**
   - Files copied to app-private storage (not shared directories)
   - Original files remain in user's control
   - No network transmission (local-first architecture)

3. **Privacy**
   - No telemetry or analytics on uploaded files
   - File metadata (names, sizes) never leaves device
   - Encryption at rest follows app-wide backup encryption strategy

## Performance Considerations

1. **File Copy Operations**
   - Async copy prevents UI blocking
   - 50 MB limit ensures reasonable copy times
   - Progress indication not required for MVP (copy is fast enough)

2. **Memory Usage**
   - File picker operates on file paths (no in-memory loading)
   - Copy operation streams data (no full file buffering)
   - Artifact metadata is lightweight (< 1 KB per file)

3. **Storage Management**
   - Session directories cleaned up after record save or cancellation
   - Duplicate detection not implemented (user responsibility)
   - Future enhancement: compression for large images

## Future Enhancements

1. **Multi-File Selection**
   - Allow selecting multiple files in one operation
   - Batch validation and copying
   - Progress indicator for multiple files

2. **File Preview**
   - Thumbnail generation for images
   - PDF first-page preview
   - Preview in review screen before save

3. **Advanced Validation**
   - Content-based file type detection (not just extension)
   - Virus scanning integration (if available)
   - Duplicate detection based on hash

4. **Compression**
   - Automatic image compression for large photos
   - PDF optimization
   - User-configurable quality settings

5. **Cloud Import**
   - Direct import from Google Drive
   - Import from other cloud storage providers
   - OAuth-based access (no credential storage)
