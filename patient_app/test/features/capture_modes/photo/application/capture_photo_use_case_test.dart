import 'package:flutter_test/flutter_test.dart';

import 'package:patient_app/features/capture_core/api/capture_artifact.dart';
import 'package:patient_app/features/capture_core/api/capture_mode.dart';
import 'package:patient_app/features/capture_modes/photo/analysis/photo_clarity_analyzer.dart';
import 'package:patient_app/features/capture_modes/photo/application/ports/photo_capture_gateway.dart';
import 'package:patient_app/features/capture_modes/photo/application/use_cases/capture_photo_use_case.dart';
import 'package:patient_app/features/capture_modes/photo/models/photo_capture_outcome.dart';

void main() {
  group('CapturePhotoUseCase', () {
    test('returns cancelled when gateway reports null outcome', () async {
      final gateway = _RecordingGateway(<PhotoCaptureOutcome?>[null]);
      final useCase = CapturePhotoUseCase(gateway);

      final result = await useCase.execute(_context());

      expect(result.completed, isFalse);
      expect(gateway.captureCalls, 1);
    });

    test('retries capture when patient chooses to retake blurry photo',
        () async {
      final blurryOutcome = _buildOutcome(clarity: const PhotoClarityResult(isSharp: false));
      final sharpOutcome = _buildOutcome();
      final gateway =
          _RecordingGateway(<PhotoCaptureOutcome?>[blurryOutcome, sharpOutcome]);
      final useCase = CapturePhotoUseCase(gateway);
      var promptCount = 0;

      final result = await useCase.execute(
        _context(
          promptRetake: (title, message) {
            promptCount += 1;
            return Future<bool>.value(true); // retake
          },
        ),
      );

      expect(result.completed, isTrue);
      expect(result.artifacts.single.relativePath, sharpOutcome.artifact.relativePath);
      expect(gateway.discardCalls, 1);
      expect(promptCount, 1);
    });

    test('keeps blurry photo and annotates when patient declines retake',
        () async {
      final blurryOutcome = _buildOutcome(clarity: const PhotoClarityResult(
        isSharp: false,
        reason: 'low score',
      ));
      final gateway = _RecordingGateway(<PhotoCaptureOutcome?>[blurryOutcome]);
      final useCase = CapturePhotoUseCase(gateway);

      final result = await useCase.execute(
        _context(
          promptRetake: (title, message) async => false,
        ),
      );

      expect(result.completed, isTrue);
      final metadata = result.artifacts.single.metadata;
      expect(metadata['clarityUserAccepted'], isTrue);
      expect(gateway.discardCalls, 0);
    });
  });
}

CaptureContext _context({
  Future<bool> Function(String title, String message)? promptRetake,
}) {
  return CaptureContext(
    sessionId: 'session',
    locale: 'en',
    promptRetake: promptRetake,
  );
}

PhotoCaptureOutcome _buildOutcome({PhotoClarityResult? clarity}) {
  return PhotoCaptureOutcome(
    artifact: CaptureArtifact(
      id: 'id',
      type: CaptureArtifactType.photo,
      relativePath: 'path.jpg',
      createdAt: DateTime(2025),
      mimeType: 'image/jpeg',
    ),
    clarity: clarity,
  );
}

class _RecordingGateway implements PhotoCaptureGateway {
  _RecordingGateway(this._responses);

  final List<PhotoCaptureOutcome?> _responses;
  int captureCalls = 0;
  int discardCalls = 0;

  @override
  Future<PhotoCaptureOutcome?> capturePhoto(CaptureContext context) async {
    captureCalls += 1;
    return _responses.removeAt(0);
  }

  @override
  Future<void> discardArtifacts(List<CaptureArtifact> artifacts) async {
    discardCalls += 1;
  }
}
