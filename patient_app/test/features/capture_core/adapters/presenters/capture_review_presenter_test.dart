import 'package:flutter_test/flutter_test.dart';

import 'package:patient_app/features/capture_core/adapters/presenters/capture_review_presenter.dart';
import 'package:patient_app/features/capture_core/api/capture_artifact.dart';
import 'package:patient_app/features/capture_core/api/capture_draft.dart';
import 'package:patient_app/features/capture_core/api/capture_mode.dart';
import 'package:patient_app/features/capture_core/api/capture_result.dart';

void main() {
  group('CaptureReviewPresenter', () {
    test('builds view model with draft details and tags', () {
      final presenter = CaptureReviewPresenter(
        mode: _FakeMode('Photo'),
        result: CaptureResult(
          completed: true,
          draft: const CaptureDraft(
            suggestedDetails: 'Details',
            suggestedTags: {'photo', 'ocr'},
          ),
          artifacts: <CaptureArtifact>[
            CaptureArtifact(
              id: '1',
              type: CaptureArtifactType.photo,
              relativePath: 'photos/1.jpg',
              createdAt: DateTime(2025),
              mimeType: 'image/jpeg',
              metadata: const {'clarityScore': 0.9},
            ),
          ],
        ),
      );

      final vm = presenter.buildViewModel();

      expect(vm.title, 'Review Photo');
      expect(vm.details, 'Details');
      expect(vm.tagsDescription, contains('photo'));
      expect(vm.hasDraft, isTrue);
      expect(vm.artifacts.single.metadataLabel, contains('clarityScore'));
    });

    test('falls back to default strings when draft missing', () {
      final presenter = CaptureReviewPresenter(
        mode: _FakeMode('Voice'),
        result: CaptureResult(
          completed: true,
          artifacts: <CaptureArtifact>[
            CaptureArtifact(
              id: 'voice',
              type: CaptureArtifactType.audio,
              relativePath: 'audio/voice.m4a',
              createdAt: DateTime(2025),
              mimeType: 'audio/m4a',
            ),
          ],
        ),
      );

      final vm = presenter.buildViewModel();

      expect(vm.hasDraft, isFalse);
      expect(vm.details, 'No details suggested yet.');
      expect(vm.tagsDescription, 'No tags suggested yet.');
      expect(vm.artifacts.single.hasMetadata, isFalse);
    });
  });
}

class _FakeMode implements CaptureMode {
  _FakeMode(this.name);

  final String name;

  @override
  String get displayName => name;

  @override
  String get iconName => 'icon';

  @override
  String get id => name.toLowerCase();

  @override
  bool isAvailable() => true;

  @override
  Future<CaptureResult> startCapture(CaptureContext context) {
    throw UnimplementedError();
  }
}
