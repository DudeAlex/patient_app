import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/security/services/authentication_service_impl.dart';

void main() {
  test('generate and validate token', () async {
    final auth = AuthenticationServiceImpl(
      secret: 'test-secret',
      clock: () => DateTime(2025, 1, 1, 12, 0, 0),
    );
    final token = await auth.generateToken(userId: 'user1', roles: ['user']);
    final result = await auth.validateToken(token);
    expect(result.isValid, isTrue);
    expect(result.userId, 'user1');
    expect(result.roles, contains('user'));
    expect(result.expiresAt, isNotNull);
  });

  test('rejects expired token', () async {
    DateTime now = DateTime(2025, 1, 1, 12, 0, 0);
    final auth = AuthenticationServiceImpl(
      secret: 'test-secret',
      tokenExpiry: const Duration(hours: 1),
      clock: () => now,
    );
    final token = await auth.generateToken(userId: 'user1');
    now = now.add(const Duration(hours: 2));
    final result = await auth.validateToken(token);
    expect(result.isValid, isFalse);
    expect(result.error, 'TOKEN_EXPIRED');
  });

  test('revokes token', () async {
    final auth = AuthenticationServiceImpl(
      secret: 'test-secret',
      clock: () => DateTime(2025, 1, 1, 12, 0, 0),
    );
    final token = await auth.generateToken(userId: 'user1');
    await auth.revokeToken(token);
    final result = await auth.validateToken(token);
    expect(result.isValid, isFalse);
    expect(result.error, 'TOKEN_REVOKED');
  });
}
