/// Represents a patient user in the authentication system.
/// 
/// A user can authenticate via email/password, Google Sign-In, or both.
/// The user entity tracks authentication preferences including MFA and
/// biometric settings.
class User {
  /// Unique identifier for the user
  final String id;
  
  /// User's email address (used for login and communication)
  final String email;
  
  /// Hashed password using bcrypt (null for Google-only accounts)
  final String? passwordHash;
  
  /// Whether the user has verified their email address
  final bool isEmailVerified;
  
  /// Whether multi-factor authentication is enabled
  final bool isMfaEnabled;
  
  /// Whether biometric authentication is enabled
  final bool isBiometricEnabled;
  
  /// Google account ID if linked (null if not using Google Sign-In)
  final String? googleAccountId;
  
  /// Timestamp when the account was created
  final DateTime createdAt;
  
  /// Timestamp of the most recent successful login (null if never logged in)
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.email,
    this.passwordHash,
    required this.isEmailVerified,
    required this.isMfaEnabled,
    required this.isBiometricEnabled,
    this.googleAccountId,
    required this.createdAt,
    this.lastLoginAt,
  });

  /// Creates a copy of this user with the specified fields replaced
  User copyWith({
    String? id,
    String? email,
    String? passwordHash,
    bool? isEmailVerified,
    bool? isMfaEnabled,
    bool? isBiometricEnabled,
    String? googleAccountId,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isMfaEnabled: isMfaEnabled ?? this.isMfaEnabled,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      googleAccountId: googleAccountId ?? this.googleAccountId,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.passwordHash == passwordHash &&
        other.isEmailVerified == isEmailVerified &&
        other.isMfaEnabled == isMfaEnabled &&
        other.isBiometricEnabled == isBiometricEnabled &&
        other.googleAccountId == googleAccountId &&
        other.createdAt == createdAt &&
        other.lastLoginAt == lastLoginAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      passwordHash,
      isEmailVerified,
      isMfaEnabled,
      isBiometricEnabled,
      googleAccountId,
      createdAt,
      lastLoginAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, isEmailVerified: $isEmailVerified, '
        'isMfaEnabled: $isMfaEnabled, isBiometricEnabled: $isBiometricEnabled, '
        'googleAccountId: $googleAccountId)';
  }
}
