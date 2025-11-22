# Implementation Plan

- [x] 1. Add processing indicator to PhotoCaptureService



  - Open `lib/features/capture_modes/photo/photo_capture_service.dart`
  - Locate the `capturePhoto()` method
  - Find where clarity analysis begins (after file storage, before `analyzer.analyze()`)
  - Add `context.onProcessing?.call(true);` before the clarity analysis block
  - Wrap the clarity + OCR analysis section in a try-finally block
  - Add `context.onProcessing?.call(false);` in the finally block
  - Ensure the finally block executes even if analysis throws an exception
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 3.1, 3.2, 3.3, 5.1, 5.2, 5.3, 5.4_

- [ ]* 2. Write unit tests for processing callback
  - [ ]* 2.1 Test processing callback is invoked during analysis
    - Create test file or add to existing `photo_capture_service_test.dart`
    - Mock `CaptureContext` with `onProcessing` callback that records calls
    - Mock `PhotoClarityAnalyzer` to return a result
    - Call `capturePhoto()`
    - Verify `onProcessing(true)` was called before analysis
    - Verify `onProcessing(false)` was called after analysis
    - Verify calls happened in correct order
    - _Requirements: 3.1, 3.2, 3.3_

  - [ ]* 2.2 Test processing callback on analyzer exception
    - Mock `CaptureContext` with `onProcessing` callback
    - Mock `PhotoClarityAnalyzer` to throw exception
    - Call `capturePhoto()` and expect exception
    - Verify `onProcessing(true)` was called
    - Verify `onProcessing(false)` was called in finally
    - Verify exception propagated correctly
    - _Requirements: 3.3, 5.1, 5.2, 5.3, 5.4_

  - [ ]* 2.3 Test processing callback with null analyzer
    - Mock `CaptureContext` with `onProcessing` callback
    - Create `PhotoCaptureService` with `clarityAnalyzer: null`
    - Call `capturePhoto()`
    - Verify `onProcessing(true)` was called
    - Verify `onProcessing(false)` was called
    - Verify photo capture completed successfully
    - _Requirements: 3.1, 3.2, 3.3, 4.5_

  - [ ]* 2.4 Test processing callback is optional
    - Create `CaptureContext` with `onProcessing: null`
    - Call `capturePhoto()`
    - Verify no exception thrown
    - Verify photo capture completes successfully
    - _Requirements: 3.5_

- [ ] 3. Manual testing and verification
  - [ ] 3.1 Test processing overlay appears immediately
    - Clear app data and launch app
    - Navigate to capture launcher
    - Tap "Take Photo"
    - Take a photo
    - Verify processing overlay appears immediately after camera closes
    - Verify "Checking clarity..." text is visible
    - Verify overlay has semi-transparent black background
    - Verify loading spinner is visible
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.3, 2.4, 2.5_

  - [ ] 3.2 Test interaction is blocked during processing
    - Take a photo
    - While processing overlay is visible, try to tap capture mode buttons
    - Verify taps are blocked (no response)
    - Verify cannot navigate away
    - Verify overlay disappears before quality dialog (if photo is blurry)
    - _Requirements: 2.1, 2.2, 1.5_

  - [ ] 3.3 Test fast capture scenario
    - Take photo in good lighting (should be fast)
    - Verify processing overlay still appears briefly
    - Verify no artificial delay
    - Verify smooth transition to next screen
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

  - [ ] 3.4 Test slow capture scenario
    - Take photo of document with lots of text (OCR takes longer)
    - Verify processing overlay appears immediately
    - Verify overlay stays visible during entire analysis
    - Verify "Checking clarity..." message visible throughout
    - _Requirements: 4.2, 1.2, 1.3, 1.4_

  - [ ] 3.5 Test error handling
    - Simulate camera error (if possible)
    - Verify processing overlay is hidden on error
    - Verify error message is visible and interactive
    - Verify can retry capture
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

  - [ ] 3.6 Test blurry photo flow
    - Take intentionally blurry photo
    - Verify processing overlay appears
    - Verify overlay disappears before quality dialog
    - Verify quality dialog is interactive
    - Verify can choose "Retake" or "Keep"
    - _Requirements: 1.5, 2.1, 2.2_

  - [ ] 3.7 Test consistency with other modes
    - Test document scan mode shows processing overlay
    - Test voice capture mode shows processing overlay
    - Verify all modes use same overlay appearance
    - Verify all modes block interaction the same way
    - _Requirements: 3.4, 3.5_

- [ ] 4. Update documentation
  - Update `TESTING.md` with manual test results
  - Add note about processing indicator to photo capture documentation (if exists)
  - Update `KNOWN_ISSUES_AND_FIXES.md` to mark this issue as resolved
  - _Requirements: All_

## Implementation Notes

### Code Change Location

The change is in one file: `lib/features/capture_modes/photo/photo_capture_service.dart`

The specific method: `capturePhoto()`

### Expected Code Structure

```dart
Future<PhotoCaptureOutcome?> capturePhoto(CaptureContext context) async {
  try {
    // 1. Camera capture (existing code)
    final xfile = await _picker.pickImage(...);
    if (xfile == null) return null;

    // 2. File storage (existing code)
    final relativePath = await _storeOnDevice(...);
    final savedFile = await _storage.resolveRelativePath(relativePath);
    final stat = await savedFile.stat();

    // 3. START PROCESSING INDICATOR (NEW)
    context.onProcessing?.call(true);
    
    try {
      // 4. Clarity analysis (existing code)
      PhotoClarityResult? clarityResult;
      final analyzer = _clarityAnalyzer;
      if (analyzer != null) {
        clarityResult = await analyzer.analyze(savedFile);
      }

      // 5. OCR extraction (existing code)
      final ocrText = await _ocrExtractor.extract(savedFile);

      // ... rest of existing code ...
      
    } finally {
      // 6. STOP PROCESSING INDICATOR (NEW)
      context.onProcessing?.call(false);
    }

    // 7. Return outcome (existing code)
    return PhotoCaptureOutcome(...);
    
  } on Exception catch (e, st) {
    // Error handling (existing code)
    debugPrint('Photo capture failed: $e\n$st');
    throw PhotoCaptureException('Camera capture failed. Please try again.');
  }
}
```

### Key Points

1. **Placement:** Call `onProcessing(true)` AFTER file storage, BEFORE analysis
2. **Try-Finally:** Wrap analysis in try-finally to ensure cleanup
3. **Optional Callback:** Use `?.call()` since callback is optional
4. **No Artificial Delay:** Don't add delays, let it be as fast as possible
5. **Match Pattern:** Follow same pattern as document_scan_service.dart

### Testing Priority

1. **Manual testing (Task 3)** - Most important to verify user experience
2. **Unit tests (Task 2)** - Optional but recommended for regression prevention

### Estimated Effort

- Task 1: 10 minutes (5 lines of code)
- Task 2: 30 minutes (if writing tests)
- Task 3: 15 minutes (manual testing)
- Task 4: 5 minutes (documentation)

**Total: ~1 hour including testing**

## Dependencies

- No external dependencies
- No changes to other files required
- Uses existing `CaptureContext.onProcessing` callback
- Uses existing `_ProcessingOverlay` widget

## Risks

**Low Risk Change:**
- Minimal code change (5 lines)
- Uses existing, tested infrastructure
- Callback is optional (backward compatible)
- Easy to verify manually
- Easy to rollback if needed

## Success Criteria

✅ Processing overlay appears immediately after photo capture
✅ "Checking clarity..." message is visible during analysis
✅ User cannot interact with launcher during processing
✅ Overlay disappears before quality dialog
✅ No artificial delays added
✅ Error handling works correctly
✅ Consistent with document scan and voice capture modes
