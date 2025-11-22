/// Value object representing a validated email address.
/// 
/// Ensures email addresses conform to a valid format before being used
/// in the authentication system. This prevents invalid emails from
/// entering the domain layer.
class Email {
  /// The validated email address string
  final String value;

  /// Regular expression pattern for email validation
  /// Matches standard email format: local-part@domain
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Private constructor to enforce validation through factory
  const Email._(this.value);

  /// Creates an Email value object from a string.
  /// 
  /// Throws [InvalidEmailException] if the email format is invalid.
  /// 
  /// Example:
  /// ```dart
  /// final email = Email.create('user@example.com'); // Valid
  /// final invalid = Email.create('not-an-email'); // Throws exception
  /// ```
  factory Email.create(String email) {
    // Trim whitespace and convert to lowercase for consistency
    final normalized = email.trim().toLowerCase();
    
    if (normalized.isEmpty) {
      throw InvalidEmailException('Email address cannot be empty');
    }
    
    if (!_emailRegex.hasMatch(normalized)) {
      throw InvalidEmailException('Invalid email format: $email');
    }
    
    // Additional validation: check length constraints
    if (normalized.length > 254) {
      throw InvalidEmailException('Email address is too long (max 254 characters)');
    }
    
    return Email._(normalized);
  }

  /// Attempts to create an Email value object, returning null if invalid.
  /// 
  /// This is useful when you want to handle validation errors without
  /// catching exceptions.
  /// 
  /// Example:
  /// ```dart
  /// final email = Email.tryCreate('user@example.com'); // Returns Email
  /// final invalid = Email.tryCreate('not-an-email'); // Returns null
  /// ```
  static Email? tryCreate(String email) {
    try {
      return Email.create(email);
    } on InvalidEmailException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Email && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Exception thrown when an invalid email format is provided.
class InvalidEmailException implements Exception {
  /// Description of why the email is invalid
  final String message;

  const InvalidEmailException(this.message);

  @override
  String toString() => 'InvalidEmailException: $message';
}
