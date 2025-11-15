/// Port (interface) for sending authentication-related emails.
/// 
/// This interface abstracts email delivery for verification, password reset,
/// MFA codes, and security alerts. Implementations wrap SMTP clients or
/// email service APIs while use cases depend only on this abstraction.
abstract class EmailGateway {
  /// Sends an email verification link to a newly registered user.
  /// 
  /// The [to] parameter is the user's email address.
  /// The [verificationLink] is a secure URL that the user clicks to
  /// verify their email address.
  /// 
  /// The email should include:
  /// - Welcome message
  /// - Verification link with clear call-to-action
  /// - Link expiration time
  /// - Instructions if link doesn't work
  Future<void> sendVerificationEmail(String to, String verificationLink);

  /// Sends a password reset link to a user who forgot their password.
  /// 
  /// The [to] parameter is the user's email address.
  /// The [resetLink] is a secure URL that allows the user to set a new password.
  /// 
  /// The email should include:
  /// - Password reset link with clear call-to-action
  /// - Link expiration time (1 hour)
  /// - Security notice (ignore if not requested)
  /// - Instructions if link doesn't work
  Future<void> sendPasswordResetEmail(String to, String resetLink);

  /// Sends a one-time password (OTP) for multi-factor authentication.
  /// 
  /// The [to] parameter is the user's email address.
  /// The [otp] is a 6-digit code valid for 5 minutes.
  /// 
  /// The email should include:
  /// - The OTP code prominently displayed
  /// - Expiration time (5 minutes)
  /// - Security notice (don't share this code)
  /// - Instructions if code doesn't work
  Future<void> sendMfaOtp(String to, String otp);

  /// Sends a security alert about suspicious account activity.
  /// 
  /// The [to] parameter is the user's email address.
  /// The [message] describes the suspicious activity detected
  /// (e.g., "Login from new device", "Multiple failed login attempts").
  /// 
  /// The email should include:
  /// - Description of the suspicious activity
  /// - Timestamp and location (if available)
  /// - Instructions for securing the account
  /// - Contact information if activity was unauthorized
  Future<void> sendSecurityAlert(String to, String message);
}
