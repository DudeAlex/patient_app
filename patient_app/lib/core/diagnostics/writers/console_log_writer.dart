import 'package:flutter/foundation.dart';
import '../models/log_entry.dart';
import '../models/log_level.dart';
import 'log_writer.dart';

/// Writes logs to the console with color coding by level.
class ConsoleLogWriter implements LogWriter {
  // ANSI color codes for terminal output
  static const String _reset = '\x1B[0m';
  static const String _gray = '\x1B[90m';
  static const String _blue = '\x1B[34m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _red = '\x1B[31m';
  static const String _magenta = '\x1B[35m';

  @override
  Future<void> write(LogEntry entry) async {
    final color = _getColorForLevel(entry.level);
    final formatted = entry.toFormattedString();
    
    // Use debugPrint for better Flutter console integration
    debugPrint('$color$formatted$_reset');
  }

  @override
  Future<void> flush() async {
    // Console writes are immediate, no buffering needed
  }

  @override
  Future<void> close() async {
    // Nothing to close for console
  }

  /// Get ANSI color code for log level
  String _getColorForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.trace:
        return _gray;
      case LogLevel.debug:
        return _blue;
      case LogLevel.info:
        return _green;
      case LogLevel.warning:
        return _yellow;
      case LogLevel.error:
        return _red;
      case LogLevel.fatal:
        return _magenta;
    }
  }
}
