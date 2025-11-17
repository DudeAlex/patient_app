import 'package:uuid/uuid.dart';
import 'log_level.dart';
import 'environment_context.dart';

/// A single log entry with timestamp, level, message, and context.
/// 
/// Represents one logged event in the system.
class LogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String module;
  final String? correlationId;
  final Map<String, dynamic> context;
  final StackTrace? stackTrace;
  final EnvironmentContext environment;

  LogEntry({
    String? id,
    DateTime? timestamp,
    required this.level,
    required this.message,
    required this.module,
    this.correlationId,
    Map<String, dynamic>? context,
    this.stackTrace,
    required this.environment,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now(),
        context = context ?? {};

  /// Convert to JSON for file storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'level': level.name,
        'message': message,
        'module': module,
        if (correlationId != null) 'correlationId': correlationId,
        if (context.isNotEmpty) 'context': context,
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
        'environment': environment.toJson(),
      };

  /// Format as human-readable string for console/file
  String toFormattedString() {
    final buffer = StringBuffer();
    
    // Timestamp and level
    buffer.write('[${timestamp.toIso8601String()}] ');
    buffer.write('[${level.label.padRight(5)}] ');
    
    // Module
    buffer.write('[$module] ');
    
    // Correlation ID if present
    if (correlationId != null) {
      buffer.write('[CID:${correlationId!.substring(0, 8)}] ');
    }
    
    // Message
    buffer.writeln(message);
    
    // Context if present
    if (context.isNotEmpty) {
      buffer.writeln('  Context: $context');
    }
    
    // Stack trace if present
    if (stackTrace != null) {
      buffer.writeln('  Stack Trace:');
      final lines = stackTrace.toString().split('\n');
      for (final line in lines.take(10)) {
        // Limit to first 10 lines
        buffer.writeln('    $line');
      }
      if (lines.length > 10) {
        buffer.writeln('    ... (${lines.length - 10} more lines)');
      }
    }
    
    return buffer.toString();
  }

  @override
  String toString() => toFormattedString();
}
