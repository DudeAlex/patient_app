import 'package:flutter_test/flutter_test.dart';

import 'package:patient_app/features/capture_core/api/capture_artifact.dart';
import 'package:patient_app/features/capture_core/api/capture_mode.dart';
import 'package:patient_app/features/capture_modes/file/application/ports/file_upload_gateway.dart';
import 'package:patient_app/features/capture_modes/file/application/use_cases/capture_file_use_case.dart';
import 'package:patient_app/features/capture_modes/file/models/file_upload_result.dart';

void main() {
  group('CaptureFileUseCase - Artifact Type Mapping', () {
    test('PDF upload creates artifact with type documentScan', () async {
      // Arrange: Mock gateway returns PDF file result
      final gateway = _MockFileUploadGateway(
        FileUploadResult.success(
          relativePath: 'attachments/session123/file_123_report.pdf',
          fileName: 'report.pdf',
          mimeType: 'application/pdf',
          sizeBytes: 1024,
        ),
      );
      final useCase = CaptureFileUseCase(gateway);
      final context = _buildContext(sessionId: 'session123');

      // Act: Execute file upload
      final result = await useCase.execute(context);

      // Assert: Artifact type should be documentScan for PDF
      expect(result.completed, isTrue);
      expect(result.artifacts.length, 1);
      expect(result.artifacts.first.type, CaptureArtifactType.documentScan);
      expect(result.artifacts.first.mimeType, 'application/pdf');
    });

    test('JPEG upload creates artifact with type photo', () async {
      // Arrange: Mock gateway returns JPEG file result
      final gateway = _MockFileUploadGateway(
        FileUploadResult.success(
          relativePath: 'attachments/session123/file_123_prescription.jpg',
          fileName: 'prescription.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 2048,
        ),
      );
      final useCase = CaptureFileUseCase(gateway);
      final context = _buildContext(sessionId: 'session123');

      // Act: Execute file upload
      final result = await useCase.execute(context);

      // Assert: Artifact type should be photo for JPEG
      expect(result.completed, isTrue);
      expect(result.artifacts.length, 1);
      expect(result.artifacts.first.type, CaptureArtifactType.photo);
      expect(result.artifacts.first.mimeType, 'image/jpeg');
    });

    test('PNG upload creates artifact with type photo', () async {
      // Arrange: Mock gateway returns PNG file result
      final gateway = _MockFileUploadGateway(
        FileUploadResult.success(
          relativePath: 'attachments/session123/file_123_insurance.png',
          fileName: 'insurance.png',
          mimeType: 'image/png',
          sizeBytes: 3072,
        ),
      );
      final useCase = CaptureFileUseCase(gateway);
      final context = _buildContext(sessionId: 'session123');

      // Act: Execute file upload
      final result = await useCase.execute(context);

      // Assert: Artifact type should be photo for PNG
      expect(result.completed, isTrue);
      expect(result.artifacts.length, 1);
      expect(result.artifacts.first.type, CaptureArtifactType.photo);
      expect(result.artifacts.first.mimeType, 'image/png');
    });

    test('artifact includes original filename in metadata', () async {
      // Arrange: Mock gateway returns file result
      final gateway = _MockFileUploadGateway(
        FileUploadResult.success(
          relativePath: 'attachments/session123/file_123_test.pdf',
          fileName: 'test.pdf',
          mimeType: 'application/pdf',
          sizeBytes: 1024,
        ),
      );
      final useCase = CaptureFileUseCase(gateway);
      final context = _buildContext(sessionId: 'session123');

      // Act: Execute file upload
      final result = await useCase.execute(context);

      // Assert: Metadata should include original filename
      expect(result.artifacts.first.metadata['originalFileName'], 'test.pdf');
    });

    test('returns cancelled when user cancels file picker', () async {
      // Arrange: Mock gateway returns cancelled result
      final gateway = _MockFileUploadGateway(FileUploadResult.cancelled());
      final useCase = CaptureFileUseCase(gateway);
      final context = _buildContext(sessionId: 'session123');

      // Act: Execute file upload
      final result = await useCase.execute(context);

      // Assert: Result should be cancelled
      expect(result.completed, isFalse);
    });

    test('throws exception when upload fails', () async {
      // Arrange: Mock gateway returns error result
      final gateway = _MockFileUploadGateway(
        FileUploadResult.error('File too large'),
      );
      final useCase = CaptureFileUseCase(gateway);
      final context = _buildContext(sessionId: 'session123');

      // Act & Assert: Should throw exception with error message
      expect(
        () => useCase.execute(context),
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

/// Mock implementation of FileUploadGateway for testing
class _MockFileUploadGateway implements FileUploadGateway {
  _MockFileUploadGateway(this._result);

  final FileUploadResult _result;

  @override
  Future<FileUploadResult> pickAndCopyFile(String sessionId) async {
    return _result;
  }
}
