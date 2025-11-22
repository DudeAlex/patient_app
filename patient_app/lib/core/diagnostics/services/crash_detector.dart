import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/crash_info.dart';

/// Detects if the app crashed on the previous run.
/// 
/// Works by creating a marker file on app start and removing it on
/// graceful shutdown. If the marker exists on next startup, a crash occurred.
class CrashDetector {
  static const String _markerFileName = '.app_running';
  static const String _crashInfoFileName = 'last_crash.json';
  static const String _crashLogsDir = 'crash_logs';

  File? _markerFile;
  String? _appDocsPath;

  /// Initialize the crash detector
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _appDocsPath = appDir.path;
    _markerFile = File(path.join(appDir.path, _markerFileName));
  }

  /// Check if a crash occurred on the previous run
  /// 
  /// Returns CrashInfo if a crash was detected, null otherwise
  Future<CrashInfo?> checkForCrash() async {
    if (_markerFile == null) {
      await initialize();
    }

    // Check if marker file exists
    if (await _markerFile!.exists()) {
      // Crash detected - marker file should have been removed on clean shutdown
      final markerStat = await _markerFile!.stat();
      final crashTime = markerStat.modified;
      final detectedTime = DateTime.now();

      // Find the most recent log file
      final lastLogFile = await _findMostRecentLogFile();

      // Preserve the crash log
      if (lastLogFile != null) {
        await _preserveCrashLog(lastLogFile, crashTime);
      }

      // Save crash info
      final crashInfo = CrashInfo(
        crashTime: crashTime,
        detectedTime: detectedTime,
        lastLogFile: lastLogFile,
        context: {
          'markerFileModified': crashTime.toIso8601String(),
          'detectionTime': detectedTime.toIso8601String(),
        },
      );

      await _saveCrashInfo(crashInfo);

      return crashInfo;
    }

    return null;
  }

  /// Mark that the app has started
  /// 
  /// Creates the marker file to indicate the app is running
  Future<void> markAppStarted() async {
    if (_markerFile == null) {
      await initialize();
    }

    // Create marker file with current timestamp
    await _markerFile!.writeAsString(DateTime.now().toIso8601String());
  }

  /// Mark that the app is shutting down gracefully
  /// 
  /// Removes the marker file to indicate clean shutdown
  Future<void> markAppStopped() async {
    if (_markerFile == null) {
      await initialize();
    }

    // Remove marker file
    if (await _markerFile!.exists()) {
      await _markerFile!.delete();
    }
  }

  /// Find the most recent log file
  Future<String?> _findMostRecentLogFile() async {
    if (_appDocsPath == null) return null;

    final logsDir = Directory(path.join(_appDocsPath!, 'logs'));
    if (!await logsDir.exists()) return null;

    final logFiles = <File>[];
    await for (final entity in logsDir.list()) {
      if (entity is File && entity.path.endsWith('.log')) {
        logFiles.add(entity);
      }
    }

    if (logFiles.isEmpty) return null;

    // Sort by modification time, most recent first
    logFiles.sort((a, b) {
      final aStat = a.statSync();
      final bStat = b.statSync();
      return bStat.modified.compareTo(aStat.modified);
    });

    return logFiles.first.path;
  }

  /// Preserve a crash log by copying it to the crash_logs directory
  Future<void> _preserveCrashLog(String logFilePath, DateTime crashTime) async {
    if (_appDocsPath == null) return;

    try {
      final crashLogsDir = Directory(path.join(_appDocsPath!, _crashLogsDir));
      if (!await crashLogsDir.exists()) {
        await crashLogsDir.create(recursive: true);
      }

      // Create crash log filename with timestamp
      final timestamp = crashTime.toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-')
          .split('T')
          .join('_');
      final crashLogName = 'crash_$timestamp.log';
      final crashLogPath = path.join(crashLogsDir.path, crashLogName);

      // Copy the log file
      final sourceFile = File(logFilePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(crashLogPath);
      }
    } catch (e) {
      // Ignore errors in crash log preservation
      // ignore: avoid_print
      print('[CrashDetector] Failed to preserve crash log: $e');
    }
  }

  /// Save crash info to a file
  Future<void> _saveCrashInfo(CrashInfo crashInfo) async {
    if (_appDocsPath == null) return;

    try {
      final crashInfoFile = File(path.join(_appDocsPath!, _crashInfoFileName));
      final json = jsonEncode(crashInfo.toJson());
      await crashInfoFile.writeAsString(json);
    } catch (e) {
      // Ignore errors in crash info saving
      // ignore: avoid_print
      print('[CrashDetector] Failed to save crash info: $e');
    }
  }

  /// Get the last crash info if available
  Future<CrashInfo?> getLastCrashInfo() async {
    if (_appDocsPath == null) {
      await initialize();
    }

    try {
      final crashInfoFile = File(path.join(_appDocsPath!, _crashInfoFileName));
      if (await crashInfoFile.exists()) {
        final json = await crashInfoFile.readAsString();
        final data = jsonDecode(json) as Map<String, dynamic>;
        return CrashInfo.fromJson(data);
      }
    } catch (e) {
      // Ignore errors reading crash info
      // ignore: avoid_print
      print('[CrashDetector] Failed to read crash info: $e');
    }

    return null;
  }

  /// Get all crash log files
  Future<List<String>> getCrashLogFiles() async {
    if (_appDocsPath == null) {
      await initialize();
    }

    final crashLogsDir = Directory(path.join(_appDocsPath!, _crashLogsDir));
    if (!await crashLogsDir.exists()) {
      return [];
    }

    final crashLogs = <String>[];
    await for (final entity in crashLogsDir.list()) {
      if (entity is File && entity.path.endsWith('.log')) {
        crashLogs.add(entity.path);
      }
    }

    // Sort by filename (which includes timestamp)
    crashLogs.sort((a, b) => b.compareTo(a)); // Most recent first

    return crashLogs;
  }

  /// Clear all crash logs
  Future<void> clearCrashLogs() async {
    if (_appDocsPath == null) {
      await initialize();
    }

    try {
      final crashLogsDir = Directory(path.join(_appDocsPath!, _crashLogsDir));
      if (await crashLogsDir.exists()) {
        await crashLogsDir.delete(recursive: true);
      }

      final crashInfoFile = File(path.join(_appDocsPath!, _crashInfoFileName));
      if (await crashInfoFile.exists()) {
        await crashInfoFile.delete();
      }
    } catch (e) {
      // Ignore errors clearing crash logs
      // ignore: avoid_print
      print('[CrashDetector] Failed to clear crash logs: $e');
    }
  }
}
