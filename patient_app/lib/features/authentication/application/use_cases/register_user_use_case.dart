import 'package:uuid/uuid.dart';
import '../../domain/entities/user.dart';
import '../../domain/value_objects/email.dart';
import '../../domain/value_objects/password.dart';
import '../../infrastructure/services/password_hasher.dart';
import '../../infrastructure/services/token_generator.dart';
import '../ports/auth_repository.dart';
import '../ports/email_gateway.dart';

/// Use case for registering a new user account.
/// 
/// Handles the complete registration flow including validation,
/// password hashing, user creation, and email verification.
/// 
/// Requirements addressed:
/// - 1.1: Create account with valid email and password
/// - 1.2: Prevent duplicate email addresses
/// - 1.3: Enforce password security requirements
/// - 1.4: Send verification email
class RegisterUserUseCase {
  final AuthRepository _repository;
  final PasswordHasher _passwordHasher;
  final EmailGateway _emailGateway;
  final TokenGenerator _tokenGenerator;
  final Uuid _uuid;

  RegisterUserUseCase({
    required AuthRepository repository,
    required PasswordHasher passwordHasher,
    required EmailGateway emailGateway,
    required TokenGenerator tokenGenerator,
    Uuid? uuid,
  })  : _repository = repository,
        _passwordHasher = passwordHasher,
        _emailGateway = emailGateway,
        _tokenGenerator = tokenGenerator,
        _uuid = uuid ?? const Uuid();

  /// Registers a new user with email and password.
  /// 
  /// [emailString] The user's email address (will be validated)
  /// [passwordString] The user's password (will be validated)
  /// [baseUrl] The base URL for generating the verification link
  /// 
  /// Returns a [RegisterResult] indicating success or failure.
  /// 
  /// Process:
  /// 1. Validate email format
  /// 2. Validate password strength
  /// 3. Check if email already exists
  /// 4. Hash the password
  /// 5. Create user entity
  /// 6. Save to repository
  /// 7. Generate verification token
  /// 8. Send verification email
  /// 
  /// Example:
  /// ```dart
  /// final useCase = RegisterUserUseCase(...);
  /// final result = await useCase.execute(
  ///   'user@example.com',
  ///   'SecureP@ss123',
  ///   'https://app.example.com',
  /// );
  /// 
  /// if (result.isSuccess) {
  ///   print('User registered: ${result.user!.id}');
  /// } else {
  ///   print('Registration failed: ${result.error}');
  /// }
  /// ```
  Future<RegisterResult> execute({
    required String emailString,
    required String passwordString,
    required String baseUrl,
  }) async {
    try {
      // Step 1: Validate email format (Requirement 1.1)
      final Email email;
      try {
        email = Email.create(emailString);
      } on InvalidEmailException catch (e) {
        return RegisterResult.failure(
          RegisterError.invalidEmail(e.message),
        );
      }

      // Step 2: Validate password strength (Requirement 1.3)
      final Password password;
      try {
        password = Password.create(passwordString);
      } on WeakPasswordException catch (e) {
        return RegisterResult.failure(
          RegisterError.weakPassword(e.errors),
        );
      }

      // Step 3: Check if email already exists (Requirement 1.2)
      final existingUser = await _repository.findUserByEmail(email.value);
      if (existingUser != null) {
        return RegisterResult.failure(
          RegisterError.emailAlreadyExists(),
        );
      }

      // Step 4: Hash the password securely (Requirement 1.1)
      final passwordHash = await _passwordHasher.hashPassword(password.value);

      // Step 5: Create user entity
      final now = DateTime.now();
      final user = User(
        id: _uuid.v4(),
        email: email.value,
        passwordHash: passwordHash,
        isEmailVerified: false, // Requires verification (Requirement 1.4)
        isMfaEnabled: false,
        isBiometricEnabled: false,
        googleAccountId: null,
        createdAt: now,
        lastLoginAt: null,
      );

      // Step 6: Save user to repository
      final createdUser = await _repository.createUser(user);

      // Step 7: Generate verification token (Requirement 1.4)
      final verificationToken = _tokenGenerator.generateToken(length: 32);
      
      // Step 8: Send verification email (Requirement 1.4)
      final verificationLink = '$baseUrl/verify-email?token=$verificationToken&userId=${createdUser.id}';
      await _emailGateway.sendVerificationEmail(
        createdUser.email,
        verificationLink,
      );

      return RegisterResult.success(createdUser);
    } catch (e) {
      // Handle unexpected errors
      return RegisterResult.failure(
        RegisterError.unknown('An unexpected error occurred: $e'),
      );
    }
  }
}

/// Result of a user registration attempt.
class RegisterResult {
  /// The registered user (null if registration failed)
  final User? user;
  
  /// Error details (null if registration succeeded)
  final RegisterError? error;
  
  /// Whether the registration was successful
  bool get isSuccess => user != null && error == null;
  
  /// Whether the registration failed
  bool get isFailure => !isSuccess;

  const RegisterResult._({
    this.user,
    this.error,
  });

  /// Creates a successful registration result
  factory RegisterResult.success(User user) {
    return RegisterResult._(user: user);
  }

  /// Creates a failed registration result
  factory RegisterResult.failure(RegisterError error) {
    return RegisterResult._(error: error);
  }
}

/// Represents errors that can occur during user registration.
class RegisterError {
  /// The type of error that occurred
  final RegisterErrorType type;
  
  /// Human-readable error message
  final String message;
  
  /// Additional error details (e.g., list of password validation errors)
  final List<String>? details;

  const RegisterError._({
    required this.type,
    required this.message,
    this.details,
  });

  /// Email format is invalid
  factory RegisterError.invalidEmail(String message) {
    return RegisterError._(
      type: RegisterErrorType.invalidEmail,
      message: message,
    );
  }

  /// Password doesn't meet security requirements
  factory RegisterError.weakPassword(List<String> validationErrors) {
    return RegisterError._(
      type: RegisterErrorType.weakPassword,
      message: 'Password does not meet security requirements',
      details: validationErrors,
    );
  }

  /// Email address is already registered
  factory RegisterError.emailAlreadyExists() {
    return RegisterError._(
      type: RegisterErrorType.emailAlreadyExists,
      message: 'An account with this email address already exists',
    );
  }

  /// Unknown or unexpected error
  factory RegisterError.unknown(String message) {
    return RegisterError._(
      type: RegisterErrorType.unknown,
      message: message,
    );
  }

  @override
  String toString() {
    if (details != null && details!.isNotEmpty) {
      return '$message: ${details!.join(', ')}';
    }
    return message;
  }
}

/// Types of errors that can occur during registration.
enum RegisterErrorType {
  /// Email format is invalid
  invalidEmail,
  
  /// Password doesn't meet security requirements
  weakPassword,
  
  /// Email address is already registered
  emailAlreadyExists,
  
  /// Unknown or unexpected error
  unknown,
}
