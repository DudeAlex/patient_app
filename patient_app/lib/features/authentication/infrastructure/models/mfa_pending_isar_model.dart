import 'package:isar/isar.dart';

part 'mfa_pending_isar_model.g.dart';

/// Isar persistence model for temporary MFA verification state.
/// Stores pending MFA challenges between primary and secondary authentication.
@collection
class MfaPendingIsarModel {
  MfaPendingIsarModel();

  /// Unique pending session identifier (UUID stored as string)
  @Index(unique: true)
  late String id;

  /// User ID awaiting MFA verification (indexed for fast lookups)
  @Index()
  late String userId;

  /// Hashed OTP if email-based MFA (null for biometric-only)
  String? otpHash;

  /// Device information for the pending session
  late String deviceInfo;

  /// IP address for the pending session
  String? ipAddress;

  /// When the pending session was created
  late DateTime createdAt;

  /// When the pending session expires (typically 5 minutes)
  @Index()
  late DateTime expiresAt;

  /// Number of verification attempts made (max 3)
  late int attemptCount;

  /// Isar auto-increment ID (internal use only)
  Id isarId = Isar.autoIncrement;
}
