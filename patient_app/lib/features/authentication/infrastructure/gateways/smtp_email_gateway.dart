import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../../application/ports/email_gateway.dart';

/// Implementation of EmailGateway using SMTP via the mailer package.
/// Sends authentication-related emails (verification, password reset, MFA OTP, security alerts).
class SmtpEmailGateway implements EmailGateway {
  final String _smtpHost;
  final int _smtpPort;
  final String _username;
  final String _password;
  final String _fromEmail;
  final String _fromName;

  SmtpEmailGateway({
    required String smtpHost,
    required int smtpPort,
    required String username,
    required String password,
    required String fromEmail,
    String fromName = 'Patient App',
  })  : _smtpHost = smtpHost,
        _smtpPort = smtpPort,
        _username = username,
        _password = password,
        _fromEmail = fromEmail,
        _fromName = fromName;

  /// Get configured SMTP server
  SmtpServer get _smtpServer {
    return SmtpServer(
      _smtpHost,
      port: _smtpPort,
      username: _username,
      password: _password,
      ssl: _smtpPort == 465, // Use SSL for port 465
      allowInsecure: false,
    );
  }

  @override
  Future<void> sendVerificationEmail(String to, String verificationLink) async {
    final message = Message()
      ..from = Address(_fromEmail, _fromName)
      ..recipients.add(to)
      ..subject = 'Verify Your Patient App Account'
      ..html = _buildVerificationEmailHtml(verificationLink);

    await _sendEmail(message);
  }

  @override
  Future<void> sendPasswordResetEmail(String to, String resetLink) async {
    final message = Message()
      ..from = Address(_fromEmail, _fromName)
      ..recipients.add(to)
      ..subject = 'Reset Your Patient App Password'
      ..html = _buildPasswordResetEmailHtml(resetLink);

    await _sendEmail(message);
  }

  @override
  Future<void> sendMfaOtp(String to, String otp) async {
    final message = Message()
      ..from = Address(_fromEmail, _fromName)
      ..recipients.add(to)
      ..subject = 'Your Patient App Verification Code'
      ..html = _buildMfaOtpEmailHtml(otp);

    await _sendEmail(message);
  }

  @override
  Future<void> sendSecurityAlert(String to, String alertMessage) async {
    final message = Message()
      ..from = Address(_fromEmail, _fromName)
      ..recipients.add(to)
      ..subject = 'Security Alert - Patient App'
      ..html = _buildSecurityAlertEmailHtml(alertMessage);

    await _sendEmail(message);
  }

  /// Send email using SMTP server
  Future<void> _sendEmail(Message message) async {
    try {
      // Send email via SMTP
      // If send() completes without throwing, the email was sent successfully
      await send(message, _smtpServer);
    } on MailerException catch (e) {
      throw EmailException('SMTP error: ${e.message}');
    } catch (e) {
      throw EmailException('Failed to send email: $e');
    }
  }

  /// Build HTML template for verification email
  String _buildVerificationEmailHtml(String verificationLink) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="background-color: #f4f4f4; padding: 20px; border-radius: 5px;">
    <h2 style="color: #2c3e50;">Welcome to Patient App!</h2>
    <p>Thank you for registering. Please verify your email address to complete your account setup.</p>
    <div style="text-align: center; margin: 30px 0;">
      <a href="$verificationLink" style="background-color: #3498db; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">Verify Email</a>
    </div>
    <p style="color: #7f8c8d; font-size: 14px;">If you didn't create this account, please ignore this email.</p>
    <p style="color: #7f8c8d; font-size: 14px;">This link will expire in 24 hours.</p>
  </div>
</body>
</html>
''';
  }

  /// Build HTML template for password reset email
  String _buildPasswordResetEmailHtml(String resetLink) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="background-color: #f4f4f4; padding: 20px; border-radius: 5px;">
    <h2 style="color: #2c3e50;">Password Reset Request</h2>
    <p>We received a request to reset your Patient App password.</p>
    <div style="text-align: center; margin: 30px 0;">
      <a href="$resetLink" style="background-color: #e74c3c; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">Reset Password</a>
    </div>
    <p style="color: #7f8c8d; font-size: 14px;">If you didn't request this, please ignore this email. Your password will remain unchanged.</p>
    <p style="color: #7f8c8d; font-size: 14px;">This link will expire in 1 hour.</p>
  </div>
</body>
</html>
''';
  }

  /// Build HTML template for MFA OTP email
  String _buildMfaOtpEmailHtml(String otp) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="background-color: #f4f4f4; padding: 20px; border-radius: 5px;">
    <h2 style="color: #2c3e50;">Your Verification Code</h2>
    <p>Use the following code to complete your login:</p>
    <div style="text-align: center; margin: 30px 0;">
      <div style="background-color: white; padding: 20px; border-radius: 5px; font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #2c3e50;">$otp</div>
    </div>
    <p style="color: #7f8c8d; font-size: 14px;">This code will expire in 5 minutes.</p>
    <p style="color: #7f8c8d; font-size: 14px;">If you didn't request this code, please secure your account immediately.</p>
  </div>
</body>
</html>
''';
  }

  /// Build HTML template for security alert email
  String _buildSecurityAlertEmailHtml(String alertMessage) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="background-color: #fff3cd; padding: 20px; border-radius: 5px; border-left: 4px solid #ffc107;">
    <h2 style="color: #856404;">Security Alert</h2>
    <p>$alertMessage</p>
    <p style="margin-top: 20px;">If this was you, you can safely ignore this email. If you don't recognize this activity, please secure your account immediately.</p>
    <div style="text-align: center; margin: 30px 0;">
      <a href="#" style="background-color: #ffc107; color: #212529; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">Review Account Activity</a>
    </div>
    <p style="color: #856404; font-size: 14px;">For your security, we recommend:</p>
    <ul style="color: #856404; font-size: 14px;">
      <li>Changing your password if you suspect unauthorized access</li>
      <li>Enabling multi-factor authentication</li>
      <li>Reviewing your active sessions</li>
    </ul>
  </div>
</body>
</html>
''';
  }
}

/// Exception thrown when email operations fail.
class EmailException implements Exception {
  final String message;
  EmailException(this.message);

  @override
  String toString() => 'EmailException: $message';
}
