import '../../api/capture_artifact.dart';
import '../../api/capture_mode.dart';
import '../../api/capture_result.dart';

class CaptureReviewViewModel {
  const CaptureReviewViewModel({
    required this.title,
    required this.details,
    required this.tagsDescription,
    required this.artifacts,
    required this.hasDraft,
  });

  final String title;
  final String details;
  final String tagsDescription;
  final bool hasDraft;
  final List<CaptureArtifactViewModel> artifacts;
}

class CaptureArtifactViewModel {
  const CaptureArtifactViewModel({
    required this.kindLabel,
    required this.pathLabel,
    required this.metadataLabel,
    required this.hasMetadata,
  });

  final String kindLabel;
  final String pathLabel;
  final String metadataLabel;
  final bool hasMetadata;
}

class CaptureReviewPresenter {
  CaptureReviewPresenter({
    required this.mode,
    required this.result,
  });

  final CaptureMode mode;
  final CaptureResult result;

  CaptureReviewViewModel buildViewModel() {
    final draft = result.draft;
    final details = draft?.suggestedDetails?.trim();
    final tags = draft?.suggestedTags ?? const <String>{};
    return CaptureReviewViewModel(
      title: 'Review ${mode.displayName}',
      details: (details == null || details.isEmpty)
          ? 'No details suggested yet.'
          : details,
      tagsDescription: tags.isEmpty ? 'No tags suggested yet.' : tags.join(', '),
      hasDraft: draft != null,
      artifacts: result.artifacts.map(_artifactToViewModel).toList(
            growable: false,
          ),
    );
  }

  CaptureArtifactViewModel _artifactToViewModel(CaptureArtifact artifact) {
    final metadata = artifact.metadata;
    final hasMetadata = metadata.isNotEmpty;
    final metadataLabel =
        hasMetadata ? 'Metadata: $metadata' : 'Metadata: none recorded.';
    return CaptureArtifactViewModel(
      kindLabel: artifact.type.name,
      pathLabel: 'Stored at: ${artifact.relativePath}',
      metadataLabel: metadataLabel,
      hasMetadata: hasMetadata,
    );
  }
}
