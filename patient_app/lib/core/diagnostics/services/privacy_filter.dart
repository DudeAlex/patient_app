/// Privacy filter that redacts sensitive information from logs.
/// 
/// Ensures logs don't contain personal health information, emails,
/// tokens, or other sensitive data.
/// 
/// In development mode (debug/dev), redaction is disabled to allow
/// full visibility of logs for debugging. In production, all sensitive
/// data is redacted for privacy compliance.
class PrivacyFilter {
  final bool enableRedaction;

  /// Create a privacy filter
  /// 
  /// [enableRedaction] - If true, sensitive data will be redacted.
  /// If false (development mode), all data is visible.
  PrivacyFilter({required this.enableRedaction});

  /// Fields that should be redacted from logs (only in production)
  static const List<String> sensitiveFields = [
    'email',
    'password',
    'token',
    'accessToken',
    'refreshToken',
    'title',
    'text',
    'notes',
    'content',
    'name',
    'displayName',
    'phone',
    'phoneNumber',
    'address',
    'ssn',
    'creditCard',
  ];

  /// Redact sensitive fields from a map
  Map<String, dynamic> redact(Map<String, dynamic> data) {
    // Skip redaction in development mode
    if (!enableRedaction) {
      return data;
    }

    final redacted = <String, dynamic>{};

    for (final entry in data.entries) {
      if (isSensitiveField(entry.key)) {
        redacted[entry.key] = '[REDACTED]';
      } else if (entry.value is Map<String, dynamic>) {
        // Recursively redact nested maps
        redacted[entry.key] = redact(entry.value as Map<String, dynamic>);
      } else if (entry.value is List) {
        // Redact lists
        redacted[entry.key] = _redactList(entry.value as List);
      } else {
        redacted[entry.key] = entry.value;
      }
    }

    return redacted;
  }

  /// Redact items in a list
  List<dynamic> _redactList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map<String, dynamic>) {
        return redact(item);
      } else if (item is String && _looksLikeSensitiveData(item)) {
        return '[REDACTED]';
      }
      return item;
    }).toList();
  }

  /// Redact sensitive patterns from a string
  String redactString(String text) {
    // Skip redaction in development mode
    if (!enableRedaction) {
      return text;
    }

    var redacted = text;

    // Redact email addresses
    redacted = redacted.replaceAll(
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
      '[EMAIL_REDACTED]',
    );

    // Redact tokens (long alphanumeric strings)
    redacted = redacted.replaceAll(
      RegExp(r'\b[A-Za-z0-9_-]{32,}\b'),
      '[TOKEN_REDACTED]',
    );

    // Redact phone numbers (various formats)
    redacted = redacted.replaceAll(
      RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b'),
      '[PHONE_REDACTED]',
    );

    return redacted;
  }

  /// Check if a field name indicates sensitive data
  bool isSensitiveField(String fieldName) {
    final normalized = fieldName.toLowerCase();
    return sensitiveFields.any((sensitive) =>
        normalized.contains(sensitive.toLowerCase()));
  }

  /// Check if a string looks like sensitive data
  bool _looksLikeSensitiveData(String value) {
    // Check if it looks like an email
    if (RegExp(r'@.*\.').hasMatch(value)) return true;

    // Check if it looks like a token (long alphanumeric)
    if (value.length > 32 && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value)) {
      return true;
    }

    return false;
  }
}
