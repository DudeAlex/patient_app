/// Types of security events that can be emitted.
enum SecurityEventType {
  rateLimitViolation,
  authenticationFailure,
  authorizationFailure,
  httpsEnforced,
  inputValidationFailure,
  piiDetected,
  suspiciousActivity,
}

/// Represents a security-related event for monitoring and alerting.
class SecurityEvent {
  SecurityEvent({
    required this.type,
    this.userId,
    DateTime? timestamp,
    Map<String, Object?> metadata = const {},
  })  : timestamp = timestamp ?? DateTime.now(),
        metadata = Map.unmodifiable(metadata);

  final SecurityEventType type;
  final String? userId;
  final DateTime timestamp;
  final Map<String, Object?> metadata;
}
