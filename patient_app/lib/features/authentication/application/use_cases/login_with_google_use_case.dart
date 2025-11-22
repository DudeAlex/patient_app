import 'package:uuid/uuid.dart';
import '../../domain/entities/auth_method.dart';
import '../../domain/entities/login_attempt.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/user.dart';
import '../../infrastructure/services/token_generator.dart';
import '../ports/auth_repository.dart';
import '../ports/google_auth_gateway.dart';

/// Use case for authenticating a user with Google Sign-In.
/// 
/// Handles the complete Google OAuth flow including account creation,
/// account linking, session creation, and audit logging.
/// 
/// Requirements addressed:
/// - 3.1: Initiate Google OAuth 2.0 flow
/// - 3.2: Create or link user account using Google email
/// - 3.3: Display error on Google auth failure
/// - 3.5: Merge accounts when Google email matches existing account
class LoginWithGoogleUseCase {
  final AuthRepository _repository;
  final GoogleAuthGateway _googleAuthGateway;
  final TokenGenerator _tokenGenerator;
  final Uuid _uuid;

  /// Session expiration duration (24 hours)
  static const Duration _sessionDuration = Duration(hours: 24);

  LoginWithGoogleUseCase({
    required AuthRepository repository,
    required GoogleAuthGateway googleAuthGateway,
    required TokenGenerator tokenGenerator,
    Uuid? uuid,
  })  : _repository = repository,
        _googleAuthGateway = googleAuthGateway,
        _tokenGenerator = tokenGenerator,
        _uuid = uuid ?? const Uuid();

  /// Authenticates a user with Google Sign-In.
  /// 
  /// [deviceInfo] Information about the device making the request
  /// [ipAddress] Optional IP address for audit logging
  /// 
  /// Returns a [GoogleLoginResult] indicating success or failure.
  /// 
  /// Process:
  /// 1. Initiate Google OAuth flow via GoogleAuthGateway
  /// 2. Handle Google authentication result
  /// 3. Find existing user by Google email
  /// 4. If user exists: link Google account if not already linked
  /// 5. If user doesn't exist: create new user with Google account
  /// 6. Create session
  /// 7. Record login attempt for audit
  /// 
  /// Example:
  /// ```dart
  /// final useCase = LoginWithGoogleUseCase(...);
  /// final result = await useCase.execute(
  ///   deviceInfo: 'iPhone 13, iOS 16.0',
  ///   ipAddress: '192.168.1.1',
  /// );
  /// 
  /// if (result.isSuccess) {
  ///   print('Login successful: ${result.session!.token}');
  /// } else {
  ///   print('Login failed: ${result.error}');
  /// }
  /// ```
  Future<GoogleLoginResult> execute({
    required String deviceInfo,
    String? ipAddress,
  }) async {
    final attemptId = _uuid.v4();
    final attemptedAt = DateTime.now();

    try {
      // Step 1: Initiate Google OAuth flow (Requirement 3.1)
      final googleResult = await _googleAuthGateway.signIn();

      // Step 2: Handle Google authentication result (Requirement 3.3)
      if (!googleResult.success || googleResult.email == null || googleResult.googleId == null) {
        // Google authentication failed
        final errorMessage = googleResult.error ?? 'Google authentication failed';
        
        // Record failed attempt (use empty string for email since we don't have it)
        await _recordFailedAttempt(
          attemptId: attemptId,
          email: googleResult.email ?? 'unknown',
          deviceInfo: deviceInfo,
          ipAddress: ipAddress,
          errorMessage: errorMessage,
          attemptedAt: attemptedAt,
        );
        
        return GoogleLoginResult.failure(
          GoogleLoginError.googleAuthFailed(errorMessage),
        );
      }

      final googleEmail = googleResult.email!;
      final googleId = googleResult.googleId!;

      // Step 3: Find existing user by Google email (Requirement 3.2)
      final existingUser = await _repository.findUserByEmail(googleEmail);

      final User user;
      
      if (existingUser != null) {
        // Step 4: User exists - link Google account if not already linked (Requirement 3.5)
        if (existingUser.googleAccountId == null) {
          // Link Google account to existing email/password account
          user = existingUser.copyWith(
            googleAccountId: googleId,
            isEmailVerified: true, // Google email is already verified
          );
          await _repository.updateUser(user);
        } else if (existingUser.googleAccountId != googleId) {
          // Google ID mismatch - this shouldn't happen but handle it
          await _recordFailedAttempt(
            attemptId: attemptId,
            email: googleEmail,
            deviceInfo: deviceInfo,
            ipAddress: ipAddress,
            errorMessage: 'Google account ID mismatch',
            attemptedAt: attemptedAt,
          );
          
          return GoogleLoginResult.failure(
            GoogleLoginError.accountMismatch(),
          );
        } else {
          // Google account already linked - use existing user
          user = existingUser;
        }
      } else {
        // Step 5: User doesn't exist - create new user (Requirement 3.2)
        final newUser = User(
          id: _uuid.v4(),
          email: googleEmail,
          passwordHash: null, // No password for Google-only accounts
          isEmailVerified: true, // Google email is already verified
          isMfaEnabled: false,
          isBiometricEnabled: false,
          googleAccountId: googleId,
          createdAt: attemptedAt,
          lastLoginAt: null,
        );
        
        user = await _repository.createUser(newUser);
      }

      // Step 6: Create session
      final session = await _createSession(
        user: user,
        deviceInfo: deviceInfo,
        ipAddress: ipAddress,
      );

      // Step 7: Record successful login attempt
      await _recordSuccessfulAttempt(
        attemptId: attemptId,
        email: googleEmail,
        deviceInfo: deviceInfo,
        ipAddress: ipAddress,
        attemptedAt: attemptedAt,
      );

      // Update user's last login timestamp
      final updatedUser = user.copyWith(lastLoginAt: attemptedAt);
      await _repository.updateUser(updatedUser);

      return GoogleLoginResult.success(session, isNewUser: existingUser == null);
    } catch (e) {
      // Handle unexpected errors
      await _recordFailedAttempt(
        attemptId: attemptId,
        email: 'unknown',
        deviceInfo: deviceInfo,
        ipAddress: ipAddress,
        errorMessage: 'Unexpected error: $e',
        attemptedAt: attemptedAt,
      );
      
      return GoogleLoginResult.failure(
        GoogleLoginError.unknown('An unexpected error occurred'),
      );
    }
  }

  /// Creates a new session for the authenticated user.
  /// 
  /// Generates a secure token and sets expiration to 24 hours.
  Future<Session> _createSession({
    required User user,
    required String deviceInfo,
    String? ipAddress,
  }) async {
    final now = DateTime.now();
    final token = _tokenGenerator.generateToken(length: 32);
    
    final session = Session(
      id: _uuid.v4(),
      userId: user.id,
      token: token,
      deviceInfo: deviceInfo,
      ipAddress: ipAddress,
      createdAt: now,
      expiresAt: now.add(_sessionDuration),
      lastActivityAt: now,
      isActive: true,
    );

    return await _repository.createSession(session);
  }

  /// Records a failed login attempt for audit logging.
  Future<void> _recordFailedAttempt({
    required String attemptId,
    required String email,
    required String deviceInfo,
    String? ipAddress,
    required String errorMessage,
    required DateTime attemptedAt,
  }) async {
    final attempt = LoginAttempt(
      id: attemptId,
      email: email,
      success: false,
      authMethod: AuthMethod.google,
      deviceInfo: deviceInfo,
      ipAddress: ipAddress,
      errorMessage: errorMessage,
      attemptedAt: attemptedAt,
    );

    await _repository.addLoginAttempt(attempt);
  }

  /// Records a successful login attempt for audit logging.
  Future<void> _recordSuccessfulAttempt({
    required String attemptId,
    required String email,
    required String deviceInfo,
    String? ipAddress,
    required DateTime attemptedAt,
  }) async {
    final attempt = LoginAttempt(
      id: attemptId,
      email: email,
      success: true,
      authMethod: AuthMethod.google,
      deviceInfo: deviceInfo,
      ipAddress: ipAddress,
      errorMessage: null,
      attemptedAt: attemptedAt,
    );

    await _repository.addLoginAttempt(attempt);
  }
}

/// Result of a Google Sign-In login attempt.
class GoogleLoginResult {
  /// The created session (null if login failed)
  final Session? session;
  
  /// Error details (null if login succeeded)
  final GoogleLoginError? error;
  
  /// Whether this was a new user registration
  final bool isNewUser;
  
  /// Whether the login was successful
  bool get isSuccess => session != null && error == null;
  
  /// Whether the login failed
  bool get isFailure => error != null;

  const GoogleLoginResult._({
    this.session,
    this.error,
    this.isNewUser = false,
  });

  /// Creates a successful login result with a session
  factory GoogleLoginResult.success(Session session, {required bool isNewUser}) {
    return GoogleLoginResult._(session: session, isNewUser: isNewUser);
  }

  /// Creates a failed login result with an error
  factory GoogleLoginResult.failure(GoogleLoginError error) {
    return GoogleLoginResult._(error: error);
  }
}

/// Represents errors that can occur during Google Sign-In login.
class GoogleLoginError {
  /// The type of error that occurred
  final GoogleLoginErrorType type;
  
  /// Human-readable error message
  final String message;

  const GoogleLoginError._({
    required this.type,
    required this.message,
  });

  /// Google authentication failed (user cancelled or OAuth error)
  factory GoogleLoginError.googleAuthFailed(String details) {
    return GoogleLoginError._(
      type: GoogleLoginErrorType.googleAuthFailed,
      message: 'Google authentication failed: $details',
    );
  }

  /// Google account ID doesn't match existing linked account
  factory GoogleLoginError.accountMismatch() {
    return const GoogleLoginError._(
      type: GoogleLoginErrorType.accountMismatch,
      message: 'This Google account is linked to a different user',
    );
  }

  /// Unknown or unexpected error
  factory GoogleLoginError.unknown(String message) {
    return GoogleLoginError._(
      type: GoogleLoginErrorType.unknown,
      message: message,
    );
  }

  @override
  String toString() => message;
}

/// Types of errors that can occur during Google Sign-In login.
enum GoogleLoginErrorType {
  /// Google authentication failed
  googleAuthFailed,
  
  /// Google account ID mismatch
  accountMismatch,
  
  /// Unknown or unexpected error
  unknown,
}
