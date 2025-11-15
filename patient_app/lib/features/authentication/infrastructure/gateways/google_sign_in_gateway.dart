import 'package:google_drive_backup/google_drive_backup.dart';
import '../../application/ports/google_auth_gateway.dart';

/// Implementation of GoogleAuthGateway using existing GoogleAuthService.
/// Reuses the Google authentication logic from the google_drive_backup package.
class GoogleSignInGateway implements GoogleAuthGateway {
  final GoogleAuthService _googleAuthService;

  GoogleSignInGateway({GoogleAuthService? googleAuthService})
      : _googleAuthService = googleAuthService ?? GoogleAuthService();

  @override
  Future<GoogleAuthResult> signIn() async {
    try {
      // Use existing GoogleAuthService to perform sign-in
      final account = await _googleAuthService.signIn();

      if (account == null) {
        return GoogleAuthResult(
          success: false,
          email: null,
          googleId: null,
          error: 'Google sign-in failed or was cancelled',
        );
      }

      // Extract email and Google ID from the account
      final email = account.email;
      final googleId = account.id;

      return GoogleAuthResult(
        success: true,
        email: email,
        googleId: googleId,
        error: null,
      );
    } catch (e) {
      return GoogleAuthResult(
        success: false,
        email: null,
        googleId: null,
        error: 'Google sign-in error: $e',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleAuthService.signOut();
    } catch (e) {
      throw GoogleAuthException('Failed to sign out: $e');
    }
  }

  @override
  Future<String?> getCurrentUserEmail() async {
    try {
      // Use tryGetEmail to get cached or lightweight auth email
      return await _googleAuthService.tryGetEmail();
    } catch (e) {
      return null;
    }
  }
}

/// Exception thrown when Google authentication operations fail.
class GoogleAuthException implements Exception {
  final String message;
  GoogleAuthException(this.message);

  @override
  String toString() => 'GoogleAuthException: $message';
}
