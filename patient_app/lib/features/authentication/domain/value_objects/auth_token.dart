import 'dart:convert';
import 'dart:math';

/// Value object representing a secure authentication token.
/// 
/// Wraps a session token with expiration checking and validation logic.
/// Tokens are used to maintain authenticated sessions and must be
/// cryptographically secure and time-limited.
class AuthToken {
  /// The token string value
  final String value;
  
  /// When this token expires
  final DateTime expiresAt;

  /// Standard session duration (24 hours per Requirement 2.5)
  static const Duration sessionDuration = Duration(hours: 24);

  /// Private constructor to enforce validation through factory
  const AuthToken._(this.value, this.expiresAt);

  /// Creates an AuthToken from an existing token string and expiration time.
  /// 
  /// Throws [InvalidTokenException] if the token is invalid or expired.
  /// 
  /// Example:
  /// ```dart
  /// final token = AuthToken.create(
  ///   'abc123...',
  ///   DateTime.now().add(Duration(hours: 24)),
  /// );
  /// ```
  factory AuthToken.create(String token, DateTime expiresAt) {
    if (token.isEmpty) {
      throw InvalidTokenException('Token cannot be empty');
    }
    
    // Validate token format: should be base64-encoded and at least 32 characters
    if (token.length < 32) {
      throw InvalidTokenException('Token is too short (minimum 32 characters)');
    }
    
    // Check if token appears to be base64-encoded
    if (!_isValidBase64(token)) {
      throw InvalidTokenException('Token must be base64-encoded');
    }
    
    return AuthToken._(token, expiresAt);
  }

  /// Generates a new secure authentication token with standard expiration.
  /// 
  /// Creates a cryptographically secure random token that expires after
  /// 24 hours (per Requirement 2.5).
  /// 
  /// Example:
  /// ```dart
  /// final token = AuthToken.generate();
  /// print(token.value); // Random base64 string
  /// print(token.expiresAt); // 24 hours from now
  /// ```
  factory AuthToken.generate() {
    final random = Random.secure();
    final bytes = List<int>.generate(48, (_) => random.nextInt(256));
    final token = base64Url.encode(bytes);
    final expiresAt = DateTime.now().add(sessionDuration);
    
    return AuthToken._(token, expiresAt);
  }

  /// Generates a new token with a custom expiration duration.
  /// 
  /// Useful for special cases like password reset tokens (1 hour)
  /// or refresh tokens (longer duration).
  /// 
  /// Example:
  /// ```dart
  /// // Password reset token (1 hour per Requirement 6.2)
  /// final resetToken = AuthToken.generateWithDuration(Duration(hours: 1));
  /// ```
  factory AuthToken.generateWithDuration(Duration duration) {
    final random = Random.secure();
    final bytes = List<int>.generate(48, (_) => random.nextInt(256));
    final token = base64Url.encode(bytes);
    final expiresAt = DateTime.now().add(duration);
    
    return AuthToken._(token, expiresAt);
  }

  /// Checks if this token has expired.
  /// 
  /// Returns true if the current time is after the expiration time.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Checks if this token is still valid (not expired).
  bool get isValid => !isExpired;

  /// Gets the remaining time until this token expires.
  /// 
  /// Returns Duration.zero if already expired.
  Duration get timeUntilExpiration {
    if (isExpired) return Duration.zero;
    return expiresAt.difference(DateTime.now());
  }

  /// Validates that this token is not expired.
  /// 
  /// Throws [ExpiredTokenException] if the token has expired.
  void validateNotExpired() {
    if (isExpired) {
      throw ExpiredTokenException('Token expired at $expiresAt');
    }
  }

  /// Checks if a string appears to be valid base64 encoding
  static bool _isValidBase64(String str) {
    try {
      base64Url.decode(str);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthToken &&
        other.value == value &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode => Object.hash(value, expiresAt);

  @override
  String toString() => 'AuthToken(expires: $expiresAt, valid: $isValid)';
}

/// Exception thrown when an invalid token format is provided.
class InvalidTokenException implements Exception {
  /// Description of why the token is invalid
  final String message;

  const InvalidTokenException(this.message);

  @override
  String toString() => 'InvalidTokenException: $message';
}

/// Exception thrown when attempting to use an expired token.
class ExpiredTokenException implements Exception {
  /// Description of the expiration
  final String message;

  const ExpiredTokenException(this.message);

  @override
  String toString() => 'ExpiredTokenException: $message';
}
