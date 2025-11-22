import '../../../../capture_core/api/capture_artifact.dart';
import '../../../../capture_core/api/capture_context_extensions.dart';
import '../../../../capture_core/api/capture_mode.dart';
import '../../../../capture_core/api/capture_result.dart';
import '../../models/photo_capture_outcome.dart';
import '../ports/photo_capture_gateway.dart';

class CapturePhotoUseCase {
  CapturePhotoUseCase(this._gateway);

  final PhotoCaptureGateway _gateway;

  Future<CaptureResult> execute(CaptureContext context) async {
    // Loop allows retaking photo if user chooses "Retake" in quality dialog
    while (true) {
      // Step 1: Capture photo and analyze it
      // This calls PhotoCaptureService which:
      // - Opens camera
      // - Stores photo
      // - Waits for screen to settle
      // - Shows processing overlay
      // - Analyzes clarity
      // - Extracts OCR text
      // - Returns WITHOUT hiding overlay
      final PhotoCaptureOutcome? outcome =
          await _gateway.capturePhoto(context);
      if (outcome == null) {
        return CaptureResult.cancelled;
      }

      var artifact = outcome.artifact;
      final clarity = outcome.clarity;
      var userAcceptedBlurry = false;

      // Step 2: Decide if we need to show quality dialog
      // Show dialog if:
      // - Photo was analyzed (clarity != null)
      // - Photo is blurry (isSharp == false)
      // - Dialog callback is available (promptRetake != null)
      final needsQualityDialog =
          clarity != null && clarity.isSharp == false && context.promptRetake != null;

      if (needsQualityDialog) {
        // Step 3a: Photo is blurry - show quality dialog
        
        // Hide processing overlay before showing dialog
        // This prevents overlay and dialog from appearing at the same time
        context.onProcessing?.call(false);
        
        // Show quality dialog and wait for user response
        final retry = await context.promptRetake!(
          'Photo looks blurry',
          clarity!.reason ??
              'We detected a low clarity score. Would you like to retake the photo?',
        );

        if (retry) {
          // User chose "Retake" - discard photo and loop back to capture again
          await _gateway.discardArtifacts(<CaptureArtifact>[artifact]);
          continue;
        }
        
        // User chose "Keep" - mark that they accepted the blurry photo
        userAcceptedBlurry = true;

        final metadata = Map<String, Object?>.from(artifact.metadata)
          ..['clarityUserAccepted'] = userAcceptedBlurry;
        artifact = artifact.copyWith(metadata: Map.unmodifiable(metadata));
      } else {
        // Step 3b: Photo is good (or no analyzer) - no dialog needed
        
        // Hide processing overlay since we're proceeding to review
        context.onProcessing?.call(false);
        
        // If photo was blurry but no dialog callback available,
        // still update metadata
        if (clarity != null && clarity.isSharp == false) {
          final metadata = Map<String, Object?>.from(artifact.metadata)
            ..['clarityUserAccepted'] = userAcceptedBlurry;
          artifact = artifact.copyWith(metadata: Map.unmodifiable(metadata));
        }
      }

      // Step 4: Return result to proceed to review screen
      return CaptureResult(
        completed: true,
        artifacts: <CaptureArtifact>[artifact],
        draft: outcome.draft,
      );
    }
  }
}
