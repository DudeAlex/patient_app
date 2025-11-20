# Design Document

## Overview

This design adds processing indicator support to the Photo Capture Service by implementing the `onProcessing` callback pattern already used by Document Scan and Voice Capture services. The existing `_ProcessingOverlay` widget in the Capture Launcher Screen will automatically display when the photo service signals processing state, providing immediate visual feedback during clarity analysis and OCR extraction.

## Architecture

### Current State

The capture system already has:
- `CaptureLauncherPresenter` with a `processing` ValueNotifier
- `_ProcessingOverlay` widget that displays when `processing` is true
- `CaptureContext.onProcessing` callback for modes to signal processing state
- Document Scan Service and Voice Capture Service already using `onProcessing`

### Problem

The Photo Capture Service does NOT call `onProcessing`, so users see:
1. Camera closes
2. Capture launcher visible (confusing - can they tap again?)
3. Delay (1-3 seconds for clarity + OCR)
4. Quality dialog appears (if photo is blurry)

### Solution

Add `onProcessing` calls to Photo Capture Service following the same pattern as Document Scan Service:

```dart
// Before analysis
context.onProcessing?.call(true);

try {
  // Perform clarity analysis
  // Perform OCR extraction
} finally {
  // Always hide processing indicator
  context.onProcessing?.call(false);
}
```

## Components and Interfaces

### Modified Components

#### PhotoCaptureService

**Location:** `lib/features/capture_modes/photo/photo_capture_service.dart`

**Changes:**
- Add `onProcessing?.call(true)` before clarity analysis
- Wrap analysis in try-finally block
- Add `onProcessing?.call(false)` in finally block

**Rationale:** This is the minimal change needed. We signal processing start right before the expensive operations (clarity + OCR) and ensure we signal end even if analysis fails.

### Unchanged Components

- `CaptureLauncherPresenter` - Already has processing state management
- `_ProcessingOverlay` - Already displays correctly when processing is true
- `CaptureContext` - Already has onProcessing callback
- `CapturePhotoUseCase` - No changes needed, it just calls the service

## Data Models

No new data models needed. Using existing:
- `CaptureContext.onProcessing: void Function(bool)?`
- `CaptureLauncherPresenter._processingNotifier: ValueNotifier<bool>`

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Processing indicator visibility during analysis

*For any* photo capture operation, when clarity analysis or OCR extraction is running, the processing indicator should be visible to the user.

**Validates: Requirements 1.2, 1.3, 1.4**

### Property 2: Processing indicator cleanup on completion

*For any* photo capture operation, when the operation completes (successfully or with error), the processing indicator should be hidden.

**Validates: Requirements 1.5, 5.1, 5.2, 5.3, 5.4**

### Property 3: Interaction blocking during processing

*For any* photo capture operation, while the processing indicator is visible, user interactions with the capture launcher should be blocked.

**Validates: Requirements 2.1, 2.2**

### Property 4: Consistent processing pattern across modes

*For any* capture mode (photo, document scan, voice), the processing indicator should be controlled using the same `onProcessing` callback mechanism.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5**

## Error Handling

### Exception During Analysis

**Scenario:** Clarity analyzer throws exception

**Handling:**
- Finally block ensures `onProcessing(false)` is called
- Processing overlay is hidden
- Exception propagates to use case
- User sees error snackbar

**Code Pattern:**
```dart
context.onProcessing?.call(true);
try {
  // Analysis that might throw
} finally {
  context.onProcessing?.call(false);
}
```

### Null Analyzer

**Scenario:** `_clarityAnalyzer` is null (disabled)

**Handling:**
- Still call `onProcessing(true)` before the check
- Skip analysis
- Call `onProcessing(false)` in finally
- Ensures consistent behavior even when analysis is disabled

### OCR Failure

**Scenario:** OCR extraction fails

**Handling:**
- OCR is already wrapped in try-catch in current code
- Our finally block ensures processing indicator is hidden
- OCR failure doesn't prevent photo capture from completing

## Testing Strategy

### Unit Tests

**Test 1: Processing callback invoked**
- Mock `CaptureContext` with `onProcessing` callback
- Call `capturePhoto()`
- Verify `onProcessing(true)` called before analysis
- Verify `onProcessing(false)` called after analysis

**Test 2: Processing callback on error**
- Mock `CaptureContext` with `onProcessing` callback
- Mock analyzer to throw exception
- Call `capturePhoto()`
- Verify `onProcessing(true)` called
- Verify `onProcessing(false)` called in finally
- Verify exception propagates

**Test 3: Processing callback with null analyzer**
- Mock `CaptureContext` with `onProcessing` callback
- Create service with null analyzer
- Call `capturePhoto()`
- Verify `onProcessing(true)` called
- Verify `onProcessing(false)` called
- Verify photo capture completes successfully

**Test 4: Processing callback is optional**
- Create `CaptureContext` with `onProcessing: null`
- Call `capturePhoto()`
- Verify no exception thrown
- Verify photo capture completes successfully

### Integration Tests

**Test 1: UI overlay appears during photo capture**
- Launch capture launcher
- Tap "Take Photo"
- Take photo in camera
- Verify processing overlay appears immediately
- Verify "Checking clarity..." text visible
- Verify overlay disappears when analysis completes

**Test 2: Interaction blocked during processing**
- Launch capture launcher
- Tap "Take Photo"
- Take photo in camera
- While processing overlay visible, attempt to tap launcher buttons
- Verify taps are blocked
- Verify overlay disappears before quality dialog

**Test 3: Consistent behavior across modes**
- Test photo capture shows processing overlay
- Test document scan shows processing overlay
- Test voice capture shows processing overlay
- Verify all use same overlay component
- Verify all block interaction the same way

### Manual Tests

**Test 1: Fast capture (< 100ms)**
- Take photo with good lighting
- Verify processing overlay appears briefly
- Verify no artificial delay added
- Verify smooth transition to next screen

**Test 2: Slow capture (> 1s)**
- Take photo with complex scene (lots of text)
- Verify processing overlay appears immediately
- Verify overlay stays visible during OCR
- Verify "Checking clarity..." message visible throughout

**Test 3: Error during capture**
- Simulate camera error (deny permissions mid-capture)
- Verify processing overlay is hidden
- Verify error message is visible
- Verify can retry capture

**Test 4: Blurry photo flow**
- Take intentionally blurry photo
- Verify processing overlay appears
- Verify overlay disappears before quality dialog
- Verify quality dialog is interactive
- Verify can choose "Retake" or "Keep"

## Implementation Notes

### Placement of onProcessing Calls

The `onProcessing(true)` call should be placed:
- **After** the camera capture completes (XFile is returned)
- **After** the file is stored to disk
- **Before** clarity analysis starts

Rationale:
- Camera UI handles its own loading state
- File storage is fast (< 50ms typically)
- Clarity + OCR is slow (500ms - 3s)
- This matches where users perceive the delay

### Comparison with Document Scan Service

Document Scan Service has TWO processing blocks:
1. During clarity analysis (per page)
2. During enhancement pipeline (all pages)

Photo Capture Service needs ONE processing block:
1. During clarity + OCR analysis

### Comparison with Voice Capture Service

Voice Capture Service has ONE processing block:
1. During transcription

Photo Capture Service follows the same pattern.

### Code Location

The change is isolated to one method:
- `PhotoCaptureService.capturePhoto()`

Approximately 5 lines of code:
- 1 line: `context.onProcessing?.call(true);`
- 1 line: `try {`
- Existing analysis code (unchanged)
- 1 line: `} finally {`
- 1 line: `context.onProcessing?.call(false);`
- 1 line: `}`

### Performance Impact

**None.** The callback is optional and just sets a boolean flag. The ValueNotifier triggers a rebuild of the Stack widget, which is already optimized with a child parameter.

### Backward Compatibility

**Full compatibility.** The `onProcessing` callback is optional (`void Function(bool)?`). Existing code that doesn't provide the callback will continue to work unchanged.

## Alternative Approaches Considered

### Alternative 1: Add loading state to PhotoCaptureService

**Approach:** Add internal state management to the service

**Rejected because:**
- Violates clean architecture (service shouldn't manage UI state)
- Requires new interfaces and state propagation
- Doesn't match existing pattern used by other modes

### Alternative 2: Show processing in CapturePhotoUseCase

**Approach:** Call `onProcessing` in the use case instead of service

**Rejected because:**
- Use case doesn't know when analysis happens
- Service is the right place (it knows when expensive operations occur)
- Doesn't match document scan pattern (which calls in service)

### Alternative 3: Add artificial delay to ensure overlay is visible

**Approach:** Add `await Future.delayed(Duration(milliseconds: 200))` to ensure overlay shows

**Rejected because:**
- Adds unnecessary delay for fast captures
- Violates performance requirements
- User experience should be as fast as possible

## References

- Document Scan Service implementation: `lib/features/capture_modes/document_scan/document_scan_service.dart` (lines 90-95, 160-165)
- Voice Capture Service implementation: `lib/features/capture_modes/voice/voice_capture_service.dart` (lines 71-86)
- Capture Launcher Presenter: `lib/features/capture_core/adapters/presenters/capture_launcher_presenter.dart`
- Processing Overlay: `lib/features/capture_core/ui/capture_launcher_screen.dart` (lines 280-300)
