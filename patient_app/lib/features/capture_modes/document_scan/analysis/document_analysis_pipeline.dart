import '../../../capture_core/api/capture_artifact.dart';
import '../../../capture_core/api/capture_draft.dart';

/// Immutable description of a captured page handed to the analysis pipeline.
class DocumentAnalysisPage {
  const DocumentAnalysisPage({
    required this.index,
    required this.original,
    required this.enhanced,
  });

  /// Zero-based index of the page within the scan session.
  final int index;

  /// Raw capture artefact.
  final CaptureArtifact original;

  /// Enhanced artefact (grayscale/contrast tweaked).
  final CaptureArtifact enhanced;
}

/// Request payload emitted after the scan session completes.
class DocumentAnalysisRequest {
  const DocumentAnalysisRequest({
    required this.sessionId,
    required this.localeTag,
    required this.pages,
  });

  final String sessionId;
  final String localeTag;
  final List<DocumentAnalysisPage> pages;
}

/// Result returned by the analysis pipeline.
class DocumentAnalysisResult {
  const DocumentAnalysisResult({
    this.draft,
    this.metadata = const <String, Object?>{},
  });

  final CaptureDraft? draft;
  final Map<String, Object?> metadata;
}

/// Contract for plugging OCR/LLM powered post-processing into scan flows.
abstract class DocumentAnalysisPipeline {
  Future<DocumentAnalysisResult> analyze(DocumentAnalysisRequest request);
}

/// Minimal placeholder pipeline that surfaces structured metadata for testing.
class StubDocumentAnalysisPipeline implements DocumentAnalysisPipeline {
  const StubDocumentAnalysisPipeline();

  @override
  Future<DocumentAnalysisResult> analyze(DocumentAnalysisRequest request) async {
    final pageCount = request.pages.length;
    final draft = CaptureDraft(
      suggestedDetails:
          'Auto-generated summary pending review. Captured $pageCount page${pageCount == 1 ? '' : 's'}.',
      suggestedTags: {'scan', 'analysis'},
    );
    return DocumentAnalysisResult(
      draft: draft,
      metadata: {
        'analysis': 'stub',
        'pageCount': pageCount,
        'locale': request.localeTag,
      },
    );
  }
}
