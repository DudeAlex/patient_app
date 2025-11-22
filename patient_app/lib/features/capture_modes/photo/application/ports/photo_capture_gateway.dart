import '../../../../capture_core/api/capture_artifact.dart';
import '../../../../capture_core/api/capture_mode.dart';
import '../../models/photo_capture_outcome.dart';

/// Port consumed by the photo capture use case so framework-specific services
/// remain swappable in tests.
abstract class PhotoCaptureGateway {
  Future<PhotoCaptureOutcome?> capturePhoto(CaptureContext context);

  Future<void> discardArtifacts(List<CaptureArtifact> artifacts);
}
