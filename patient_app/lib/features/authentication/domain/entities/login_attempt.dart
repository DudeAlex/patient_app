import 'auth_method.dart';

/// Represents a login attempt for audit logging and security monitoring.
/// 
/// Login attempts are recorded for both successful and failed authentication
/// to enable security features like rate limiting, account lockout, and
/// suspicious activity detection.
class LoginAttempt {
  /// Unique identifier for this login attempt
  final String id;
  
  /// Email address used in the login attempt
  final String email;
  
  /// Whether the login attempt was successful
  final bool success;
  
  /// Authentication method used for this attempt
  final AuthMethod authMethod;
  
  /// Information about the device used for this attempt
  /// (e.g., "iPhone 13, iOS 16.0" or "Pixel 6, Android 13")
  final String? deviceInfo;
  
  /// IP address from which the attempt was made (optional)
  final String? ipAddress;
  
  /// Error message if the attempt failed (null for successful attempts)
  final String? errorMessage;
  
  /// Timestamp when the attempt was made
  final DateTime attemptedAt;

  const LoginAttempt({
    required this.id,
    required this.email,
    required this.success,
    required this.authMethod,
    this.deviceInfo,
    this.ipAddress,
    this.errorMessage,
    required this.attemptedAt,
  });

  /// Creates a copy of this login attempt with the specified fields replaced
  LoginAttempt copyWith({
    String? id,
    String? email,
    bool? success,
    AuthMethod? authMethod,
    String? deviceInfo,
    String? ipAddress,
    String? errorMessage,
    DateTime? attemptedAt,
  }) {
    return LoginAttempt(
      id: id ?? this.id,
      email: email ?? this.email,
      success: success ?? this.success,
      authMethod: authMethod ?? this.authMethod,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      ipAddress: ipAddress ?? this.ipAddress,
      errorMessage: errorMessage ?? this.errorMessage,
      attemptedAt: attemptedAt ?? this.attemptedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginAttempt &&
        other.id == id &&
        other.email == email &&
        other.success == success &&
        other.authMethod == authMethod &&
        other.deviceInfo == deviceInfo &&
        other.ipAddress == ipAddress &&
        other.errorMessage == errorMessage &&
        other.attemptedAt == attemptedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      success,
      authMethod,
      deviceInfo,
      ipAddress,
      errorMessage,
      attemptedAt,
    );
  }

  @override
  String toString() {
    return 'LoginAttempt(id: $id, email: $email, success: $success, '
        'authMethod: $authMethod, attemptedAt: $attemptedAt)';
  }
}
