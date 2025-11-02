import 'capture_mode.dart';
import 'capture_result.dart';

/// Coordinates capture sessions and aggregates results before they reach the review UI.
abstract class CaptureController {
  /// Registered modes available in the launcher.
  List<CaptureMode> get modes;

  /// Generates a new capture session identifier.
  String createSession();

  /// Starts the given mode and returns the result for review.
  Future<CaptureResult> startMode({
    required String modeId,
    required CaptureContext context,
  });

  /// Clears any temporary artefacts created during the current session.
  Future<void> discardSession(String sessionId);
}
