import 'package:uuid/uuid.dart';
import '../../domain/entities/auth_method.dart';
import '../../domain/entities/login_attempt.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/user.dart';
import '../../domain/value_objects/email.dart';
import '../../domain/value_objects/password.dart';
import '../../infrastructure/services/password_hasher.dart';
import '../../infrastructure/services/token_generator.dart';
import '../ports/auth_repository.dart';

/// Use case for authenticating a user with email and password.
/// 
/// Handles the complete login flow including rate limiting, credential
/// verification, MFA detection, session creation, and audit logging.
/// 
/// Requirements addressed:
/// - 2.1: Authenticate with valid credentials and create session
/// - 2.2: Display error for invalid credentials without revealing which field was wrong
/// - 2.3: Lock account after 3 consecutive failures for 15 minutes
/// - 2.4: Limit authentication attempts to 5 per minute per IP
/// - 2.5: Generate secure session token with 24-hour expiration
/// - 4.4: Prompt for secondary authentication when MFA is enabled
class LoginWithEmailUseCase {
  final AuthRepository _repository;
  final PasswordHasher _passwordHasher;
  final TokenGenerator _tokenGenerator;
  final Uuid _uuid;

  /// Rate limiting: maximum attempts per minute per IP
  static const int _maxAttemptsPerMinute = 5;
  
  /// Account lockout: number of consecutive failures before lockout
  static const int _maxConsecutiveFailures = 3;
  
  /// Account lockout duration
  static const Duration _lockoutDuration = Duration(minutes: 15);
  
  /// Session expiration duration (24 hours)
  static const Duration _sessionDuration = Duration(hours: 24);

  LoginWithEmailUseCase({
    required AuthRepository repository,
    required PasswordHasher passwordHasher,
    required TokenGenerator tokenGenerator,
    Uuid? uuid,
  })  : _repository = repository,
        _passwordHasher = passwordHasher,
        _tokenGenerator = tokenGenerator,
        _uuid = uuid ?? const Uuid();

  /// Authenticates a user with email and password.
  /// 
  /// [emailString] The user's email address
  /// [passwordString] The user's password
  /// [deviceInfo] Information about the device making the request
  /// [ipAddress] Optional IP address for rate limiting
  /// 
  /// Returns a [LoginResult] indicating success, failure, or MFA required.
  /// 
  /// Process:
  /// 1. Validate email and password format
  /// 2. Check rate limiting (5 attempts per minute)
  /// 3. Check account lockout (3 consecutive failures)
  /// 4. Find user by email
  /// 5. Verify password hash
  /// 6. Check if MFA is enabled
  /// 7. Create session if no MFA, or return pending MFA state
  /// 8. Record login attempt for audit
  /// 
  /// Example:
  /// ```dart
  /// final useCase = LoginWithEmailUseCase(...);
  /// final result = await useCase.execute(
  ///   emailString: 'user@example.com',
  ///   passwordString: 'SecureP@ss123',
  ///   deviceInfo: 'iPhone 13, iOS 16.0',
  ///   ipAddress: '192.168.1.1',
  /// );
  /// 
  /// if (result.isSuccess) {
  ///   print('Login successful: ${result.session!.token}');
  /// } else if (result.isMfaRequired) {
  ///   print('MFA required: ${result.pendingUserId}');
  /// } else {
  ///   print('Login failed: ${result.error}');
  /// }
  /// ```
  Future<LoginResult> execute({
    required String emailString,
    required String passwordString,
    required String deviceInfo,
    String? ipAddress,
  }) async {
    final attemptId = _uuid.v4();
    final attemptedAt = DateTime.now();

    try {
      // Step 1: Validate email format
      final Email email;
      try {
        email = Email.create(emailString);
      } on InvalidEmailException catch (e) {
        // Record failed attempt
        await _recordFailedAttempt(
          attemptId: attemptId,
          email: emailString,
          deviceInfo: deviceInfo,
          ipAddress: ipAddress,
          errorMessage: 'Invalid email format',
          attemptedAt: attemptedAt,
        );
        
        return LoginResult.failure(
          LoginError.invalidCredentials(),
        );
      }

      // Step 2: Check rate limiting (Requirement 2.4)
      // Count attempts in the last minute
      final recentAttempts = await _repository.countFailedAttempts(
        email.value,
        const Duration(minutes: 1),
      );
      
      if (recentAttempts >= _maxAttemptsPerMinute) {
        await _recordFailedAttempt(
          attemptId: attemptId,
          email: email.value,
          deviceInfo: deviceInfo,
          ipAddress: ipAddress,
          errorMessage: 'Rate limit exceeded',
          attemptedAt: attemptedAt,
        );
        
        return LoginResult.failure(
          LoginError.rateLimitExceeded(),
        );
      }

      // Step 3: Check account lockout (Requirement 2.3)
      // Count consecutive failures in the last 15 minutes
      final consecutiveFailures = await _repository.countFailedAttempts(
        email.value,
        _lockoutDuration,
      );
      
      if (consecutiveFailures >= _maxConsecutiveFailures) {
        await _recordFailedAttempt(
          attemptId: attemptId,
          email: email.value,
          deviceInfo: deviceInfo,
          ipAddress: ipAddress,
          errorMessage: 'Account locked due to too many failed attempts',
          attemptedAt: attemptedAt,
        );
        
        return LoginResult.failure(
          LoginError.accountLocked(_lockoutDuration),
        );
      }

      // Step 4: Find user by email
      final user = await _repository.findUserByEmail(email.value);
      
      if (user == null) {
        // User not found - record failed attempt
        // Don't reveal whether email exists (Requirement 2.2)
        await _recordFailedAttempt(
          attemptId: attemptId,
          email: email.value,
          deviceInfo: deviceInfo,
          ipAddress: ipAddress,
          errorMessage: 'Invalid credentials',
          attemptedAt: attemptedAt,
        );
        
        return LoginResult.failure(
          LoginError.invalidCredentials(),
        );
      }

      // Step 5: Verify password hash
      if (user.passwordHash == null) {
        // User registered with Google only, no password set
        await _recordFailedAttempt(
          attemptId: attemptId,
          email: email.value,
          deviceInfo: deviceInfo,
          ipAddress: ipAddress,
          errorMessage: 'No password set for this account',
          attemptedAt: attemptedAt,
        );
        
        return LoginResult.failure(
          LoginError.invalidCredentials(),
        );
      }

      final isPasswordValid = await _passwordHasher.verifyPassword(
        passwordString,
        user.passwordHash!,
      );

      if (!isPasswordValid) {
        // Invalid password - record failed attempt
        // Don't reveal that email was correct (Requirement 2.2)
        await _recordFailedAttempt(
          attemptId: attemptId,
          email: email.value,
          deviceInfo: deviceInfo,
          ipAddress: ipAddress,
          errorMessage: 'Invalid credentials',
          attemptedAt: attemptedAt,
        );
        
        return LoginResult.failure(
          LoginError.invalidCredentials(),
        );
      }

      // Step 6: Check if MFA is enabled (Requirement 4.4)
      if (user.isMfaEnabled) {
        // Record successful primary authentication
        await _recordSuccessfulAttempt(
          attemptId: attemptId,
          email: email.value,
          deviceInfo: deviceInfo,
          ipAddress: ipAddress,
          attemptedAt: attemptedAt,
        );
        
        // Return MFA required state - session will be created after MFA verification
        return LoginResult.mfaRequired(
          userId: user.id,
          deviceInfo: deviceInfo,
          ipAddress: ipAddress,
        );
      }

      // Step 7: Create session (Requirement 2.1, 2.5)
      final session = await _createSession(
        user: user,
        deviceInfo: deviceInfo,
        ipAddress: ipAddress,
      );

      // Step 8: Record successful login attempt
      await _recordSuccessfulAttempt(
        attemptId: attemptId,
        email: email.value,
        deviceInfo: deviceInfo,
        ipAddress: ipAddress,
        attemptedAt: attemptedAt,
      );

      // Update user's last login timestamp
      final updatedUser = user.copyWith(lastLoginAt: attemptedAt);
      await _repository.updateUser(updatedUser);

      return LoginResult.success(session);
    } catch (e) {
      // Handle unexpected errors
      await _recordFailedAttempt(
        attemptId: attemptId,
        email: emailString,
        deviceInfo: deviceInfo,
        ipAddress: ipAddress,
        errorMessage: 'Unexpected error: $e',
        attemptedAt: attemptedAt,
      );
      
      return LoginResult.failure(
        LoginError.unknown('An unexpected error occurred'),
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
      authMethod: AuthMethod.emailPassword,
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
      authMethod: AuthMethod.emailPassword,
      deviceInfo: deviceInfo,
      ipAddress: ipAddress,
      errorMessage: null,
      attemptedAt: attemptedAt,
    );

    await _repository.addLoginAttempt(attempt);
  }
}


/// Result of a login attempt with email and password.
class LoginResult {
  /// The created session (null if login failed or MFA required)
  final Session? session;
  
  /// Error details (null if login succeeded or MFA required)
  final LoginError? error;
  
  /// User ID when MFA is required (null otherwise)
  final String? pendingUserId;
  
  /// Device info for MFA verification
  final String? pendingDeviceInfo;
  
  /// IP address for MFA verification
  final String? pendingIpAddress;
  
  /// Whether the login was successful
  bool get isSuccess => session != null && error == null && pendingUserId == null;
  
  /// Whether the login failed
  bool get isFailure => error != null;
  
  /// Whether MFA verification is required
  bool get isMfaRequired => pendingUserId != null && error == null;

  const LoginResult._({
    this.session,
    this.error,
    this.pendingUserId,
    this.pendingDeviceInfo,
    this.pendingIpAddress,
  });

  /// Creates a successful login result with a session
  factory LoginResult.success(Session session) {
    return LoginResult._(session: session);
  }

  /// Creates a failed login result with an error
  factory LoginResult.failure(LoginError error) {
    return LoginResult._(error: error);
  }

  /// Creates a result indicating MFA is required
  factory LoginResult.mfaRequired({
    required String userId,
    required String deviceInfo,
    String? ipAddress,
  }) {
    return LoginResult._(
      pendingUserId: userId,
      pendingDeviceInfo: deviceInfo,
      pendingIpAddress: ipAddress,
    );
  }
}

/// Represents errors that can occur during email/password login.
class LoginError {
  /// The type of error that occurred
  final LoginErrorType type;
  
  /// Human-readable error message
  final String message;
  
  /// Additional error details (e.g., lockout duration)
  final Duration? lockoutDuration;

  const LoginError._({
    required this.type,
    required this.message,
    this.lockoutDuration,
  });

  /// Invalid email or password (doesn't reveal which)
  factory LoginError.invalidCredentials() {
    return const LoginError._(
      type: LoginErrorType.invalidCredentials,
      message: 'Invalid email or password',
    );
  }

  /// Account locked due to too many failed attempts
  factory LoginError.accountLocked(Duration duration) {
    return LoginError._(
      type: LoginErrorType.accountLocked,
      message: 'Account temporarily locked due to too many failed attempts. '
          'Please try again in ${duration.inMinutes} minutes.',
      lockoutDuration: duration,
    );
  }

  /// Rate limit exceeded (too many attempts per minute)
  factory LoginError.rateLimitExceeded() {
    return const LoginError._(
      type: LoginErrorType.rateLimitExceeded,
      message: 'Too many login attempts. Please try again later.',
    );
  }

  /// Unknown or unexpected error
  factory LoginError.unknown(String message) {
    return LoginError._(
      type: LoginErrorType.unknown,
      message: message,
    );
  }

  @override
  String toString() => message;
}

/// Types of errors that can occur during login.
enum LoginErrorType {
  /// Invalid email or password
  invalidCredentials,
  
  /// Account locked due to too many failed attempts
  accountLocked,
  
  /// Rate limit exceeded
  rateLimitExceeded,
  
  /// Unknown or unexpected error
  unknown,
}
