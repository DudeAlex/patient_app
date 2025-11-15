/// Result of a Google Sign-In authentication attempt.
/// 
/// Contains the outcome of the authentication flow including user
/// information on success or error details on failure.
class GoogleAuthResult {
  /// Whether the authentication was successful
  final bool success;
  
  /// User's email address from Google account (null on failure)
  final String? email;
  
  /// Google account unique identifier (null on failure)
  final String? googleId;
  
  /// Error message if authentication failed (null on success)
  final String? error;

  const GoogleAuthResult({
    required this.success,
    this.email,
    this.googleId,
    this.error,
  });

  /// Creates a successful authentication result
  factory GoogleAuthResult.success({
    required String email,
    required String googleId,
  }) {
    return GoogleAuthResult(
      success: true,
      email: email,
      googleId: googleId,
    );
  }

  /// Creates a failed authentication result
  factory GoogleAuthResult.failure(String error) {
    return GoogleAuthResult(
      success: false,
      error: error,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'GoogleAuthResult.success(email: $email, googleId: $googleId)';
    } else {
      return 'GoogleAuthResult.failure(error: $error)';
    }
  }
}

/// Port (interface) for Google Sign-In authentication.
/// 
/// This interface abstracts Google OAuth 2.0 authentication flow.
/// Implementations wrap the Google Sign-In SDK while use cases
/// depend only on this abstraction. The existing GoogleAuthService
/// from the google_drive_backup package can be adapted to implement
/// this interface.
abstract class GoogleAuthGateway {
  /// Initiates the Google Sign-In flow.
  /// 
  /// Displays the Google account picker and OAuth consent screen.
  /// Returns a [GoogleAuthResult] containing user information on success
  /// or error details on failure.
  /// 
  /// The user may cancel the flow, in which case this returns a failure
  /// result. Network errors or OAuth failures also return failure results.
  Future<GoogleAuthResult> signIn();

  /// Signs out the current Google user.
  /// 
  /// Clears the cached Google authentication state.
  /// Used during logout to ensure the user must re-authenticate
  /// with Google on the next sign-in attempt.
  Future<void> signOut();

  /// Gets the email of the currently signed-in Google user.
  /// 
  /// Returns the email address if a user is currently signed in,
  /// null otherwise. Used for checking existing authentication state
  /// on app launch.
  Future<String?> getCurrentUserEmail();
}
