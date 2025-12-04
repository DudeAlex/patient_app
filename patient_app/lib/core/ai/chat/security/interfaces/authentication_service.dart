import 'package:patient_app/core/ai/chat/security/models/auth_result.dart';

/// Interface for token-based authentication.
abstract class AuthenticationService {
  /// Generate a token for the given user and roles.
  Future<String> generateToken({
    required String userId,
    List<String> roles,
  });

  /// Validate a token, checking signature, expiry, and revocation.
  Future<AuthResult> validateToken(String token);

  /// Revoke a token.
  Future<void> revokeToken(String token);
}
