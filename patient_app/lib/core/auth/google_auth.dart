import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  // Provide a web client ID at build time:
  // flutter run -d chrome --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID
  static const _webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  final _googleSignIn = GoogleSignIn(
    clientId: kIsWeb && _webClientId.isNotEmpty ? _webClientId : null,
    scopes: const ['https://www.googleapis.com/auth/drive.appdata'],
  );

  Future<GoogleSignInAccount?> signIn() async {
    return _googleSignIn.signIn();
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
  }

  Future<String?> getAuthHeader() async {
    final account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    final auth = await account?.authHeaders;
    return auth?['Authorization'];
  }
}
