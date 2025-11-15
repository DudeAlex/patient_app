import '../../../../capture_core/api/capture_artifact.dart';
import '../../../../capture_core/api/capture_draft.dart';
import '../../../../capture_core/api/capture_mode.dart';
import '../../../../capture_core/api/capture_result.dart';
import '../ports/file_upload_gateway.dart';

/// Use case for file upload capture flow.
class CaptureFileUseCase {
  CaptureFileUseCase(this._gateway);

  final FileUploadGateway _gateway;

  /// Executes file upload: pick file, copy to session, create artifact.
  /// 
  /// Follows the same pattern as photo and voice capture modes by accepting
  /// CaptureContext and extracting sessionId for storage operations.
  /// 
  /// Throws an exception if an error occurs during file upload, which will
  /// be caught by the capture launcher and displayed as a snackbar.
  Future<CaptureResult> execute(CaptureContext context) async {
    final uploadResult = await _gateway.pickAndCopyFile(context.sessionId);

    if (uploadResult.isCancelled) {
      return CaptureResult.cancelled;
    }

    if (uploadResult.isError) {
      throw Exception(uploadResult.errorMessage!);
    }

    // Create artifact from uploaded file
    final now = DateTime.now();
    final artifact = CaptureArtifact(
      id: 'file_${now.millisecondsSinceEpoch}',
      type: _inferArtifactType(uploadResult.mimeType),
      relativePath: uploadResult.relativePath!,
      createdAt: now,
      mimeType: uploadResult.mimeType,
      sizeBytes: uploadResult.sizeBytes,
      metadata: {
        'originalFileName': uploadResult.fileName!,
      },
    );

    // Create draft with basic info
    final draft = CaptureDraft(
      suggestedDetails: 'Uploaded file: ${uploadResult.fileName}',
    );

    return CaptureResult(
      completed: true,
      artifacts: [artifact],
      draft: draft,
    );
  }

  CaptureArtifactType _inferArtifactType(String? mimeType) {
    if (mimeType == null) return CaptureArtifactType.file;

    if (mimeType.startsWith('image/')) {
      return CaptureArtifactType.photo;
    } else if (mimeType == 'application/pdf') {
      return CaptureArtifactType.documentScan;
    }

    return CaptureArtifactType.file;
  }
}
