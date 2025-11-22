/// Log severity levels ordered from least to most severe.
/// 
/// Used to filter and categorize log entries.
enum LogLevel {
  /// Detailed trace information for debugging
  trace(0, 'TRACE'),
  
  /// Debug information for development
  debug(1, 'DEBUG'),
  
  /// General informational messages
  info(2, 'INFO'),
  
  /// Warning messages for potentially harmful situations
  warning(3, 'WARN'),
  
  /// Error messages for error events
  error(4, 'ERROR'),
  
  /// Fatal error messages for severe failures
  fatal(5, 'FATAL');

  const LogLevel(this.severity, this.label);

  /// Numeric severity for comparison (0 = least severe, 5 = most severe)
  final int severity;
  
  /// Short label for display
  final String label;

  /// Check if this level is at least as severe as another level
  bool isAtLeast(LogLevel other) => severity >= other.severity;

  /// Parse log level from string (case-insensitive)
  static LogLevel fromString(String value) {
    final normalized = value.toLowerCase();
    return LogLevel.values.firstWhere(
      (level) => level.name.toLowerCase() == normalized,
      orElse: () => LogLevel.info,
    );
  }

  @override
  String toString() => label;
}
