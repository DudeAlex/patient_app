import 'models/log_config.dart';
import 'models/environment_context.dart';
import 'models/crash_info.dart';
import 'services/logger_service.dart';
import 'services/privacy_filter.dart';
import 'services/crash_detector.dart';
import 'writers/log_writer.dart';
import 'writers/console_log_writer.dart';
import 'writers/file_log_writer.dart';
import 'app_logger.dart';

/// Main entry point for initializing the diagnostic system.
/// 
/// Handles loading configuration, setting up writers, and initializing
/// the logger service.
class DiagnosticSystem {
  static bool _isInitialized = false;
  static LoggerService? _loggerService;
  static CrashDetector? _crashDetector;

  /// Initialize the diagnostic system
  /// 
  /// This should be called early in main() before runApp()
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load configuration
      final config = await LogConfig.load();
      
      // Create environment context
      final environmentContext = await EnvironmentContext.create();
      
      // Create writers based on configuration
      final writers = <LogWriter>[];
      
      if (config.consoleEnabled) {
        writers.add(ConsoleLogWriter());
      }
      
      if (config.fileEnabled) {
        writers.add(FileLogWriter(
          logDirectory: 'logs',
          maxFileSize: config.maxFileSize,
          maxFiles: config.maxFiles,
        ));
      }
      
      // Create logger service (privacy filter will be created automatically)
      _loggerService = LoggerService(
        config: config,
        environmentContext: environmentContext,
        writers: writers,
      );
      
      // Initialize AppLogger
      AppLogger.initialize(_loggerService!);
      
      _isInitialized = true;
      
      // Log successful initialization
      await AppLogger.info(
        'Diagnostic system initialized',
        context: {
          'version': environmentContext.appVersion,
          'buildNumber': environmentContext.buildNumber,
          'platform': environmentContext.platform,
          'deviceType': environmentContext.deviceType,
          'sessionId': environmentContext.sessionId,
          'logLevel': config.minLevel.name,
          'consoleEnabled': config.consoleEnabled,
          'fileEnabled': config.fileEnabled,
        },
      );
      
      // Initialize crash detector
      _crashDetector = CrashDetector();
      await _crashDetector!.initialize();
      
      // Check for previous crash
      final crashInfo = await _crashDetector!.checkForCrash();
      if (crashInfo != null) {
        await AppLogger.error(
          'Previous crash detected',
          context: {
            'crashTime': crashInfo.crashTime.toIso8601String(),
            'detectedTime': crashInfo.detectedTime.toIso8601String(),
            'lastLogFile': crashInfo.lastLogFile,
            'description': crashInfo.description,
          },
        );
      }
      
      // Mark app as started
      await _crashDetector!.markAppStarted();
      await AppLogger.info('Crash detection active');
    } catch (e, stackTrace) {
      // If initialization fails, print to console
      // ignore: avoid_print
      print('[DiagnosticSystem] Failed to initialize: $e');
      // ignore: avoid_print
      print('[DiagnosticSystem] Stack trace: $stackTrace');
      
      // Set up minimal fallback (console only)
      await _initializeFallback();
    }
  }

  /// Initialize with minimal fallback configuration
  static Future<void> _initializeFallback() async {
    try {
      final environmentContext = await EnvironmentContext.create();
      
      _loggerService = LoggerService(
        config: LogConfig.defaultConfig,
        environmentContext: environmentContext,
        writers: [ConsoleLogWriter()],
      );
      
      AppLogger.initialize(_loggerService!);
      _isInitialized = true;
      
      await AppLogger.warning(
        'Diagnostic system initialized with fallback configuration',
      );
    } catch (e) {
      print('[DiagnosticSystem] Fallback initialization failed: $e');
    }
  }

  /// Get the current logger service (for advanced usage)
  static LoggerService? get loggerService => _loggerService;

  /// Check if the system is initialized
  static bool get isInitialized => _isInitialized;

  /// Shutdown the diagnostic system
  static Future<void> shutdown() async {
    if (!_isInitialized) return;
    
    await AppLogger.info('Diagnostic system shutting down');
    
    // Mark app as stopped (graceful shutdown)
    if (_crashDetector != null) {
      await _crashDetector!.markAppStopped();
    }
    
    await AppLogger.close();
    
    _loggerService = null;
    _crashDetector = null;
    _isInitialized = false;
  }
  
  /// Get the crash detector (for advanced usage)
  static CrashDetector? get crashDetector => _crashDetector;
  
  /// Get the last crash info if available
  static Future<CrashInfo?> getLastCrashInfo() async {
    return await _crashDetector?.getLastCrashInfo();
  }
  
  /// Get all crash log files
  static Future<List<String>> getCrashLogFiles() async {
    return await _crashDetector?.getCrashLogFiles() ?? [];
  }
  
  /// Clear all crash logs
  static Future<void> clearCrashLogs() async {
    await _crashDetector?.clearCrashLogs();
  }
}
