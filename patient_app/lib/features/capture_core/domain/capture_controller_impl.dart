import 'package:uuid/uuid.dart';

import '../../../core/storage/attachments.dart';
import '../api/capture_controller.dart';
import '../api/capture_mode.dart';
import '../api/capture_result.dart';

class CaptureControllerImpl implements CaptureController {
  CaptureControllerImpl(List<CaptureMode> modes, {Uuid? uuid})
    : _modes = List.unmodifiable(modes),
      _uuid = uuid ?? const Uuid();

  final List<CaptureMode> _modes;
  final Uuid _uuid;

  @override
  List<CaptureMode> get modes => _modes;

  @override
  String createSession() {
    return _uuid.v4();
  }

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
  Future<void> discardSession(String sessionId) async {
    await AttachmentsStorage.deleteSession(sessionId);
  }
}
