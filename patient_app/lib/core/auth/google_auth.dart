import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  // Provide a web client ID at build time:
  // flutter run -d chrome --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID
  static const _webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: kIsWeb && _webClientId.isNotEmpty ? _webClientId : null,
    );
    _initialized = true;
  }

  Future<GoogleSignInAccount?> signIn() async {
    await _ensureInitialized();
    try {
      return await GoogleSignIn.instance.authenticate(
        scopeHint: const ['https://www.googleapis.com/auth/drive.appdata'],
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.disconnect();
  }

  Future<Map<String, String>?> getAuthHeaders({bool promptIfNecessary = false}) async {
    await _ensureInitialized();
    try {
      return await GoogleSignIn.instance.authorizationClient.authorizationHeaders(
        const ['https://www.googleapis.com/auth/drive.appdata'],
        promptIfNecessary: promptIfNecessary,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> tryGetEmail() async {
    await _ensureInitialized();
    try {
      final fut = GoogleSignIn.instance.attemptLightweightAuthentication();
      final acc = await (fut ?? Future<GoogleSignInAccount?>.value(null));
      return acc?.email;
    } catch (_) {
      return null;
    }
  }
}
