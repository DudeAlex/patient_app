import '../../../capture_core/api/capture_artifact.dart';
import '../../../capture_core/api/capture_draft.dart';

class VoiceCaptureOutcome {
  const VoiceCaptureOutcome({
    required this.artifact,
    this.draft,
  });

  final CaptureArtifact artifact;
  final CaptureDraft? draft;
}
