import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:patient_app/core/ai/chat/security/interfaces/authentication_service.dart';
import 'package:patient_app/core/ai/chat/security/models/auth_result.dart';

/// Lightweight HMAC-based token service (JWT-like, not a full JWT parser).
class AuthenticationServiceImpl implements AuthenticationService {
  AuthenticationServiceImpl({
    String? secret,
    Duration? tokenExpiry,
    DateTime Function()? clock,
  })  : _secret = utf8.encode(secret ?? const String.fromEnvironment('AUTH_SECRET', defaultValue: 'dev-secret')),
        _tokenExpiry = tokenExpiry ?? const Duration(hours: 24),
        _clock = clock ?? DateTime.now;

  final List<int> _secret;
  final Duration _tokenExpiry;
  final DateTime Function() _clock;
  final Set<String> _revoked = {};
  final Hmac _hmac = Hmac.sha256();

  @override
  Future<String> generateToken({
    required String userId,
    List<String> roles = const [],
  }) async {
    final exp = _clock().add(_tokenExpiry).millisecondsSinceEpoch;
    final payload = jsonEncode({'sub': userId, 'exp': exp, 'roles': roles});
    final payloadB64 = base64UrlEncode(utf8.encode(payload));
    final mac = await _hmac.calculateMac(utf8.encode(payloadB64), secretKey: SecretKey(_secret));
    final sigB64 = base64UrlEncode(mac.bytes);
    return '$payloadB64.$sigB64';
  }

  @override
  Future<AuthResult> validateToken(String token) async {
    try {
      if (_revoked.contains(token)) {
        return const AuthResult(isValid: false, error: 'TOKEN_REVOKED');
      }
      final parts = token.split('.');
      if (parts.length != 2) {
        return const AuthResult(isValid: false, error: 'INVALID_FORMAT');
      }
      final payloadStr = utf8.decode(base64Url.decode(parts[0]));
      final sig = base64Url.decode(parts[1]);
      final expected = await _hmac.calculateMac(utf8.encode(parts[0]), secretKey: SecretKey(_secret));
      if (!_constantTimeEquals(expected.bytes, sig)) {
        return const AuthResult(isValid: false, error: 'INVALID_SIGNATURE');
      }
      final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
      final userId = payload['sub'] as String?;
      final exp = payload['exp'] as int?;
      final roles = (payload['roles'] as List?)?.cast<String>() ?? const [];
      if (userId == null || exp == null) {
        return const AuthResult(isValid: false, error: 'INVALID_PAYLOAD');
      }
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp);
      if (_clock().isAfter(expiresAt)) {
        return AuthResult(isValid: false, error: 'TOKEN_EXPIRED', expiresAt: expiresAt);
      }
      return AuthResult(
        isValid: true,
        userId: userId,
        expiresAt: expiresAt,
        roles: roles,
      );
    } catch (_) {
      return const AuthResult(isValid: false, error: 'INVALID_TOKEN');
    }
  }

  @override
  Future<void> revokeToken(String token) async {
    _revoked.add(token);
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
