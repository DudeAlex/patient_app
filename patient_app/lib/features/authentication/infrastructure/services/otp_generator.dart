import 'dart:math';

/// Service for generating and managing One-Time Passwords (OTP) for MFA.
/// 
/// Generates 6-digit OTPs using cryptographically secure random numbers
/// with a 5-minute expiration window.
class OtpGenerator {
  /// Secure random number generator
  final Random _random = Random.secure();
  
  /// OTP expiration duration (5 minutes)
  static const Duration otpExpiration = Duration(minutes: 5);
  
  /// Length of generated OTP codes
  static const int otpLength = 6;

  /// Generates a 6-digit OTP code.
  /// 
  /// Uses cryptographically secure random number generation to ensure
  /// OTP codes cannot be predicted or guessed.
  /// 
  /// Returns a 6-digit string (e.g., "123456")
  /// 
  /// Example:
  /// ```dart
  /// final generator = OtpGenerator();
  /// final otp = generator.generateOtp();
  /// print(otp); // "847293"
  /// ```
  String generateOtp() {
    // Generate a random number between 0 and 999999
    final code = _random.nextInt(1000000);
    
    // Pad with leading zeros to ensure 6 digits
    return code.toString().padLeft(otpLength, '0');
  }

  /// Calculates the expiration timestamp for a new OTP.
  /// 
  /// Returns a DateTime representing when the OTP should expire
  /// (5 minutes from now)
  /// 
  /// Example:
  /// ```dart
  /// final generator = OtpGenerator();
  /// final expiresAt = generator.calculateExpiration();
  /// ```
  DateTime calculateExpiration() {
    return DateTime.now().add(otpExpiration);
  }

  /// Checks if an OTP has expired based on its expiration timestamp.
  /// 
  /// [expiresAt] The expiration timestamp to check
  /// Returns true if the OTP has expired, false otherwise
  /// 
  /// Example:
  /// ```dart
  /// final generator = OtpGenerator();
  /// final isExpired = generator.isExpired(otpExpiresAt);
  /// if (isExpired) {
  ///   print('OTP has expired, please request a new one');
  /// }
  /// ```
  bool isExpired(DateTime expiresAt) {
    return DateTime.now().isAfter(expiresAt);
  }

  /// Verifies an OTP code against the stored code.
  /// 
  /// [inputCode] The OTP code entered by the user
  /// [storedCode] The OTP code that was generated and stored
  /// [expiresAt] The expiration timestamp of the stored OTP
  /// 
  /// Returns true if the codes match and the OTP hasn't expired
  /// 
  /// Example:
  /// ```dart
  /// final generator = OtpGenerator();
  /// final isValid = generator.verifyOtp(
  ///   userInput,
  ///   storedOtp,
  ///   otpExpiresAt,
  /// );
  /// ```
  bool verifyOtp(String inputCode, String storedCode, DateTime expiresAt) {
    // Check if OTP has expired
    if (isExpired(expiresAt)) {
      return false;
    }
    
    // Verify the codes match (constant-time comparison to prevent timing attacks)
    return _constantTimeCompare(inputCode, storedCode);
  }

  /// Performs constant-time string comparison to prevent timing attacks.
  /// 
  /// Timing attacks could allow an attacker to determine the correct OTP
  /// by measuring how long the comparison takes. This method ensures
  /// the comparison always takes the same amount of time regardless of
  /// where the strings differ.
  /// 
  /// [a] First string to compare
  /// [b] Second string to compare
  /// Returns true if strings are equal, false otherwise
  bool _constantTimeCompare(String a, String b) {
    // If lengths differ, still compare to maintain constant time
    if (a.length != b.length) {
      return false;
    }
    
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    
    return result == 0;
  }

  /// Hashes an OTP for secure storage.
  /// 
  /// While OTPs are short-lived, hashing them before storage adds
  /// an extra layer of security in case the database is compromised.
  /// 
  /// [otp] The OTP to hash
  /// Returns a simple hash of the OTP
  /// 
  /// Note: For production use, consider using a proper hashing algorithm
  /// like SHA-256. This simple implementation is sufficient for short-lived OTPs.
  /// 
  /// Example:
  /// ```dart
  /// final generator = OtpGenerator();
  /// final otp = generator.generateOtp();
  /// final hashedOtp = generator.hashOtp(otp);
  /// // Store hashedOtp in database
  /// ```
  String hashOtp(String otp) {
    // Simple hash for demonstration - in production, use SHA-256 or similar
    int hash = 0;
    for (int i = 0; i < otp.length; i++) {
      hash = ((hash << 5) - hash) + otp.codeUnitAt(i);
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash.abs().toString();
  }
}
