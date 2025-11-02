import 'capture_mode.dart';

/// Contract for registering capture modes and providing a controller implementation.
abstract class CaptureModule {
  /// Registers built-in capture modes with the provided registry.
  void registerModes(CaptureModeRegistry registry);
}

/// Registry used by capture modules to expose modes to the launcher.
abstract class CaptureModeRegistry {
  void registerMode(CaptureMode mode);
}
