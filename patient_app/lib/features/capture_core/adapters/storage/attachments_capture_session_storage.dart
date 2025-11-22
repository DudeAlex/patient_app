import '../../../../core/storage/attachments.dart';
import '../../application/ports/capture_session_storage.dart';

/// Storage adapter that maps capture session cleanup requests to the shared
/// attachments helper.
class AttachmentsCaptureSessionStorage implements CaptureSessionStorage {
  const AttachmentsCaptureSessionStorage();

  @override
  Future<void> deleteSession(String sessionId) {
    return AttachmentsStorage.deleteSession(sessionId);
  }
}
