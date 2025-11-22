import '../models/log_entry.dart';
import '../models/log_level.dart';
import '../models/log_config.dart';
import '../models/environment_context.dart';
import '../writers/log_writer.dart';
import 'privacy_filter.dart';

/// Core logging service that processes and routes log entries.
/// 
/// Handles filtering, privacy redaction, and writing to multiple destinations.
class LoggerService {
  final LogConfig config;
  final EnvironmentContext environmentContext;
  final List<LogWriter> writers;
  final PrivacyFilter privacyFilter;

  LoggerService({
    required this.config,
    required this.environmentContext,
    required this.writers,
    PrivacyFilter? privacyFilter,
  }) : privacyFilter = privacyFilter ?? PrivacyFilter();

  /// Log an entry if it passes all filters
  Future<void> log(LogEntry entry) async {
    // Check if we should log this level
    if (!entry.level.isAtLeast(config.minLevel)) {
      return;
    }

    // Check if we should log this module
    if (!config.shouldLogModule(entry.module)) {
      return;
    }

    // Apply privacy filter to context
    final filteredEntry = LogEntry(
      id: entry.id,
      timestamp: entry.timestamp,
      level: entry.level,
      message: privacyFilter.redactString(entry.message),
      module: entry.module,
      correlationId: entry.correlationId,
      context: privacyFilter.redact(entry.context),
      stackTrace: entry.stackTrace,
      environment: entry.environment,
    );

    // Write to all configured writers
    final futures = <Future<void>>[];
    for (final writer in writers) {
      futures.add(_writeToWriter(writer, filteredEntry));
    }

    // Wait for all writes to complete
    await Future.wait(futures);
  }

  /// Create a log entry with current environment context
  LogEntry createEntry(
    LogLevel level,
    String message,
    String module, {
    String? correlationId,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    return LogEntry(
      level: level,
      message: message,
      module: module,
      correlationId: correlationId,
      context: context,
      stackTrace: stackTrace,
      environment: environmentContext,
    );
  }

  /// Check if a log level and module should be logged
  bool shouldLog(LogLevel level, String module) {
    return level.isAtLeast(config.minLevel) && config.shouldLogModule(module);
  }

  /// Flush all writers
  Future<void> flush() async {
    final futures = writers.map((writer) => writer.flush());
    await Future.wait(futures);
  }

  /// Close all writers
  Future<void> close() async {
    final futures = writers.map((writer) => writer.close());
    await Future.wait(futures);
  }

  /// Write to a single writer with error handling
  Future<void> _writeToWriter(LogWriter writer, LogEntry entry) async {
    try {
      await writer.write(entry);
    } catch (e, stackTrace) {
      // If logging fails, print to console as fallback
      // Don't use the logger here to avoid infinite recursion
      // ignore: avoid_print
      print('[LoggerService] Failed to write log entry: $e');
      // ignore: avoid_print
      print('[LoggerService] Stack trace: $stackTrace');
    }
  }
}
