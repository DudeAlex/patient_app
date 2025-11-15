import 'package:isar/isar.dart';

part 'user_isar_model.g.dart';

/// Isar persistence model for User entity.
/// Maps to domain User entity via the repository adapter layer.
@collection
class UserIsarModel {
  UserIsarModel();

  /// Unique identifier (UUID stored as string)
  @Index(unique: true)
  late String id;

  /// User's email address (unique, indexed for fast lookups)
  @Index(unique: true, caseSensitive: false)
  late String email;

  /// Bcrypt password hash (null for Google-only accounts)
  String? passwordHash;

  /// Whether the user has verified their email address
  late bool isEmailVerified;

  /// Whether multi-factor authentication is enabled
  late bool isMfaEnabled;

  /// Whether biometric authentication is enabled
  late bool isBiometricEnabled;

  /// Google account ID if linked (unique, indexed)
  @Index(unique: true)
  String? googleAccountId;

  /// Account creation timestamp
  late DateTime createdAt;

  /// Last successful login timestamp
  DateTime? lastLoginAt;

  /// Isar auto-increment ID (internal use only)
  Id isarId = Isar.autoIncrement;
}
