import '../../../../capture_core/api/capture_mode.dart';
import '../../models/document_scan_outcome.dart';

abstract class DocumentScanGateway {
  bool get isAvailable;

  Future<DocumentScanOutcome?> captureDocument(CaptureContext context);
}
