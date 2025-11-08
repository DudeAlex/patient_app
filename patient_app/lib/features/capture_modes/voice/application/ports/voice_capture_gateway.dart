import '../../../../capture_core/api/capture_mode.dart';
import '../../models/voice_capture_outcome.dart';

/// Gateway interface for voice capture adapters (UI + storage plumbing).
///
/// Keeps the use case agnostic of concrete recording widgets/pipelines so we
/// can swap implementations or add tests via mocks.
abstract class VoiceCaptureGateway {
  Future<VoiceCaptureOutcome?> captureVoice(CaptureContext context);
}
