import '../../capture_core/api/capture_module.dart';

import 'analysis/document_analysis_pipeline.dart';
import 'analysis/document_clarity_analyzer.dart';
import 'application/use_cases/capture_document_use_case.dart';
import 'document_scan_mode.dart';
import 'document_scan_service.dart';

class DocumentScanModule implements CaptureModule {
  DocumentScanModule({DocumentScanService? service})
    : _service = service ??
            DocumentScanService(
              clarityAnalyzer: LaplacianDocumentClarityAnalyzer(),
              analysisPipeline: const StubDocumentAnalysisPipeline(),
            );

  final DocumentScanService _service;

  @override
  void registerModes(CaptureModeRegistry registry) {
    registry.registerMode(
      DocumentScanMode(CaptureDocumentUseCase(_service)),
    );
  }
}
