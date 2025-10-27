import 'package:http/http.dart' as http;

/// Web stub. The Google Sign-In web SDK exposes authenticated fetch APIs,
/// so this client is intentionally unsupported for pure web builds.
class GoogleAuthClient extends http.BaseClient {
  GoogleAuthClient(dynamic provider, [dynamic inner]);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnsupportedError('GoogleAuthClient not supported on web');
  }
}
