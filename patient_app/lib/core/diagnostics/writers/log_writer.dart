import '../models/log_entry.dart';

/// Interface for log output destinations.
/// 
/// Implementations write logs to different targets (console, file, remote, etc.)
abstract class LogWriter {
  /// Write a log entry to the output destination
  Future<void> write(LogEntry entry);

  /// Flush any buffered entries
  Future<void> flush();

  /// Close the writer and release resources
  Future<void> close();
}
