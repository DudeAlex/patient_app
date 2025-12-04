import 'package:patient_app/core/ai/chat/security/models/redaction_pattern.dart';

/// Interface for redacting sensitive data (PII) from text.
abstract class DataRedactionService {
  /// Redact known sensitive patterns from [text].
  String redact(String text);

  /// Add a custom redaction pattern.
  void addPattern(RedactionPattern pattern);

  /// Check if [text] contains any sensitive pattern.
  bool containsSensitiveData(String text);
}
