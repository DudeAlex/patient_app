import 'package:uuid/uuid.dart';

import '../api/capture_controller.dart';
import '../api/capture_mode.dart';
import '../api/capture_result.dart';
import 'ports/capture_session_storage.dart';

class CaptureControllerImpl implements CaptureController {
  CaptureControllerImpl(
    List<CaptureMode> modes, {
    required CaptureSessionStorage sessionStorage,
    Uuid? uuid,
  })  : _modes = List<CaptureMode>.unmodifiable(modes),
        _sessionStorage = sessionStorage,
        _uuid = uuid ?? const Uuid();

  final List<CaptureMode> _modes;
  final CaptureSessionStorage _sessionStorage;
  final Uuid _uuid;

  @override
  List<CaptureMode> get modes => _modes;

  @override
  String createSession() => _uuid.v4();

  @override
  Future<CaptureResult> startMode({
    required String modeId,
    required CaptureContext context,
  }) async {
    final mode = _modes.firstWhere(
      (m) => m.id == modeId,
      orElse: () => throw ArgumentError.value(modeId, 'modeId', 'Unknown mode'),
    );
    final result = await mode.startCapture(context);
    if (!result.completed) {
      await discardSession(context.sessionId);
    }
    return result;
  }

  @override
  Future<void> discardSession(String sessionId) {
    return _sessionStorage.deleteSession(sessionId);
  }
}
