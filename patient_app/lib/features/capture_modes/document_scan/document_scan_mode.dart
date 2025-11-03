import '../../capture_core/api/capture_mode.dart';
import '../../capture_core/api/capture_result.dart';
import '../../capture_core/api/capture_draft.dart';

import 'document_scan_service.dart';
import 'models/document_scan_outcome.dart';

class DocumentScanMode implements CaptureMode {
  DocumentScanMode(this._service);

  final DocumentScanService _service;

  @override
  String get id => 'documentScan';

  @override
  String get displayName => 'Scan Document';

  @override
  String get iconName => 'document_scanner';

  @override
  bool isAvailable() => _service.isAvailable;

  @override
  Future<CaptureResult> startCapture(CaptureContext context) async {
    final DocumentScanOutcome? outcome = await _service.captureDocument(context);
    if (outcome == null || outcome.artifacts.isEmpty) {
      return CaptureResult.cancelled;
    }

    return CaptureResult(
      completed: true,
      artifacts: List.unmodifiable(outcome.artifacts),
      draft: outcome.draft ??
          const CaptureDraft(
            suggestedTags: {'scan', 'document'},
          ),
    );
  }
}
