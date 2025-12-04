import 'package:patient_app/core/ai/chat/security/models/rate_limit_config.dart';
import 'package:patient_app/core/ai/chat/security/models/redaction_pattern.dart';

/// Global security configuration for the AI chat system.
class SecurityConfig {
  const SecurityConfig({
    required this.httpsOnly,
    required this.requireAuth,
    required this.tokenExpiry,
    required this.rateLimits,
    required this.redactionPatterns,
    required this.maxMessageLength,
  });

  /// Enforce HTTPS-only communication.
  final bool httpsOnly;

  /// Require authentication for protected endpoints.
  final bool requireAuth;

  /// Token lifetime duration.
  final Duration tokenExpiry;

  /// Rate limit settings.
  final RateLimitConfig rateLimits;

  /// Redaction patterns applied to logs and outputs.
  final List<RedactionPattern> redactionPatterns;

  /// Maximum length allowed for incoming messages.
  final int maxMessageLength;
}
