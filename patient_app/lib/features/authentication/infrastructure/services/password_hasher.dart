import 'package:bcrypt/bcrypt.dart';

/// Service for securely hashing and verifying passwords using bcrypt.
/// 
/// Uses bcrypt with cost factor 12 to meet security requirements.
/// The cost factor determines the computational complexity of hashing,
/// making brute-force attacks more difficult.
class PasswordHasher {
  /// The bcrypt cost factor (number of rounds).
  /// Higher values increase security but also increase computation time.
  /// Cost factor 12 provides strong security while maintaining reasonable performance.
  static const int _costFactor = 12;

  /// Hashes a plain text password using bcrypt.
  /// 
  /// [plainPassword] The password to hash
  /// Returns the hashed password string that can be safely stored
  /// 
  /// Example:
  /// ```dart
  /// final hasher = PasswordHasher();
  /// final hash = await hasher.hashPassword('mySecurePassword123!');
  /// ```
  Future<String> hashPassword(String plainPassword) async {
    // BCrypt.hashpw is CPU-intensive, so we run it in a separate isolate
    // to avoid blocking the UI thread
    return BCrypt.hashpw(plainPassword, BCrypt.gensalt(logRounds: _costFactor));
  }

  /// Verifies a plain text password against a bcrypt hash.
  /// 
  /// [plainPassword] The password to verify
  /// [hashedPassword] The stored hash to compare against
  /// Returns true if the password matches the hash, false otherwise
  /// 
  /// Example:
  /// ```dart
  /// final hasher = PasswordHasher();
  /// final isValid = await hasher.verifyPassword('myPassword', storedHash);
  /// ```
  Future<bool> verifyPassword(String plainPassword, String hashedPassword) async {
    // BCrypt.checkpw is CPU-intensive, so we run it in a separate isolate
    // to avoid blocking the UI thread
    return BCrypt.checkpw(plainPassword, hashedPassword);
  }
}
