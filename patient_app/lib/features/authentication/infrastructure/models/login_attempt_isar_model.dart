import 'package:isar/isar.dart';

part 'login_attempt_isar_model.g.dart';

/// Isar persistence model for LoginAttempt entity.
/// Stores audit log of all authentication attempts for security monitoring.
@collection
class LoginAttemptIsarModel {
  LoginAttemptIsarModel();

  /// Unique attempt identifier (UUID stored as string)
  @Index(unique: true)
  late String id;

  /// Email address used in the attempt (indexed for rate limiting queries)
  @Index(caseSensitive: false)
  late String email;

  /// Whether the authentication attempt succeeded
  late bool success;

  /// Authentication method used (emailPassword, google, biometric)
  late String authMethod;

  /// Device information if available
  String? deviceInfo;

  /// IP address from which attempt was made
  String? ipAddress;

  /// Error message if attempt failed
  String? errorMessage;

  /// Timestamp of the attempt (indexed for time-based queries)
  @Index()
  late DateTime attemptedAt;

  /// Isar auto-increment ID (internal use only)
  Id isarId = Isar.autoIncrement;
}
