import '../api/capture_controller.dart';
import '../api/capture_module.dart';
import 'capture_controller_impl.dart';
import 'capture_mode_registry_impl.dart';

CaptureController buildCaptureController(List<CaptureModule> modules) {
  final registry = InMemoryCaptureModeRegistry();
  for (final module in modules) {
    module.registerModes(registry);
  }
  return CaptureControllerImpl(registry.modes);
}
