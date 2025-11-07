import '../../capture_core/api/capture_mode.dart';
import '../../capture_core/api/capture_result.dart';
import 'application/use_cases/capture_photo_use_case.dart';

class PhotoCaptureMode implements CaptureMode {
  PhotoCaptureMode(this._useCase);

  final CapturePhotoUseCase _useCase;

  @override
  String get id => 'photo';

  @override
  String get displayName => 'Take Photo';

  @override
  String get iconName => 'camera_alt';

  @override
  bool isAvailable() => true;

  @override
  Future<CaptureResult> startCapture(CaptureContext context) async {
    return _useCase.execute(context);
  }
}
