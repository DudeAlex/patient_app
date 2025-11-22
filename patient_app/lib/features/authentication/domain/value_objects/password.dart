/// Value object representing a validated password.
/// 
/// Enforces password strength requirements to ensure user accounts
/// are protected with secure passwords. Requirements include minimum
/// length, character variety, and complexity rules.
class Password {
  /// The validated password string
  final String value;

  /// Minimum required password length
  static const int minLength = 8;

  /// Private constructor to enforce validation through factory
  const Password._(this.value);

  /// Creates a Password value object from a string.
  /// 
  /// Throws [WeakPasswordException] if the password doesn't meet
  /// security requirements.
  /// 
  /// Requirements (per Requirement 1.3):
  /// - At least 8 characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one number
  /// - At least one special character
  /// 
  /// Example:
  /// ```dart
  /// final password = Password.create('SecureP@ss123'); // Valid
  /// final weak = Password.create('weak'); // Throws exception
  /// ```
  factory Password.create(String password) {
    final errors = <String>[];
    
    // Check minimum length
    if (password.length < minLength) {
      errors.add('Password must be at least $minLength characters long');
    }
    
    // Check for uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) {
      errors.add('Password must contain at least one uppercase letter');
    }
    
    // Check for lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) {
      errors.add('Password must contain at least one lowercase letter');
    }
    
    // Check for number
    if (!password.contains(RegExp(r'[0-9]'))) {
      errors.add('Password must contain at least one number');
    }
    
    // Check for special character
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/;`~]'))) {
      errors.add('Password must contain at least one special character');
    }
    
    // If any validation errors, throw exception with all messages
    if (errors.isNotEmpty) {
      throw WeakPasswordException(errors);
    }
    
    return Password._(password);
  }

  /// Attempts to create a Password value object, returning null if invalid.
  /// 
  /// This is useful when you want to handle validation errors without
  /// catching exceptions.
  /// 
  /// Example:
  /// ```dart
  /// final password = Password.tryCreate('SecureP@ss123'); // Returns Password
  /// final weak = Password.tryCreate('weak'); // Returns null
  /// ```
  static Password? tryCreate(String password) {
    try {
      return Password.create(password);
    } on WeakPasswordException {
      return null;
    }
  }

  /// Validates a password and returns a list of validation errors.
  /// 
  /// Returns an empty list if the password is valid.
  /// This is useful for providing real-time feedback in UI forms.
  /// 
  /// Example:
  /// ```dart
  /// final errors = Password.validate('weak');
  /// // Returns: ['Password must be at least 8 characters long', ...]
  /// ```
  static List<String> validate(String password) {
    try {
      Password.create(password);
      return [];
    } on WeakPasswordException catch (e) {
      return e.errors;
    }
  }

  /// Calculates password strength as a score from 0 to 5.
  /// 
  /// Score breakdown:
  /// - 1 point: meets minimum length
  /// - 1 point: contains uppercase letter
  /// - 1 point: contains lowercase letter
  /// - 1 point: contains number
  /// - 1 point: contains special character
  /// 
  /// This can be used to display a password strength indicator in the UI.
  static int calculateStrength(String password) {
    int strength = 0;
    
    if (password.length >= minLength) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/;`~]'))) strength++;
    
    return strength;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Password && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '***'; // Never expose password in logs
}

/// Exception thrown when a password doesn't meet security requirements.
class WeakPasswordException implements Exception {
  /// List of validation errors describing why the password is weak
  final List<String> errors;

  const WeakPasswordException(this.errors);

  @override
  String toString() => 'WeakPasswordException: ${errors.join(', ')}';
}
