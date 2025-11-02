/// Enumeration of artefact types produced by capture modes.
enum CaptureArtifactType {
  photo,
  documentScan,
  audio,
  file,
  email,
}

/// Metadata describing a captured asset that should be persisted as an
/// attachment alongside the final record.
class CaptureArtifact {
  const CaptureArtifact({
    required this.id,
    required this.type,
    required this.relativePath,
    required this.createdAt,
    this.mimeType,
    this.sizeBytes,
    this.durationMs,
    this.pageCount,
    this.metadata = const {},
  });

  /// Stable identifier inside the scope of a capture session.
  final String id;

  final CaptureArtifactType type;

  /// Relative path under the attachments root.
  final String relativePath;

  final DateTime createdAt;

  final String? mimeType;

  final int? sizeBytes;

  /// For audio artefacts.
  final int? durationMs;

  /// For document scans (page count).
  final int? pageCount;

  /// Arbitrary mode-specific metadata serialized as primitives/strings.
  final Map<String, Object?> metadata;
}
