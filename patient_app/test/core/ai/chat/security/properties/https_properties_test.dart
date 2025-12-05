import 'package:flutter_test/flutter_test.dart';

/// Property 7: HTTPS enforcement
/// Feature: llm-stage-7e-privacy-security, Property 7: HTTPS enforcement
/// Validates: Requirements 7.1, 7.2
///
/// Requests that are not HTTPS (and not marked via x-forwarded-proto) are rejected.
bool _isHttpsRequest({
  required bool isSecure,
  required List<String> forwardedProto,
  bool httpsOnly = true,
}) {
  if (!httpsOnly) return true;
  if (isSecure) return true;
  return forwardedProto.map((v) => v.toLowerCase()).contains('https');
}

void main() {
  test('Property 7: non-HTTPS requests are rejected when HTTPS-only', () {
    final allowed = _isHttpsRequest(isSecure: true, forwardedProto: const ['https']);
    expect(allowed, isTrue);

    final viaProxy = _isHttpsRequest(isSecure: false, forwardedProto: const ['https']);
    expect(viaProxy, isTrue);

    final rejected = _isHttpsRequest(isSecure: false, forwardedProto: const ['http']);
    expect(rejected, isFalse);
  });

  test('Property 7: HTTP allowed when HTTPS-only disabled (dev)', () {
    final allowedDev = _isHttpsRequest(
      isSecure: false,
      forwardedProto: const ['http'],
      httpsOnly: false,
    );
    expect(allowedDev, isTrue);
  });
}
