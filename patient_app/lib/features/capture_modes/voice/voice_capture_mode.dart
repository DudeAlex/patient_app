import '../../capture_core/api/capture_mode.dart';
import '../../capture_core/api/capture_result.dart';
import '../../capture_core/api/capture_draft.dart';

import 'models/voice_capture_outcome.dart';
import 'voice_capture_service.dart';

class VoiceCaptureMode implements CaptureMode {
  VoiceCaptureMode(this._service);

  final VoiceCaptureService _service;

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
    final VoiceCaptureOutcome? outcome =
        await _service.captureVoice(context);
    if (outcome == null) {
      return CaptureResult.cancelled;
    }

    return CaptureResult(
      completed: true,
      artifacts: [outcome.artifact],
      draft: outcome.draft ??
          const CaptureDraft(
            suggestedTags: {'voice'},
          ),
    );
  }
}
