import '../../models/file_upload_result.dart';

/// Port for file upload operations.
abstract class FileUploadGateway {
  /// Picks a file and copies it to the session directory.
  /// 
  /// Accepts sessionId (not absolute path) to maintain consistency with
  /// other capture modes and enable proper relative path resolution.
  /// Returns result with file metadata or error.
  Future<FileUploadResult> pickAndCopyFile(String sessionId);
}
