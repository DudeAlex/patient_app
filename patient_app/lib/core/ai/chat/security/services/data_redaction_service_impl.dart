import 'package:patient_app/core/ai/chat/security/interfaces/data_redaction_service.dart';
import 'package:patient_app/core/ai/chat/security/models/redaction_pattern.dart';

/// In-memory redaction service applying regex patterns.
class DataRedactionServiceImpl implements DataRedactionService {
  DataRedactionServiceImpl({
    List<RedactionPattern>? patterns,
  }) : _patterns = List.of(patterns ?? _defaultPatterns);

  final List<RedactionPattern> _patterns;

  @override
  String redact(String text) {
    var output = text;
    for (final p in _patterns.where((p) => p.enabled)) {
      output = output.replaceAll(p.pattern, p.replacement);
    }
    return output;
  }

  @override
  void addPattern(RedactionPattern pattern) {
    _patterns.add(pattern);
  }

  @override
  bool containsSensitiveData(String text) {
    for (final p in _patterns.where((p) => p.enabled)) {
      if (p.pattern.hasMatch(text)) return true;
    }
    return false;
  }

  static final List<RedactionPattern> _defaultPatterns = [
    RedactionPattern(
      name: 'name',
      pattern: RegExp(r'\\b[A-Z][a-z]+ [A-Z][a-z]+\\b'),
    ),
    RedactionPattern(
      name: 'email',
      pattern: RegExp(r'\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\\b'),
    ),
    RedactionPattern(
      name: 'phone',
      pattern: RegExp(r'\\b\\d{3}[-.]?\\d{3}[-.]?\\d{4}\\b'),
    ),
    RedactionPattern(
      name: 'ssn',
      pattern: RegExp(r'\\b\\d{3}-\\d{2}-\\d{4}\\b'),
    ),
    RedactionPattern(
      name: 'address',
      pattern: RegExp(r'\\b\\d+\\s+[A-Za-z0-9\\.\\-\\s]+\\s+(Street|St\\.|Avenue|Ave\\.|Road|Rd\\.|Boulevard|Blvd\\.|Lane|Ln\\.|Drive|Dr\\.)\\b', caseSensitive: false),
    ),
  ];
}
