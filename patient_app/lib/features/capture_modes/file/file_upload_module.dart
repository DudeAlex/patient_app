import '../../capture_core/api/capture_module.dart';

import 'application/use_cases/capture_file_use_case.dart';
import 'file_upload_mode.dart';
import 'file_upload_service.dart';

class FileUploadModule implements CaptureModule {
  FileUploadModule({FileUploadService? service})
      : this._(service ?? FileUploadService());

  FileUploadModule._(FileUploadService service)
      : _useCase = CaptureFileUseCase(service);

  final CaptureFileUseCase _useCase;

  @override
  void registerModes(CaptureModeRegistry registry) {
    registry.registerMode(FileUploadMode(_useCase));
  }
}
