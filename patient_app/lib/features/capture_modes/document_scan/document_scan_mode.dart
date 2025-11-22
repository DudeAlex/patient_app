import '../../capture_core/api/capture_draft.dart';
import '../../capture_core/api/capture_mode.dart';
import '../../capture_core/api/capture_result.dart';

import 'application/use_cases/capture_document_use_case.dart';

class DocumentScanMode implements CaptureMode {
  DocumentScanMode(this._useCase);

  final CaptureDocumentUseCase _useCase;

  @override
  String get id => 'documentScan';

  @override
  String get displayName => 'Scan Document';

  @override
  String get iconName => 'document_scanner';

  @override
  bool isAvailable() => _useCase.isAvailable;

  @override
  Future<CaptureResult> startCapture(CaptureContext context) async {
    final result = await _useCase.execute(context);
    if (!result.completed) {
      return CaptureResult.cancelled;
    }
    if (result.draft != null) {
      return result;
    }
    return result.copyWith(
      draft: const CaptureDraft(
        suggestedTags: {'scan', 'document'},
      ),
    );
  }
}
