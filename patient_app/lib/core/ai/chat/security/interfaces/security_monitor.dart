import 'package:patient_app/core/ai/chat/security/models/security_event.dart';

/// Interface for logging and inspecting security events.
abstract class SecurityMonitor {
  /// Record a security event with optional metadata.
  Future<void> logEvent({
    required SecurityEventType type,
    String? userId,
    Map<String, Object?>? metadata,
  });

  /// Retrieve recent events within a time [window] (default 24 hours).
  Future<List<SecurityEvent>> getRecentEvents({
    Duration window = const Duration(hours: 24),
  });

  /// Determine whether the given user exhibits suspicious activity patterns.
  Future<bool> isSuspiciousActivity({
    required String userId,
  });
}
