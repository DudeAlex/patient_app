# Design Document

## Overview

The authentication system provides secure, multi-method user authentication for the Patient App. It follows clean architecture principles with clear separation between domain logic, application use cases, and infrastructure adapters. The design supports email/password authentication, Google Sign-In, biometric authentication, and multi-factor authentication (MFA) while maintaining security best practices.

## Architecture

### Layer Structure

```
lib/features/authentication/
├── domain/
│   ├── entities/
│   │   ├── user.dart                    # User entity
│   │   ├── session.dart                 # Session entity
│   │   ├── auth_method.dart             # Authentication method types
│   │   └── login_attempt.dart           # Login history entry
│   └── value_objects/
│       ├── email.dart                   # Email validation
│       ├── password.dart                # Password validation
│       └── auth_token.dart              # Token wrapper
├── application/
│   ├── ports/
│   │   ├── auth_repository.dart         # Data persistence port
│   │   ├── biometric_gateway.dart       # Biometric auth port
│   │   ├── google_auth_gateway.dart     # Google auth port
│   │   ├── email_gateway.dart           # Email sending port
│   │   └── secure_storage_gateway.dart  # Secure credential storage port
│   └── use_cases/
│       ├── register_user_use_case.dart
│       ├── login_with_email_use_case.dart
│       ├── login_with_google_use_case.dart
│       ├── login_with_biometric_use_case.dart
│       ├── enable_mfa_use_case.dart
│       ├── verify_mfa_use_case.dart
│       ├── reset_password_use_case.dart
│       ├── logout_use_case.dart
│       ├── refresh_session_use_case.dart
│       └── manage_sessions_use_case.dart
├── infrastructure/
│   ├── repositories/
│   │   └── local_auth_repository.dart   # SQLite implementation
│   ├── gateways/
│   │   ├── local_auth_biometric_gateway.dart
│   │   ├── google_sign_in_gateway.dart
│   │   ├── smtp_email_gateway.dart
│   │   └── flutter_secure_storage_gateway.dart
│   └── services/
│       ├── password_hasher.dart         # bcrypt implementation
│       ├── token_generator.dart         # JWT/secure token generation
│       └── otp_generator.dart           # OTP generation
├── presentation/
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── mfa_setup_screen.dart
│   │   ├── mfa_verify_screen.dart
│   │   ├── password_reset_screen.dart
│   │   └── auth_settings_screen.dart
│   ├── widgets/
│   │   ├── email_input_field.dart
│   │   ├── password_input_field.dart
│   │   ├── google_sign_in_button.dart
│   │   ├── biometric_prompt_widget.dart
│   │   └── session_list_item.dart
│   └── state/
│       └── auth_state_manager.dart      # Authentication state management
└── auth_module.dart                     # Dependency injection setup
```

### Integration Points

- **Existing Google Auth**: Reuse `packages/google_drive_backup/lib/src/auth/google_auth.dart` for Google Sign-In
- **Session Management**: Integrate with app-level navigation to enforce authentication requirements
- **Secure Storage**: Use `flutter_secure_storage` for tokens and biometric credentials
- **Database**: Extend existing SQLite database for user accounts and sessions

## Components and Interfaces

### Domain Entities

#### User Entity
```dart
class User {
  final String id;
  final Email email;
  final String? passwordHash;
  final bool isEmailVerified;
  final bool isMfaEnabled;
  final bool isBiometricEnabled;
  final String? googleAccountId;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
}
```

#### Session Entity
```dart
class Session {
  final String id;
  final String userId;
  final AuthToken token;
  final String deviceInfo;
  final String? ipAddress;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime lastActivityAt;
  final bool isActive;
}
```

#### AuthMethod Enum
```dart
enum AuthMethod {
  emailPassword,
  google,
  biometric,
}

enum MfaMethod {
  biometric,
  emailOtp,
}
```

### Application Ports

#### AuthRepository
```dart
abstract class AuthRepository {
  Future<User?> findUserByEmail(Email email);
  Future<User?> findUserById(String id);
  Future<User> createUser(User user);
  Future<User> updateUser(User user);
  Future<Session> createSession(Session session);
  Future<Session?> findSessionByToken(AuthToken token);
  Future<void> invalidateSession(String sessionId);
  Future<List<Session>> getActiveSessions(String userId);
  Future<void> addLoginAttempt(LoginAttempt attempt);
  Future<List<LoginAttempt>> getLoginHistory(String userId, {int limit = 100});
  Future<int> countFailedAttempts(Email email, Duration window);
}
```

#### BiometricGateway
```dart
abstract class BiometricGateway {
  Future<bool> isAvailable();
  Future<BiometricType> getSupportedType(); // fingerprint, face, none
  Future<bool> authenticate({required String reason});
  Future<void> storeCredentials(String userId, String encryptedData);
  Future<String?> retrieveCredentials(String userId);
  Future<void> deleteCredentials(String userId);
}
```

#### GoogleAuthGateway
```dart
abstract class GoogleAuthGateway {
  Future<GoogleAuthResult> signIn();
  Future<void> signOut();
  Future<String?> getCurrentUserEmail();
}

class GoogleAuthResult {
  final bool success;
  final String? email;
  final String? googleId;
  final String? error;
}
```

#### EmailGateway
```dart
abstract class EmailGateway {
  Future<void> sendVerificationEmail(Email to, String verificationLink);
  Future<void> sendPasswordResetEmail(Email to, String resetLink);
  Future<void> sendMfaOtp(Email to, String otp);
  Future<void> sendSecurityAlert(Email to, String message);
}
```

#### SecureStorageGateway
```dart
abstract class SecureStorageGateway {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
}
```

### Use Case Examples

#### RegisterUserUseCase
```dart
class RegisterUserUseCase {
  final AuthRepository _repository;
  final PasswordHasher _hasher;
  final EmailGateway _emailGateway;
  final TokenGenerator _tokenGenerator;

  Future<RegisterResult> execute(Email email, Password password) async {
    // 1. Validate email not already registered
    // 2. Hash password with bcrypt
    // 3. Create user entity
    // 4. Generate verification token
    // 5. Send verification email
    // 6. Return result
  }
}
```

#### LoginWithEmailUseCase
```dart
class LoginWithEmailUseCase {
  final AuthRepository _repository;
  final PasswordHasher _hasher;
  final TokenGenerator _tokenGenerator;

  Future<LoginResult> execute(
    Email email,
    Password password,
    String deviceInfo,
  ) async {
    // 1. Check rate limiting
    // 2. Find user by email
    // 3. Verify password hash
    // 4. Check if MFA enabled
    // 5. If MFA: return pending MFA state
    // 6. If no MFA: create session and return token
    // 7. Record login attempt
  }
}
```

#### VerifyMfaUseCase
```dart
class VerifyMfaUseCase {
  final AuthRepository _repository;
  final BiometricGateway _biometricGateway;
  final TokenGenerator _tokenGenerator;

  Future<MfaVerifyResult> execute(
    String userId,
    MfaMethod method,
    String? otpCode,
  ) async {
    // 1. Verify MFA code or biometric
    // 2. Create session
    // 3. Return auth token
  }
}
```

## Data Models

### Database Schema

#### users table
```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT,
  is_email_verified INTEGER NOT NULL DEFAULT 0,
  is_mfa_enabled INTEGER NOT NULL DEFAULT 0,
  is_biometric_enabled INTEGER NOT NULL DEFAULT 0,
  google_account_id TEXT UNIQUE,
  created_at INTEGER NOT NULL,
  last_login_at INTEGER,
  CONSTRAINT email_or_google CHECK (
    password_hash IS NOT NULL OR google_account_id IS NOT NULL
  )
);
```

#### sessions table
```sql
CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  token_hash TEXT NOT NULL,
  device_info TEXT NOT NULL,
  ip_address TEXT,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  last_activity_at INTEGER NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

#### login_attempts table
```sql
CREATE TABLE login_attempts (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  success INTEGER NOT NULL,
  auth_method TEXT NOT NULL,
  device_info TEXT,
  ip_address TEXT,
  error_message TEXT,
  attempted_at INTEGER NOT NULL
);
```

#### mfa_pending table (temporary storage)
```sql
CREATE TABLE mfa_pending (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  otp_hash TEXT,
  device_info TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### Secure Storage Keys

Stored in device secure storage (flutter_secure_storage):
- `auth_token_{userId}`: Current session token
- `biometric_credentials_{userId}`: Encrypted credentials for biometric auth
- `refresh_token_{userId}`: Long-lived refresh token (optional)

## Error Handling

### Error Types

```dart
abstract class AuthError {
  String get message;
}

class InvalidCredentialsError extends AuthError {
  String get message => 'Invalid email or password';
}

class AccountLockedError extends AuthError {
  final Duration lockDuration;
  String get message => 'Account temporarily locked. Try again in ${lockDuration.inMinutes} minutes';
}

class EmailAlreadyExistsError extends AuthError {
  String get message => 'An account with this email already exists';
}

class MfaRequiredError extends AuthError {
  final String pendingSessionId;
  String get message => 'Multi-factor authentication required';
}

class BiometricNotAvailableError extends AuthError {
  String get message => 'Biometric authentication not available on this device';
}

class SessionExpiredError extends AuthError {
  String get message => 'Your session has expired. Please log in again';
}

class RateLimitExceededError extends AuthError {
  String get message => 'Too many attempts. Please try again later';
}
```

### Error Handling Strategy

1. **Use Case Layer**: Return `Result<T, AuthError>` types to handle errors functionally
2. **Presentation Layer**: Map errors to user-friendly messages
3. **Security**: Never reveal whether email exists during login failures
4. **Logging**: Log all authentication errors (excluding sensitive data) for security monitoring
5. **Rate Limiting**: Implement exponential backoff for repeated failures

## Testing Strategy

### Unit Tests

1. **Domain Layer**
   - Email validation logic
   - Password strength validation
   - Token generation and validation

2. **Use Cases**
   - Registration flow with valid/invalid inputs
   - Login flow with correct/incorrect credentials
   - MFA verification with various methods
   - Password reset flow
   - Session management operations

3. **Infrastructure**
   - Password hashing and verification
   - Token generation and expiration
   - OTP generation and validation

### Integration Tests

1. **Repository Tests**
   - User CRUD operations
   - Session management
   - Login attempt tracking

2. **Gateway Tests**
   - Biometric authentication flow (mocked platform)
   - Google Sign-In flow (mocked)
   - Email sending (mocked SMTP)

### Widget Tests

1. **Login Screen**
   - Email/password input validation
   - Google Sign-In button interaction
   - Biometric prompt trigger
   - Error message display

2. **Registration Screen**
   - Form validation
   - Password strength indicator
   - Email verification flow

3. **MFA Screens**
   - OTP input
   - Biometric prompt
   - Method selection

### Security Tests

1. **Password Security**
   - Verify bcrypt hashing with cost factor 12+
   - Test password requirements enforcement

2. **Session Security**
   - Verify token encryption
   - Test session expiration
   - Test concurrent session limits

3. **Rate Limiting**
   - Test account lockout after failed attempts
   - Test IP-based rate limiting

4. **Input Validation**
   - Test SQL injection prevention
   - Test XSS prevention in error messages

## Security Considerations

### Password Security
- Use bcrypt with cost factor 12 minimum
- Enforce strong password requirements
- Never log or transmit passwords in plain text
- Implement secure password reset flow with time-limited tokens

### Token Security
- Generate cryptographically secure random tokens
- Use AES-256 encryption for token storage
- Implement token rotation on sensitive operations
- Set appropriate expiration times (24 hours for sessions)

### Biometric Security
- Store credentials only in device secure storage
- Never transmit biometric data
- Require password re-authentication every 30 days
- Provide fallback to password authentication

### MFA Security
- Generate OTPs with 6 digits, valid for 5 minutes
- Limit OTP verification attempts to 3
- Use secure random number generation
- Implement anti-replay protection

### Session Security
- Implement session timeout (15 minutes inactivity)
- Require re-authentication after app backgrounding (5 minutes)
- Invalidate all sessions on password change
- Allow users to remotely terminate sessions

### Communication Security
- Enforce HTTPS with TLS 1.3+
- Implement certificate pinning for API calls
- Use secure headers (HSTS, CSP, X-Frame-Options)

### Data Protection
- Encrypt sensitive data at rest
- Use parameterized queries to prevent SQL injection
- Sanitize all user inputs
- Implement CSRF protection for state-changing operations

## Performance Considerations

1. **Password Hashing**: Use async operations to avoid blocking UI
2. **Biometric Auth**: Provide immediate feedback, timeout after 30 seconds
3. **Session Checks**: Cache session validation for 1 minute to reduce database queries
4. **Login History**: Paginate results, index by user_id and timestamp
5. **Rate Limiting**: Use in-memory cache for attempt counting

## Accessibility

1. **Screen Reader Support**: All authentication screens fully accessible
2. **Keyboard Navigation**: Support tab navigation through forms
3. **Error Announcements**: Ensure errors are announced to screen readers
4. **Biometric Alternatives**: Always provide password fallback
5. **High Contrast**: Support system high contrast mode
6. **Text Scaling**: Support dynamic text sizing

## Migration Strategy

### Phase 1: Core Authentication
- Implement email/password registration and login
- Add session management
- Create authentication screens

### Phase 2: Google Integration
- Integrate existing Google auth for login
- Support account linking
- Migrate existing Google Drive users

### Phase 3: Enhanced Security
- Add MFA support
- Implement biometric authentication
- Add session management UI

### Phase 4: Monitoring & Refinement
- Add login history tracking
- Implement security alerts
- Performance optimization
