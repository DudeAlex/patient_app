/// Authentication result for token validation.
class AuthResult {
  const AuthResult({
    required this.isValid,
    this.userId,
    this.expiresAt,
    this.error,
    this.roles = const [],
  });

  final bool isValid;
  final String? userId;
  final DateTime? expiresAt;
  final String? error;
  final List<String> roles;
}
