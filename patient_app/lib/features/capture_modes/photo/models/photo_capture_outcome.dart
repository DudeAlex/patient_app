import '../../../capture_core/api/capture_artifact.dart';
import '../../../capture_core/api/capture_draft.dart';
import '../analysis/photo_clarity_analyzer.dart';

class PhotoCaptureOutcome {
  PhotoCaptureOutcome({required this.artifact, this.draft, this.clarity});

  final CaptureArtifact artifact;
  final CaptureDraft? draft;
  final PhotoClarityResult? clarity;
}
