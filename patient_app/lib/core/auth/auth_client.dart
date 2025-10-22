import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleAuthClient extends http.BaseClient {
  final GoogleSignIn _signIn;
  final http.Client _inner;

  GoogleAuthClient(this._signIn, [http.Client? inner]) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final account = _signIn.currentUser ?? await _signIn.signInSilently();
    if (account == null) {
      throw StateError('Google user not signed in');
    }
    final headers = await account.authHeaders;
    request.headers.addAll(headers);
    return _inner.send(request);
  }
}

