import '../../../../capture_core/api/capture_artifact.dart';
import '../../../../capture_core/api/capture_draft.dart';
import '../../../../capture_core/api/capture_mode.dart';
import '../../../../capture_core/api/capture_result.dart';
import '../../models/voice_capture_outcome.dart';
import '../ports/voice_capture_gateway.dart';

class CaptureVoiceUseCase {
  CaptureVoiceUseCase(this._gateway);

  final VoiceCaptureGateway _gateway;

  Future<CaptureResult> execute(CaptureContext context) async {
    final VoiceCaptureOutcome? outcome =
        await _gateway.captureVoice(context);
    if (outcome == null) {
      return CaptureResult.cancelled;
    }
    return CaptureResult(
      completed: true,
      artifacts: <CaptureArtifact>[outcome.artifact],
      draft: outcome.draft ??
          const CaptureDraft(
            suggestedTags: {'voice'},
          ),
    );
  }
}
