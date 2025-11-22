/// Represents the primary authentication method used by a user
/// to access the Patient App.
enum AuthMethod {
  /// Traditional email and password authentication
  emailPassword,
  
  /// Google OAuth 2.0 authentication
  google,
  
  /// Biometric authentication (fingerprint or face recognition)
  biometric,
}

/// Represents the secondary authentication method used for
/// multi-factor authentication (MFA).
enum MfaMethod {
  /// Biometric verification as second factor
  biometric,
  
  /// Email-based one-time password (OTP) as second factor
  emailOtp,
}
