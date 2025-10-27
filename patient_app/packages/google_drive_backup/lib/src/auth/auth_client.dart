import 'package:http/http.dart' as http;

typedef AuthHeadersProvider = Future<Map<String, String>?> Function();

/// HTTP client that injects Google authorization headers fetched from a
/// provided async callback. Throws if the callback returns null/empty headers.
class GoogleAuthClient extends http.BaseClient {
  final http.Client _inner;
  final AuthHeadersProvider _headersProvider;

  GoogleAuthClient(this._headersProvider, [http.Client? inner])
      : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final headers = await _headersProvider();
    if (headers == null || headers.isEmpty) {
      throw StateError('No Google auth headers available');
    }
    request.headers.addAll(headers);
    return _inner.send(request);
  }
}
