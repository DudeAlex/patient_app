/// Storage port used by capture flows to clean up temporary session artifacts
/// without depending on a concrete filesystem implementation.
abstract class CaptureSessionStorage {
  Future<void> deleteSession(String sessionId);
}
