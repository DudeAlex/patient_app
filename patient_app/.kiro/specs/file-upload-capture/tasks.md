# Implementation Plan

- [x] 1. Create FileUploadMode implementation












  - Implement `CaptureMode` interface with id='file', displayName='Upload File', iconName='upload_file'
  - Add `isAvailable()` method returning true for MVP
  - Implement `startCapture()` to delegate to `CaptureFileUseCase` with session path resolution
  - _Requirements: 1.1, 6.1, 6.2, 6.3, 6.4_

- [x] 2. Update FileUploadModule to register the mode




  - Import `FileUploadMode` class
  - Instantiate `FileUploadMode` with the existing `CaptureFileUseCase`
  - Register mode in `registerModes()` method
  - _Requirements: 1.1_

- [x] 3. Verify session path resolution logic





  - Review how other capture modes (photo, voice) resolve session paths from `CaptureContext.sessionId`
  - Implement consistent path resolution in `FileUploadMode.startCapture()`
  - Ensure session directory structure matches existing capture modes
  - _Requirements: 5.1, 5.3_

- [x] 4. Wire FileUploadModule into the app





  - Locate where capture modules are registered (likely in main app initialization or capture controller setup)
  - Add `FileUploadModule()` to the module registry
  - Verify the Upload File option appears in the capture launcher
  - _Requirements: 1.1_

- [x] 5. Verify error handling integration





  - Test file picker cancellation returns to launcher without error
  - Test file size exceeded shows appropriate error message
  - Test file access errors display user-friendly messages
  - Test copy failures provide actionable feedback
  - _Requirements: 3.1, 3.2, 3.3, 4.1, 4.2, 4.3, 4.4_

- [x] 6. Verify artifact type mapping






  - Test PDF upload creates artifact with type `documentScan`
  - Test JPEG upload creates artifact with type `photo`
  - Test PNG upload creates artifact with type `photo`
  - Verify artifacts appear correctly in review screen
  - _Requirements: 2.2, 2.3, 2.4_

- [x] 7. Verify attachment persistence








  - Test uploaded file is copied to session directory with timestamped name
  - Test original file remains in source location
  - Test saved record links attachment with correct recordId
  - Test attachment metadata includes path, MIME type, size, and timestamp
  - _Requirements: 1.3, 1.4, 5.2, 5.4_

- [x]* 8. Write unit tests for FileUploadMode



  - Test mode metadata properties (id, displayName, iconName)
  - Test `isAvailable()` returns true
  - Test `startCapture()` calls use case with correct session path
  - Mock `CaptureFileUseCase` to verify result propagation
  - _Requirements: 1.1, 6.1, 6.2, 6.3, 6.4_

- [x]* 9. Verify existing test coverage



  - Review `CaptureFileUseCase` tests for completeness
  - Review `FileUploadService` tests for completeness
  - Add missing test cases if gaps are identified
  - _Requirements: 2.1, 2.2, 3.1, 4.1, 4.2, 4.3_

- [ ]* 10. Perform accessibility audit
  - Test with screen reader (TalkBack on Android, VoiceOver on iOS)
  - Test with large text size settings
  - Test with high contrast mode
  - Verify error messages are announced properly
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [x] 11. Update documentation



  - Add file upload capability to README.md feature list
  - Update M5_MULTI_MODAL_PLAN.md to mark file upload tasks complete
  - Add manual test scenarios to TESTING.md
  - Document any platform-specific limitations discovered
  - _Requirements: All_
