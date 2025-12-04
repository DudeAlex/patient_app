/// Describes a pattern used to redact sensitive data.
class RedactionPattern {
  const RedactionPattern({
    required this.name,
    required this.pattern,
    this.replacement = '[REDACTED]',
    this.enabled = true,
  });

  /// Friendly name of the pattern (e.g., "email", "phone").
  final String name;

  /// Regular expression that matches the sensitive content.
  final RegExp pattern;

  /// Replacement text when redacting.
  final String replacement;

  /// Whether the pattern is active.
  final bool enabled;
}
