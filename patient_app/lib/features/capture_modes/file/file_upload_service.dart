import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import '../../capture_core/adapters/storage/attachments_capture_artifact_storage.dart';
import '../../capture_core/application/ports/capture_artifact_storage.dart';
import 'application/ports/file_upload_gateway.dart';
import 'models/file_upload_result.dart';

/// Service that handles file selection and copying to attachments storage.
/// 
/// Uses CaptureArtifactStorage for consistent session path resolution,
/// matching the pattern used by photo and voice capture modes.
class FileUploadService implements FileUploadGateway {
  FileUploadService({CaptureArtifactStorage? storage})
      : _storage = storage ?? const AttachmentsCaptureArtifactStorage();

  static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50 MB

  final CaptureArtifactStorage _storage;

  @override
  Future<FileUploadResult> pickAndCopyFile(String sessionId) async {
    // Pick file using file_picker
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return FileUploadResult.cancelled();
    }

    final pickedFile = result.files.first;
    final filePath = pickedFile.path;

    if (filePath == null) {
      return FileUploadResult.error('Could not access selected file');
    }

    // Check file size
    final file = File(filePath);
    final fileSize = await file.length();

    if (fileSize > maxFileSizeBytes) {
      final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      return FileUploadResult.error(
        'File too large ($sizeMB MB). Maximum size is 50 MB.',
      );
    }

    // Generate timestamped filename and allocate relative path
    final fileName = path.basename(filePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final targetFileName = 'file_${timestamp}_$fileName';
    
    // Allocate relative path using storage abstraction (consistent with photo/voice)
    final relativePath = await _storage.allocateRelativePath(
      sessionId: sessionId,
      fileName: targetFileName,
    );

    try {
      // Resolve absolute path for file copy operation
      final root = await _storage.rootDir();
      final targetFile = File('${root.path}/$relativePath');
      await file.copy(targetFile.path);

      return FileUploadResult.success(
        relativePath: relativePath,
        fileName: fileName,
        mimeType: pickedFile.extension != null
            ? _getMimeType(pickedFile.extension!)
            : null,
        sizeBytes: fileSize,
      );
    } catch (e) {
      return FileUploadResult.error('Failed to copy file: $e');
    }
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
}
