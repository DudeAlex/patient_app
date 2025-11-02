import 'capture_artifact.dart';
import 'capture_draft.dart';

/// Outcome returned by a capture mode once the flow completes or is cancelled.
class CaptureResult {
  const CaptureResult({
    required this.completed,
    this.draft,
    this.artifacts = const <CaptureArtifact>[],
  });

  /// Whether the patient completed the flow (false = cancelled/aborted).
  final bool completed;

  /// Optional draft data (pre-filled title/notes/tags).
  final CaptureDraft? draft;

  /// Artefacts produced by the capture flow.
  final List<CaptureArtifact> artifacts;

  static const CaptureResult cancelled = CaptureResult(completed: false);

  CaptureResult copyWith({
    bool? completed,
    CaptureDraft? draft,
    List<CaptureArtifact>? artifacts,
  }) {
    return CaptureResult(
      completed: completed ?? this.completed,
      draft: draft ?? this.draft,
      artifacts: artifacts ?? this.artifacts,
    );
  }
}
