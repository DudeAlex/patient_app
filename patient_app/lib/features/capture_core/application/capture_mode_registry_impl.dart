import '../api/capture_mode.dart';
import '../api/capture_module.dart';

class InMemoryCaptureModeRegistry implements CaptureModeRegistry {
  final List<CaptureMode> _modes = <CaptureMode>[];

  List<CaptureMode> get modes => List.unmodifiable(_modes);

  @override
  void registerMode(CaptureMode mode) {
    if (_modes.any((existing) => existing.id == mode.id)) {
      return;
    }
    _modes.add(mode);
  }
}
