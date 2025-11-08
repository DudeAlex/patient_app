import 'package:flutter_test/flutter_test.dart';

import 'package:patient_app/features/capture_core/api/capture_artifact.dart';
import 'package:patient_app/features/capture_core/api/capture_draft.dart';
import 'package:patient_app/features/capture_core/api/capture_mode.dart';
import 'package:patient_app/features/capture_core/api/capture_result.dart';
import 'package:patient_app/features/capture_modes/voice/application/ports/voice_capture_gateway.dart';
import 'package:patient_app/features/capture_modes/voice/application/use_cases/capture_voice_use_case.dart';
import 'package:patient_app/features/capture_modes/voice/models/voice_capture_outcome.dart';

void main() {
  group('CaptureVoiceUseCase', () {
    test('returns cancelled when gateway yields null outcome', () async {
      final gateway = _RecordingGateway(<VoiceCaptureOutcome?>[null]);
      final useCase = CaptureVoiceUseCase(gateway);

      final result = await useCase.execute(_context());

      expect(result.completed, isFalse);
      expect(gateway.captureCalls, 1);
    });

    test('wraps artifact and uses provided draft when available', () async {
      final draft = CaptureDraft(suggestedTags: const {'voice', 'transcribed'});
      final outcome = VoiceCaptureOutcome(
        artifact: _artifact('voice1.m4a'),
        draft: draft,
      );
      final gateway = _RecordingGateway(<VoiceCaptureOutcome?>[outcome]);
      final useCase = CaptureVoiceUseCase(gateway);

      final CaptureResult result = await useCase.execute(_context());

      expect(result.completed, isTrue);
      expect(result.artifacts.single.relativePath, 'voice1.m4a');
      expect(result.draft, same(draft));
    });

    test('applies default voice draft when gateway omits one', () async {
      final outcome = VoiceCaptureOutcome(
        artifact: _artifact('voice2.m4a'),
      );
      final gateway = _RecordingGateway(<VoiceCaptureOutcome?>[outcome]);
      final useCase = CaptureVoiceUseCase(gateway);

      final CaptureResult result = await useCase.execute(_context());

      expect(result.completed, isTrue);
      expect(result.draft?.suggestedTags, contains('voice'));
    });
  });
}

CaptureContext _context() {
  return CaptureContext(
    sessionId: 'session',
    locale: 'en',
  );
}

CaptureArtifact _artifact(String path) {
  return CaptureArtifact(
    id: path,
    type: CaptureArtifactType.audio,
    relativePath: path,
    createdAt: DateTime(2025),
    mimeType: 'audio/m4a',
  );
}

class _RecordingGateway implements VoiceCaptureGateway {
  _RecordingGateway(this._responses);

  final List<VoiceCaptureOutcome?> _responses;
  int captureCalls = 0;

  @override
  Future<VoiceCaptureOutcome?> captureVoice(CaptureContext context) async {
    captureCalls += 1;
    return _responses.removeAt(0);
  }
}
