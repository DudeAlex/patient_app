import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final _googleSignIn = GoogleSignIn(
    scopes: const [
      'https://www.googleapis.com/auth/drive.appdata',
    ],
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

