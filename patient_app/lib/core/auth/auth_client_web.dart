import 'package:http/http.dart' as http;

class GoogleAuthClient extends http.BaseClient {
  GoogleAuthClient(dynamic provider, [dynamic inner]);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnsupportedError('GoogleAuthClient not supported on web');
  }
}
