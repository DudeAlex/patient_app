import 'package:isar/isar.dart';

import '../../application/ports/auth_repository.dart';
import '../../domain/entities/auth_method.dart';
import '../../domain/entities/login_attempt.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/user.dart';
import '../models/login_attempt_isar_model.dart';
import '../models/session_isar_model.dart';
import '../models/user_isar_model.dart';

/// Local implementation of AuthRepository using Isar database.
/// 
/// This adapter translates between domain entities and Isar persistence models,
/// maintaining clean architecture boundaries. All database operations are
/// performed through Isar collections with proper indexing for performance.
class LocalAuthRepository implements AuthRepository {
  final Isar _isar;

  LocalAuthRepository(this._isar);

  @override
  Future<User?> findUserByEmail(String email) async {
    // Query by indexed email field (case-insensitive)
    final model = await _isar.userIsarModels
        .filter()
        .emailEqualTo(email, caseSensitive: false)
        .findFirst();
    
    return model != null ? _mapUserFromModel(model) : null;
  }

  @override
  Future<User?> findUserById(String id) async {
    // Query by indexed id field
    final model = await _isar.userIsarModels
        .filter()
        .idEqualTo(id)
        .findFirst();
    
    return model != null ? _mapUserFromModel(model) : null;
  }

  @override
  Future<User> createUser(User user) async {
    final model = _mapUserToModel(user);
    
    await _isar.writeTxn(() async {
      await _isar.userIsarModels.put(model);
    });
    
    return user;
  }

  @override
  Future<User> updateUser(User user) async {
    final model = _mapUserToModel(user);
    
    await _isar.writeTxn(() async {
      await _isar.userIsarModels.put(model);
    });
    
    return user;
  }

  @override
  Future<Session> createSession(Session session) async {
    final model = _mapSessionToModel(session);
    
    await _isar.writeTxn(() async {
      await _isar.sessionIsarModels.put(model);
    });
    
    return session;
  }

  @override
  Future<Session?> findSessionByToken(String token) async {
    // Query by indexed tokenHash field
    // Note: The token should be hashed before calling this method
    final model = await _isar.sessionIsarModels
        .filter()
        .tokenHashEqualTo(token)
        .and()
        .isActiveEqualTo(true)
        .findFirst();
    
    return model != null ? _mapSessionFromModel(model) : null;
  }

  @override
  Future<void> invalidateSession(String sessionId) async {
    await _isar.writeTxn(() async {
      final model = await _isar.sessionIsarModels
          .filter()
          .idEqualTo(sessionId)
          .findFirst();
      
      if (model != null) {
        model.isActive = false;
        await _isar.sessionIsarModels.put(model);
      }
    });
  }

  @override
  Future<List<Session>> getActiveSessions(String userId) async {
    // Query active sessions for user, ordered by creation time (newest first)
    final models = await _isar.sessionIsarModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isActiveEqualTo(true)
        .sortByCreatedAtDesc()
        .findAll();
    
    return models.map(_mapSessionFromModel).toList();
  }

  @override
  Future<void> addLoginAttempt(LoginAttempt attempt) async {
    final model = _mapLoginAttemptToModel(attempt);
    
    await _isar.writeTxn(() async {
      await _isar.loginAttemptIsarModels.put(model);
    });
  }

  @override
  Future<List<LoginAttempt>> getLoginHistory(
    String userId, {
    int limit = 100,
  }) async {
    // First find the user to get their email
    final user = await findUserById(userId);
    if (user == null) return [];
    
    // Query login attempts by email, ordered by time (newest first)
    final models = await _isar.loginAttemptIsarModels
        .filter()
        .emailEqualTo(user.email, caseSensitive: false)
        .sortByAttemptedAtDesc()
        .limit(limit)
        .findAll();
    
    return models.map(_mapLoginAttemptFromModel).toList();
  }

  @override
  Future<int> countFailedAttempts(String email, Duration window) async {
    final cutoffTime = DateTime.now().subtract(window);
    
    // Count failed attempts within the time window
    final count = await _isar.loginAttemptIsarModels
        .filter()
        .emailEqualTo(email, caseSensitive: false)
        .and()
        .successEqualTo(false)
        .and()
        .attemptedAtGreaterThan(cutoffTime)
        .count();
    
    return count;
  }

  // Mapping methods: Domain Entity -> Isar Model

  UserIsarModel _mapUserToModel(User user) {
    return UserIsarModel()
      ..id = user.id
      ..email = user.email
      ..passwordHash = user.passwordHash
      ..isEmailVerified = user.isEmailVerified
      ..isMfaEnabled = user.isMfaEnabled
      ..isBiometricEnabled = user.isBiometricEnabled
      ..googleAccountId = user.googleAccountId
      ..createdAt = user.createdAt
      ..lastLoginAt = user.lastLoginAt;
  }

  SessionIsarModel _mapSessionToModel(Session session) {
    return SessionIsarModel()
      ..id = session.id
      ..userId = session.userId
      ..tokenHash = session.token // Note: Should be hashed before storage
      ..deviceInfo = session.deviceInfo
      ..ipAddress = session.ipAddress
      ..createdAt = session.createdAt
      ..expiresAt = session.expiresAt
      ..lastActivityAt = session.lastActivityAt
      ..isActive = session.isActive;
  }

  LoginAttemptIsarModel _mapLoginAttemptToModel(LoginAttempt attempt) {
    return LoginAttemptIsarModel()
      ..id = attempt.id
      ..email = attempt.email
      ..success = attempt.success
      ..authMethod = attempt.authMethod.name
      ..deviceInfo = attempt.deviceInfo
      ..ipAddress = attempt.ipAddress
      ..errorMessage = attempt.errorMessage
      ..attemptedAt = attempt.attemptedAt;
  }

  // Mapping methods: Isar Model -> Domain Entity

  User _mapUserFromModel(UserIsarModel model) {
    return User(
      id: model.id,
      email: model.email,
      passwordHash: model.passwordHash,
      isEmailVerified: model.isEmailVerified,
      isMfaEnabled: model.isMfaEnabled,
      isBiometricEnabled: model.isBiometricEnabled,
      googleAccountId: model.googleAccountId,
      createdAt: model.createdAt,
      lastLoginAt: model.lastLoginAt,
    );
  }

  Session _mapSessionFromModel(SessionIsarModel model) {
    return Session(
      id: model.id,
      userId: model.userId,
      token: model.tokenHash,
      deviceInfo: model.deviceInfo,
      ipAddress: model.ipAddress,
      createdAt: model.createdAt,
      expiresAt: model.expiresAt,
      lastActivityAt: model.lastActivityAt,
      isActive: model.isActive,
    );
  }

  LoginAttempt _mapLoginAttemptFromModel(LoginAttemptIsarModel model) {
    return LoginAttempt(
      id: model.id,
      email: model.email,
      success: model.success,
      authMethod: AuthMethod.values.firstWhere(
        (e) => e.name == model.authMethod,
        orElse: () => AuthMethod.emailPassword,
      ),
      deviceInfo: model.deviceInfo,
      ipAddress: model.ipAddress,
      errorMessage: model.errorMessage,
      attemptedAt: model.attemptedAt,
    );
  }
}
