import 'capture_mode.dart';

/// Extensions for CaptureContext to handle common processing overlay patterns.
extension CaptureContextProcessingExtensions on CaptureContext {
  /// Hides the processing overlay with a delay to ensure smooth transition.
  /// 
  /// This method ensures the processing overlay is fully visible and rendered
  /// before hiding it. This prevents weird flashing or partial rendering issues
  /// when transitioning from the processing overlay to a dialog.
  /// 
  /// Use this before showing quality dialogs or other UI that should appear
  /// after processing completes.
  /// 
  /// Example:
  /// ```dart
  /// // Analysis complete, prepare to show dialog
  /// await context.hideProcessingOverlayWithDelay();
  /// 
  /// // Now show dialog
  /// final retry = await context.promptRetake!('Photo looks blurry', '...');
  /// ```
  Future<void> hideProcessingOverlayWithDelay({
    Duration delay = const Duration(milliseconds: 3000),
  }) async {
    // Wait for processing overlay to be fully visible and rendered
    // This ensures users see the complete "Checking clarity..." message
    // and prevents weird transitions where the capture launcher is
    // briefly visible between the overlay disappearing and dialog appearing
    await Future.delayed(delay);
    
    // Hide the processing overlay
    onProcessing?.call(false);
  }
  
  /// Shows the processing overlay.
  /// 
  /// This is a convenience method that wraps the onProcessing callback.
  /// Use this at the start of long-running operations like clarity analysis.
  /// 
  /// Example:
  /// ```dart
  /// // Start analysis
  /// context.showProcessingOverlay();
  /// final result = await analyzer.analyze(file);
  /// ```
  void showProcessingOverlay() {
    onProcessing?.call(true);
  }
}
