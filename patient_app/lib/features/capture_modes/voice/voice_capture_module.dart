import '../../capture_core/api/capture_module.dart';

import 'analysis/voice_transcription_pipeline.dart';
import 'application/use_cases/capture_voice_use_case.dart';
import 'voice_capture_mode.dart';
import 'voice_capture_service.dart';

class VoiceCaptureModule implements CaptureModule {
  VoiceCaptureModule({VoiceCaptureService? service})
      : _service = service ??
            VoiceCaptureService(
              transcriptionPipeline: const StubVoiceTranscriptionPipeline(),
            );

  final VoiceCaptureService _service;

  @override
  void registerModes(CaptureModeRegistry registry) {
    final useCase = CaptureVoiceUseCase(_service);
    registry.registerMode(VoiceCaptureMode(useCase));
  }
}
