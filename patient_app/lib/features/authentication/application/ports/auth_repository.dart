import '../../domain/entities/login_attempt.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/user.dart';

/// Port (interface) for authentication data persistence.
/// 
/// This interface defines the contract for storing and retrieving
/// authentication-related data including users, sessions, and login attempts.
/// Implementations handle the actual database operations while use cases
/// depend only on this abstraction (Dependency Inversion Principle).
abstract class AuthRepository {
  /// Finds a user by their email address.
  /// 
  /// Returns the user if found, null otherwise.
  /// Used during login to verify credentials and during registration
  /// to check for duplicate accounts.
  Future<User?> findUserByEmail(String email);

  /// Finds a user by their unique identifier.
  /// 
  /// Returns the user if found, null otherwise.
  /// Used for session validation and user profile operations.
  Future<User?> findUserById(String id);

  /// Creates a new user in the system.
  /// 
  /// Returns the created user with any generated fields populated.
  /// Throws an exception if a user with the same email already exists.
  Future<User> createUser(User user);

  /// Updates an existing user's information.
  /// 
  /// Returns the updated user.
  /// Used for enabling/disabling MFA, biometric auth, linking Google accounts,
  /// and updating verification status.
  Future<User> updateUser(User user);

  /// Creates a new authenticated session.
  /// 
  /// Returns the created session with generated fields populated.
  /// Sessions track active user access with device info and expiration.
  Future<Session> createSession(Session session);

  /// Finds an active session by its authentication token.
  /// 
  /// Returns the session if found and active, null otherwise.
  /// Used for validating incoming requests and maintaining user state.
  Future<Session?> findSessionByToken(String token);

  /// Invalidates a session, marking it as inactive.
  /// 
  /// Used during logout or when terminating sessions remotely.
  /// The session remains in the database for audit purposes but
  /// can no longer be used for authentication.
  Future<void> invalidateSession(String sessionId);

  /// Retrieves all active sessions for a specific user.
  /// 
  /// Returns a list of sessions ordered by creation time (newest first).
  /// Used for displaying active sessions in the user's security settings.
  Future<List<Session>> getActiveSessions(String userId);

  /// Records a login attempt for audit logging and security monitoring.
  /// 
  /// Stores both successful and failed attempts with device info,
  /// IP address, and error details. Used for rate limiting, account
  /// lockout, and suspicious activity detection.
  Future<void> addLoginAttempt(LoginAttempt attempt);

  /// Retrieves login history for a specific user.
  /// 
  /// Returns a list of login attempts ordered by time (newest first).
  /// The [limit] parameter controls the maximum number of results.
  /// Used for displaying login history in security settings.
  Future<List<LoginAttempt>> getLoginHistory(
    String userId, {
    int limit = 100,
  });

  /// Counts failed login attempts for an email within a time window.
  /// 
  /// Returns the number of consecutive failed attempts.
  /// Used for implementing rate limiting and account lockout after
  /// repeated failures (e.g., 3 failures triggers 15-minute lockout).
  Future<int> countFailedAttempts(String email, Duration window);
}
