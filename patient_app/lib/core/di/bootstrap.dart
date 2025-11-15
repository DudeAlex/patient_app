import '../../features/capture_core/capture_core.dart' as capture_core;
import '../../features/capture_modes/document_scan/document_scan_module.dart';
import '../../features/capture_modes/file/file_upload_module.dart';
import '../../features/capture_modes/photo/photo_capture_module.dart';
import '../../features/capture_modes/voice/voice_capture_module.dart';
import '../../features/records/data/records_service.dart';
import 'app_container.dart';

/// Registers core dependencies so presentation layers can resolve them via the
/// [AppContainer] without reinitialising state.
Future<void> bootstrapAppContainer() async {
  final container = AppContainer.instance;
  container.reset();

  container.registerLazySingleton<Future<RecordsService>>(
    (_) => RecordsService.instance(),
  );

  container.registerLazySingleton<capture_core.CaptureController>(
    (_) => capture_core.buildCaptureController(
      [
        PhotoCaptureModule(),
        DocumentScanModule(),
        VoiceCaptureModule(),
        FileUploadModule(),
      ],
    ),
  );
}
