import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  // Provide a web client ID at build time:
  // flutter run -d chrome --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID
  static const _webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  // Provide an Android server client ID (Web client ID) at build time:
  // flutter run -d <android_device> --dart-define=GOOGLE_ANDROID_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID
  static const _androidServerClientId = String.fromEnvironment('GOOGLE_ANDROID_SERVER_CLIENT_ID');
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    debugPrint('[Auth] Initializing GoogleSignIn');
    if (kIsWeb) {
      await GoogleSignIn.instance.initialize(
        clientId: _webClientId.isNotEmpty ? _webClientId : null,
      );
      if (_webClientId.isEmpty) {
        debugPrint('[Auth] WARN: GOOGLE_WEB_CLIENT_ID not provided; web sign-in may fail');
      }
    } else {
      await GoogleSignIn.instance.initialize(
        serverClientId: _androidServerClientId.isNotEmpty ? _androidServerClientId : null,
      );
      if (_androidServerClientId.isEmpty) {
        debugPrint('[Auth] ERROR: GOOGLE_ANDROID_SERVER_CLIENT_ID not provided; Android sign-in will fail');
      } else {
        debugPrint('[Auth] Using Android server client id');
      }
    }
    _initialized = true;
    debugPrint('[Auth] GoogleSignIn initialized');
  }

  Future<GoogleSignInAccount?> signIn() async {
    await _ensureInitialized();
    try {
      debugPrint('[Auth] Starting interactive authenticate');
      final acc = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['https://www.googleapis.com/auth/drive.appdata'],
      );
      if (acc == null) {
        debugPrint('[Auth] authenticate returned null (cancelled or failed)');
      } else {
        debugPrint('[Auth] authenticate success for: ' + acc.email);
      }
      return acc;
    } catch (e) {
      debugPrint('[Auth] authenticate error: ' + e.toString());
      return null;
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    debugPrint('[Auth] Signing out');
    await GoogleSignIn.instance.disconnect();
  }

  Future<Map<String, String>?> getAuthHeaders({bool promptIfNecessary = false}) async {
    await _ensureInitialized();
    try {
      debugPrint('[Auth] Fetching auth headers (promptIfNecessary: ' + promptIfNecessary.toString() + ')');
      final headers = await GoogleSignIn.instance.authorizationClient.authorizationHeaders(
        const ['https://www.googleapis.com/auth/drive.appdata'],
        promptIfNecessary: promptIfNecessary,
      );
      if (headers == null) {
        debugPrint('[Auth] authorizationHeaders returned null');
        return null;
      }
      if (headers.isEmpty) {
        debugPrint('[Auth] authorizationHeaders returned empty map');
        return headers;
      }
      debugPrint('[Auth] authorizationHeaders success');
      return headers;
    } catch (e) {
      debugPrint('[Auth] authorizationHeaders error: ' + e.toString());
      return null;
    }
  }

  Future<String?> tryGetEmail() async {
    await _ensureInitialized();
    try {
      final fut = GoogleSignIn.instance.attemptLightweightAuthentication();
      final acc = await (fut ?? Future<GoogleSignInAccount?>.value(null));
      if (acc?.email != null) {
        debugPrint('[Auth] Lightweight auth success for: ' + acc!.email);
      } else {
        debugPrint('[Auth] Lightweight auth returned null');
      }
      return acc?.email;
    } catch (e) {
      debugPrint('[Auth] Lightweight auth error: ' + e.toString());
      return null;
    }
  }
}
