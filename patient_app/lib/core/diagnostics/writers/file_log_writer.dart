import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/log_entry.dart';
import 'log_writer.dart';

/// Writes logs to rotating files with size and count limits.
/// 
/// Features:
/// - Automatic file rotation when size limit reached
/// - Automatic cleanup of old files
/// - Buffered writes for performance
/// - Timestamped filenames
class FileLogWriter implements LogWriter {
  final String logDirectory;
  final int maxFileSize;
  final int maxFiles;

  File? _currentFile;
  IOSink? _sink;
  int _currentSize = 0;
  final List<String> _buffer = [];
  Timer? _flushTimer;
  String? _absoluteLogPath;
  bool _isFlushing = false;

  FileLogWriter({
    required this.logDirectory,
    required this.maxFileSize,
    required this.maxFiles,
  }) {
    // Start periodic flush timer (every 1 second)
    _flushTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => flush(),
    );
  }

  @override
  Future<void> write(LogEntry entry) async {
    try {
      // Ensure we have a current file
      await _ensureFile();

      // Format entry
      final formatted = entry.toFormattedString();
      
      // Add to buffer
      _buffer.add(formatted);
      _currentSize += formatted.length;

      // Rotate if needed
      if (_currentSize >= maxFileSize) {
        await _rotate();
      }
    } catch (e) {
      // Don't let logging errors crash the app
      print('[FileLogWriter] Error writing log: $e');
    }
  }

  @override
  Future<void> flush() async {
    // Prevent concurrent flush operations
    if (_isFlushing || _buffer.isEmpty || _sink == null) return;

    _isFlushing = true;
    try {
      // Copy buffer to avoid modification during flush
      final entriesToFlush = List<String>.from(_buffer);
      _buffer.clear();
      
      // Write all entries
      for (final entry in entriesToFlush) {
        _sink!.writeln(entry);
      }
      
      // Flush the sink
      await _sink!.flush();
    } catch (e) {
      print('[FileLogWriter] Error flushing logs: $e');
    } finally {
      _isFlushing = false;
    }
  }

  @override
  Future<void> close() async {
    _flushTimer?.cancel();
    await flush();
    await _sink?.close();
    _sink = null;
    _currentFile = null;
  }

  /// Ensure we have a current log file open
  Future<void> _ensureFile() async {
    if (_currentFile != null && _sink != null) return;

    // Get absolute path to log directory (in app documents directory)
    if (_absoluteLogPath == null) {
      final appDir = await getApplicationDocumentsDirectory();
      _absoluteLogPath = path.join(appDir.path, logDirectory);
    }

    // Create log directory if it doesn't exist
    final dir = Directory(_absoluteLogPath!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Generate filename with timestamp
    final filename = _generateFileName();
    _currentFile = File(path.join(_absoluteLogPath!, filename));

    // Open file for appending
    _sink = _currentFile!.openWrite(mode: FileMode.append);
    
    // Get current file size
    if (await _currentFile!.exists()) {
      _currentSize = await _currentFile!.length();
    } else {
      _currentSize = 0;
    }
  }

  /// Generate timestamped filename
  String _generateFileName() {
    final now = DateTime.now();
    return 'app_log_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}.log';
  }

  /// Rotate to a new log file
  Future<void> _rotate() async {
    // Flush and close current file
    await flush();
    await _sink?.close();
    _sink = null;
    _currentFile = null;
    _currentSize = 0;

    // Clean up old files
    await _deleteOldFiles();

    // Next write will create a new file
  }

  /// Delete old log files beyond the limit
  Future<void> _deleteOldFiles() async {
    try {
      if (_absoluteLogPath == null) return;
      
      final dir = Directory(_absoluteLogPath!);
      if (!await dir.exists()) return;

      // Get all log files sorted by modification time (oldest first)
      final files = await dir
          .list()
          .where((entity) =>
              entity is File && entity.path.endsWith('.log'))
          .cast<File>()
          .toList();

      // Sort by last modified (oldest first)
      files.sort((a, b) =>
          a.lastModifiedSync().compareTo(b.lastModifiedSync()));

      // Delete oldest files if we exceed the limit
      while (files.length >= maxFiles) {
        final oldestFile = files.removeAt(0);
        try {
          await oldestFile.delete();
          print('[FileLogWriter] Deleted old log file: ${oldestFile.path}');
        } catch (e) {
          print('[FileLogWriter] Failed to delete old log: $e');
        }
      }
    } catch (e) {
      print('[FileLogWriter] Error cleaning up old files: $e');
    }
  }
}
