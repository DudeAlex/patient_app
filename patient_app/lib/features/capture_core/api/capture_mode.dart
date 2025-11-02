import 'capture_result.dart';

/// Context passed to capture modes when invoked.
class CaptureContext {
  const CaptureContext({
    required this.sessionId,
    required this.locale,
    this.isAccessibilityEnabled = false,
  });

  /// Unique identifier for the overall capture session.
  final String sessionId;

  /// Current locale (e.g., `en`, `ru`).
  final String locale;

  /// Indicates whether accessibility services (screen reader, large fonts) are active.
  final bool isAccessibilityEnabled;
}

/// Describes a capture mode that can be displayed in the launcher.
abstract class CaptureMode {
  /// Stable identifier (e.g., `photo`, `scan`, `voice`).
  String get id;

  /// Localised label shown to patients.
  String get displayName;

  /// Material Icons name or custom asset reference (to be interpreted by UI layer).
  String get iconName;

  /// Returns true if the current platform/device supports this mode.
  bool isAvailable();

  /// Launches the capture flow and returns the outcome.
  Future<CaptureResult> startCapture(CaptureContext context);
}
