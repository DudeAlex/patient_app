import '../../capture_core/api/capture_module.dart';

import 'analysis/photo_clarity_analyzer.dart';
import 'analysis/photo_ocr_extractor.dart';
import 'photo_capture_mode.dart';
import 'photo_capture_service.dart';

class PhotoCaptureModule implements CaptureModule {
  PhotoCaptureModule({PhotoCaptureService? service})
    : _service =
          service ??
          PhotoCaptureService(
            clarityAnalyzer: LaplacianVarianceClarityAnalyzer(),
            ocrExtractor: const StubPhotoOcrExtractor(),
          );

  final PhotoCaptureService _service;

  @override
  void registerModes(CaptureModeRegistry registry) {
    registry.registerMode(PhotoCaptureMode(_service));
  }
}
