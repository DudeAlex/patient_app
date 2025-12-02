/// Represents a single error recovery attempt.
class ErrorRecoveryAttempt {
  /// The attempt number (1-indexed).
  final int attemptNumber;

  /// The strategy used for this recovery attempt.
  final String strategyUsed;

  /// The timestamp when the attempt was made.
  final DateTime timestamp;

  /// The duration of the recovery attempt.
  final Duration duration;

  /// Whether the recovery attempt was successful.
  final bool success;

  /// Optional error message if the attempt failed.
  final String? errorMessage;

  /// Creates an [ErrorRecoveryAttempt] instance.
  ErrorRecoveryAttempt({
    required this.attemptNumber,
    required this.strategyUsed,
    required this.timestamp,
    required this.duration,
    required this.success,
    this.errorMessage,
  });

 /// Converts the attempt to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'attemptNumber': attemptNumber,
      'strategyUsed': strategyUsed,
      'timestamp': timestamp.toIso8601String(),
      'duration': duration.inMilliseconds,
      'success': success,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }
}