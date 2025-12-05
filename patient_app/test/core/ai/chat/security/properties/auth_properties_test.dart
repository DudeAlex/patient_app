import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/security/models/auth_result.dart';
import 'package:patient_app/core/ai/chat/security/services/authentication_service_impl.dart';

/// Property 8: Token validation
/// Feature: llm-stage-7e-privacy-security, Property 8: Token validation
/// Validates: Requirements 8.1, 8.2, 8.3, 8.4
///
/// Tokens are validated for signature and expiry; invalid or expired tokens are rejected.
void main() {
  test('Property 8: valid tokens pass, tampered or expired tokens fail', () async {
    DateTime now = DateTime(2025, 1, 1, 12, 0, 0);
    final service = AuthenticationServiceImpl(
      secret: 'secret',
      tokenExpiry: const Duration(minutes: 5),
      clock: () => now,
    );

    final token = await service.generateToken(userId: 'user1', roles: const ['user']);
    final valid = await service.validateToken(token);
    expect(valid.isValid, isTrue);
    expect(valid.roles, contains('user'));

    // Tamper with signature
    final tampered = '$token-invalid';
    final tamperedResult = await service.validateToken(tampered);
    expect(tamperedResult.isValid, isFalse);
    expect(tamperedResult.error, isNotNull);

    // Expire token
    now = now.add(const Duration(minutes: 10));
    final expiredResult = await service.validateToken(token);
    expect(expiredResult.isValid, isFalse);
    expect(expiredResult.error, 'TOKEN_EXPIRED');
  });
}
