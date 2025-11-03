import '../../capture_core/api/capture_module.dart';

import 'document_scan_mode.dart';
import 'document_scan_service.dart';

class DocumentScanModule implements CaptureModule {
  DocumentScanModule({DocumentScanService? service})
    : _service = service ?? DocumentScanService();

  final DocumentScanService _service;

  @override
  void registerModes(CaptureModeRegistry registry) {
    registry.registerMode(DocumentScanMode(_service));
  }
}
