import 'package:flutter/foundation.dart';

/// Structured error payload returned by AI operations.
@immutable
class AiError {
  /// Human-readable message safe to show to people inside the app.
  final String message;

  /// Indicates whether retrying the same request might succeed.
  final bool isRetryable;

  /// Optional provider-specific error code for diagnostics.
  final String? code;

  const AiError({
    required this.message,
    required this.isRetryable,
    this.code,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiError &&
        other.message == message &&
        other.isRetryable == isRetryable &&
        other.code == code;
  }

  @override
  int get hashCode => message.hashCode ^ isRetryable.hashCode ^ code.hashCode;

  @override
  String toString() =>
      'AiError(message: $message, isRetryable: $isRetryable, code: $code)';
}
