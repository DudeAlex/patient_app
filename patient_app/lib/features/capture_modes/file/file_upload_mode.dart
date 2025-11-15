import '../../capture_core/api/capture_mode.dart';
import '../../capture_core/api/capture_result.dart';
import 'application/use_cases/capture_file_use_case.dart';

/// Capture mode for uploading files from device storage.
/// 
/// Integrates file upload into the multi-modal capture launcher,
/// allowing patients to import PDFs and images from their device.
class FileUploadMode implements CaptureMode {
  FileUploadMode(this._useCase);

  final CaptureFileUseCase _useCase;

  @override
  String get id => 'file';

  @override
  String get displayName => 'Upload File';

  @override
  String get iconName => 'upload_file';

  /// Returns true if file upload is available on the current platform.
  /// 
  /// For MVP, always returns true. Future enhancement: check platform
  /// capabilities (e.g., web File API support, mobile storage permissions).
  @override
  bool isAvailable() => true;

  /// Launches the file upload flow.
  /// 
  /// Delegates to the use case with the full capture context,
  /// following the same pattern as photo and voice capture modes.
  @override
  Future<CaptureResult> startCapture(CaptureContext context) async {
    return _useCase.execute(context);
  }
}
