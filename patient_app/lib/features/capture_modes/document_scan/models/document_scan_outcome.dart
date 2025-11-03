import '../../../capture_core/api/capture_artifact.dart';
import '../../../capture_core/api/capture_draft.dart';

/// Outcome of a document scanning session.
class DocumentScanOutcome {
  const DocumentScanOutcome({
    required this.artifacts,
    required this.pageCount,
    this.draft,
    this.metadata = const <String, Object?>{},
  });

  final List<CaptureArtifact> artifacts;
  final int pageCount;
  final CaptureDraft? draft;
  final Map<String, Object?> metadata;
}
