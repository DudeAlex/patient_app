import '../../capture_core/api/capture_module.dart';

import 'analysis/photo_clarity_analyzer.dart';
import 'analysis/photo_ocr_extractor.dart';
import 'application/use_cases/capture_photo_use_case.dart';
import 'photo_capture_mode.dart';
import 'photo_capture_service.dart';

class PhotoCaptureModule implements CaptureModule {
  PhotoCaptureModule({PhotoCaptureService? service})
    : this._(
        service ??
            PhotoCaptureService(
              clarityAnalyzer: LaplacianVarianceClarityAnalyzer(),
              ocrExtractor: const StubPhotoOcrExtractor(),
            ),
      );

  PhotoCaptureModule._(PhotoCaptureService service)
    : _useCase = CapturePhotoUseCase(service);
  final CapturePhotoUseCase _useCase;

  @override
  void registerModes(CaptureModeRegistry registry) {
    registry.registerMode(PhotoCaptureMode(_useCase));
  }
}
