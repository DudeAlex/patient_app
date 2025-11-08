import '../../capture_core/api/capture_mode.dart';
import '../../capture_core/api/capture_result.dart';
import 'application/use_cases/capture_voice_use_case.dart';

class VoiceCaptureMode implements CaptureMode {
  VoiceCaptureMode(this._useCase);

  final CaptureVoiceUseCase _useCase;

  @override
  String get id => 'voice';

  @override
  String get displayName => 'Voice Note';

  @override
  String get iconName => 'mic';

  @override
  bool isAvailable() => true;

  @override
  Future<CaptureResult> startCapture(CaptureContext context) async {
    return _useCase.execute(context);
  }
}
