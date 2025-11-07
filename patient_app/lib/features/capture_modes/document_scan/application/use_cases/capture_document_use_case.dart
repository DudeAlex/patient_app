import '../../../../capture_core/api/capture_mode.dart';
import '../../../../capture_core/api/capture_result.dart';
import '../../models/document_scan_outcome.dart';
import '../ports/document_scan_gateway.dart';

class CaptureDocumentUseCase {
  CaptureDocumentUseCase(this._gateway);

  final DocumentScanGateway _gateway;

  bool get isAvailable => _gateway.isAvailable;

  Future<CaptureResult> execute(CaptureContext context) async {
    final DocumentScanOutcome? outcome =
        await _gateway.captureDocument(context);
    if (outcome == null || outcome.artifacts.isEmpty) {
      return CaptureResult.cancelled;
    }
    return CaptureResult(
      completed: true,
      artifacts: List.unmodifiable(outcome.artifacts),
      draft: outcome.draft,
    );
  }
}
