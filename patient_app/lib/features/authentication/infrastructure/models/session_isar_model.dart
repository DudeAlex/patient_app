import 'package:isar/isar.dart';

part 'session_isar_model.g.dart';

/// Isar persistence model for Session entity.
/// Maps to domain Session entity via the repository adapter layer.
@collection
class SessionIsarModel {
  SessionIsarModel();

  /// Unique session identifier (UUID stored as string)
  @Index(unique: true)
  late String id;

  /// User ID this session belongs to (indexed for fast user session queries)
  @Index()
  late String userId;

  /// Hashed authentication token for security
  /// (actual token is never stored, only its hash)
  @Index(unique: true)
  late String tokenHash;

  /// Device information (e.g., "iPhone 13, iOS 16.0")
  late String deviceInfo;

  /// IP address from which session was created
  String? ipAddress;

  /// Session creation timestamp
  late DateTime createdAt;

  /// Session expiration timestamp (24 hours from creation)
  @Index()
  late DateTime expiresAt;

  /// Last activity timestamp (updated on each request)
  late DateTime lastActivityAt;

  /// Whether session is still active (false after logout/invalidation)
  @Index()
  late bool isActive;

  /// Isar auto-increment ID (internal use only)
  Id isarId = Isar.autoIncrement;
}
