/// Web stub for Google auth — web builds should provide their own
/// implementation using the Google Sign-In JS SDK.
class GoogleAuthService {
  Future<void> signOut() async {}
  Future<dynamic> signIn() async => null;
  Future<Map<String, String>?> getAuthHeaders({bool promptIfNecessary = false}) async => null;
  Future<String?> tryGetEmail() async => null;
  Future<String> diagnostics() async => 'Diagnostics not available on web';
  String? get cachedEmail => null;
}
