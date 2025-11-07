import '../../../../capture_core/api/capture_artifact.dart';
import '../../../../capture_core/api/capture_mode.dart';
import '../../../../capture_core/api/capture_result.dart';
import '../../models/photo_capture_outcome.dart';
import '../ports/photo_capture_gateway.dart';

class CapturePhotoUseCase {
  CapturePhotoUseCase(this._gateway);

  final PhotoCaptureGateway _gateway;

  Future<CaptureResult> execute(CaptureContext context) async {
    while (true) {
      final PhotoCaptureOutcome? outcome =
          await _gateway.capturePhoto(context);
      if (outcome == null) {
        return CaptureResult.cancelled;
      }

      var artifact = outcome.artifact;
      final clarity = outcome.clarity;
      var userAcceptedBlurry = false;

      if (clarity != null && clarity.isSharp == false) {
        final promptRetake = context.promptRetake;
        if (promptRetake != null) {
          final retry = await promptRetake(
            'Photo looks blurry',
            clarity.reason ??
                'We detected a low clarity score. Would you like to retake the photo?',
          );
          if (retry) {
            await _gateway.discardArtifacts(<CaptureArtifact>[artifact]);
            continue;
          }
          userAcceptedBlurry = true;
        }

        final metadata = Map<String, Object?>.from(artifact.metadata)
          ..['clarityUserAccepted'] = userAcceptedBlurry;
        artifact = artifact.copyWith(metadata: Map.unmodifiable(metadata));
      }

      return CaptureResult(
        completed: true,
        artifacts: <CaptureArtifact>[artifact],
        draft: outcome.draft,
      );
    }
  }
}
