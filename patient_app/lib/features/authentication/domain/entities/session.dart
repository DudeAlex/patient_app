/// Represents an authenticated user session in the Patient App.
/// 
/// Sessions track active user access with security information including
/// device details, expiration times, and activity tracking for timeout
/// enforcement.
class Session {
  /// Unique identifier for this session
  final String id;
  
  /// ID of the user who owns this session
  final String userId;
  
  /// Secure authentication token (stored as hash in database)
  final String token;
  
  /// Information about the device used for this session
  /// (e.g., "iPhone 13, iOS 16.0" or "Pixel 6, Android 13")
  final String deviceInfo;
  
  /// IP address from which the session was created (optional)
  final String? ipAddress;
  
  /// Timestamp when the session was created
  final DateTime createdAt;
  
  /// Timestamp when the session will expire (24 hours from creation)
  final DateTime expiresAt;
  
  /// Timestamp of the last activity in this session
  /// (used for inactivity timeout enforcement)
  final DateTime lastActivityAt;
  
  /// Whether this session is currently active
  /// (false if manually logged out or remotely terminated)
  final bool isActive;

  const Session({
    required this.id,
    required this.userId,
    required this.token,
    required this.deviceInfo,
    this.ipAddress,
    required this.createdAt,
    required this.expiresAt,
    required this.lastActivityAt,
    required this.isActive,
  });

  /// Creates a copy of this session with the specified fields replaced
  Session copyWith({
    String? id,
    String? userId,
    String? token,
    String? deviceInfo,
    String? ipAddress,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? lastActivityAt,
    bool? isActive,
  }) {
    return Session(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      token: token ?? this.token,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      ipAddress: ipAddress ?? this.ipAddress,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Checks if this session has expired based on the expiration timestamp
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Checks if this session has been inactive for more than the specified duration
  bool isInactiveFor(Duration duration) {
    return DateTime.now().difference(lastActivityAt) > duration;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Session &&
        other.id == id &&
        other.userId == userId &&
        other.token == token &&
        other.deviceInfo == deviceInfo &&
        other.ipAddress == ipAddress &&
        other.createdAt == createdAt &&
        other.expiresAt == expiresAt &&
        other.lastActivityAt == lastActivityAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      token,
      deviceInfo,
      ipAddress,
      createdAt,
      expiresAt,
      lastActivityAt,
      isActive,
    );
  }

  @override
  String toString() {
    return 'Session(id: $id, userId: $userId, deviceInfo: $deviceInfo, '
        'isActive: $isActive, isExpired: $isExpired)';
  }
}
