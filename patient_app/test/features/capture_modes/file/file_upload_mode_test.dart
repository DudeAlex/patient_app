import 'package:flutter_test/flutter_test.dart';

import 'package:patient_app/features/capture_core/api/capture_artifact.dart';
import 'package:patient_app/features/capture_core/api/capture_draft.dart';
import 'package:patient_app/features/capture_core/api/capture_mode.dart';
import 'package:patient_app/features/capture_core/api/capture_result.dart';
import 'package:patient_app/features/capture_modes/file/application/use_cases/capture_file_use_case.dart';
import 'package:patient_app/features/capture_modes/file/file_upload_mode.dart';

void main() {
  group('FileUploadMode', () {
    test('has correct mode metadata properties', () {
      // Arrange: Create mode with mock use case
      final useCase = _MockCaptureFileUseCase();
      final mode = FileUploadMode(useCase);

      // Assert: Verify mode metadata
      expect(mode.id, 'file');
      expect(mode.displayName, 'Upload File');
      expect(mode.iconName, 'upload_file');
    });

    test('isAvailable returns true', () {
      // Arrange: Create mode with mock use case
      final useCase = _MockCaptureFileUseCase();
      final mode = FileUploadMode(useCase);

      // Act & Assert: Mode should always be available for MVP
      expect(mode.isAvailable(), isTrue);
    });

    test('startCapture delegates to use case with context', () async {
      // Arrange: Create mode with mock use case that returns success
      final expectedResult = CaptureResult(
        completed: true,
        artifacts: [
          CaptureArtifact(
            id: 'file_123',
            type: CaptureArtifactType.documentScan,
            relativePath: 'attachments/session123/file_123_test.pdf',
            createdAt: DateTime(2025),
            mimeType: 'application/pdf',
          ),
        ],
        draft: const CaptureDraft(
          suggestedDetails: 'Uploaded file: test.pdf',
        ),
      );
      final useCase = _MockCaptureFileUseCase(result: expectedResult);
      final mode = FileUploadMode(useCase);
      final context = _buildContext(sessionId: 'session123');

      // Act: Start capture
      final result = await mode.startCapture(context);

      // Assert: Result should match use case result
      expect(result.completed, isTrue);
      expect(result.artifacts.length, 1);
      expect(result.artifacts.first.type, CaptureArtifactType.documentScan);
      expect(useCase.executeCalled, isTrue);
      expect(useCase.lastContext?.sessionId, 'session123');
    });

    test('startCapture propagates cancellation from use case', () async {
      // Arrange: Create mode with mock use case that returns cancelled
      final useCase = _MockCaptureFileUseCase(
        result: CaptureResult.cancelled,
      );
      final mode = FileUploadMode(useCase);
      final context = _buildContext(sessionId: 'session123');

      // Act: Start capture
      final result = await mode.startCapture(context);

      // Assert: Result should be cancelled
      expect(result.completed, isFalse);
      expect(useCase.executeCalled, isTrue);
    });

    test('startCapture propagates exceptions from use case', () async {
      // Arrange: Create mode with mock use case that throws
      final useCase = _MockCaptureFileUseCase(
        throwError: Exception('File too large'),
      );
      final mode = FileUploadMode(useCase);
      final context = _buildContext(sessionId: 'session123');

      // Act & Assert: Should propagate exception
      expect(
        () => mode.startCapture(context),
        throwsA(isA<Exception>()),
      );
    });
  });
}

/// Helper to build CaptureContext for tests
CaptureContext _buildContext({required String sessionId}) {
  return CaptureContext(
    sessionId: sessionId,
    locale: 'en',
  );
}

/// Mock implementation of CaptureFileUseCase for testing
class _MockCaptureFileUseCase implements CaptureFileUseCase {
  _MockCaptureFileUseCase({
    this.result,
    this.throwError,
  });

  final CaptureResult? result;
  final Exception? throwError;

  bool executeCalled = false;
  CaptureContext? lastContext;

  @override
  Future<CaptureResult> execute(CaptureContext context) async {
    executeCalled = true;
    lastContext = context;

    if (throwError != null) {
      throw throwError!;
    }

    return result ?? CaptureResult.cancelled;
  }
}
