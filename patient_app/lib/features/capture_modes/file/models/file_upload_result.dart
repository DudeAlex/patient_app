/// Result of a file upload operation.
class FileUploadResult {
  const FileUploadResult._({
    required this.success,
    this.relativePath,
    this.fileName,
    this.mimeType,
    this.sizeBytes,
    this.errorMessage,
  });

  factory FileUploadResult.success({
    required String relativePath,
    required String fileName,
    String? mimeType,
    required int sizeBytes,
  }) {
    return FileUploadResult._(
      success: true,
      relativePath: relativePath,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
    );
  }

  factory FileUploadResult.cancelled() {
    return const FileUploadResult._(success: false);
  }

  factory FileUploadResult.error(String message) {
    return FileUploadResult._(
      success: false,
      errorMessage: message,
    );
  }

  final bool success;
  final String? relativePath;
  final String? fileName;
  final String? mimeType;
  final int? sizeBytes;
  final String? errorMessage;

  bool get isCancelled => !success && errorMessage == null;
  bool get isError => !success && errorMessage != null;
}
