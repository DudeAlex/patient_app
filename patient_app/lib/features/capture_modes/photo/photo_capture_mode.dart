import '../../capture_core/api/capture_mode.dart';
import '../../capture_core/api/capture_result.dart';
import 'models/photo_capture_outcome.dart';

import 'photo_capture_service.dart';

class PhotoCaptureMode implements CaptureMode {
  PhotoCaptureMode(this._service);

  final PhotoCaptureService _service;

  @override
  String get id => 'photo';

  @override
  String get displayName => 'Take Photo';

  @override
  String get iconName => 'camera_alt';

  @override
  bool isAvailable() => true;

  @override
  Future<CaptureResult> startCapture(CaptureContext context) async {
    while (true) {
      final PhotoCaptureOutcome? outcome = await _service.capturePhoto(context);
      if (outcome == null) {
        return CaptureResult.cancelled;
      }

      var artifact = outcome.artifact;
      final clarity = outcome.clarity;
      var userAcceptedBlurry = false;

      if (clarity != null && clarity.isSharp == false) {
        if (context.promptRetake != null) {
          final retry = await context.promptRetake!(
            'Photo looks blurry',
            clarity.reason ??
                'We detected a low clarity score. Would you like to retake the photo?',
          );
          if (retry) {
            await _service.discardArtifacts([artifact]);
            continue;
          } else {
            userAcceptedBlurry = true;
          }
        }
      }

      final metadata = Map<String, Object?>.from(artifact.metadata);
      if (clarity != null && clarity.isSharp == false) {
        metadata['clarityUserAccepted'] = userAcceptedBlurry;
      }
      artifact = artifact.copyWith(metadata: Map.unmodifiable(metadata));

      return CaptureResult(
        completed: true,
        artifacts: [artifact],
        draft: outcome.draft,
      );
    }
  }
}
