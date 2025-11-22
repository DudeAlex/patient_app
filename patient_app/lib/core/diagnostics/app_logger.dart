import 'models/log_level.dart';
import 'services/logger_service.dart';

/// Simple, static API for logging throughout the application.
/// 
/// This is the main interface that application code should use for logging.
/// It provides a clean facade over the underlying logging infrastructure.
class AppLogger {
  static LoggerService? _service;
  static final Map<String, String> _activeOperations = {};
  static int _operationCounter = 0;

  /// Initialize the logger with a service instance
  static void initialize(LoggerService service) {
    _service = service;
  }

  /// Log a trace message (most verbose)
  static Future<void> trace(
    String message, {
    Map<String, dynamic>? context,
    String? correlationId,
  }) async {
    await _log(LogLevel.trace, message, context: context, correlationId: correlationId);
  }

  /// Log a debug message
  static Future<void> debug(
    String message, {
    Map<String, dynamic>? context,
    String? correlationId,
  }) async {
    await _log(LogLevel.debug, message, context: context, correlationId: correlationId);
  }

  /// Log an info message
  static Future<void> info(
    String message, {
    Map<String, dynamic>? context,
    String? correlationId,
  }) async {
    await _log(LogLevel.info, message, context: context, correlationId: correlationId);
  }

  /// Log a warning message
  static Future<void> warning(
    String message, {
    Map<String, dynamic>? context,
    String? correlationId,
  }) async {
    await _log(LogLevel.warning, message, context: context, correlationId: correlationId);
  }

  /// Log an error message
  static Future<void> error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? correlationId,
  }) async {
    final errorContext = <String, dynamic>{
      if (context != null) ...context,
      if (error != null) 'error': error.toString(),
    };

    await _log(
      LogLevel.error,
      message,
      context: errorContext,
      stackTrace: stackTrace,
      correlationId: correlationId,
    );
  }

  /// Log a fatal error message
  static Future<void> fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? correlationId,
  }) async {
    final errorContext = <String, dynamic>{
      if (context != null) ...context,
      if (error != null) 'error': error.toString(),
    };

    await _log(
      LogLevel.fatal,
      message,
      context: errorContext,
      stackTrace: stackTrace,
      correlationId: correlationId,
    );
  }

  /// Start timing an operation and return an operation ID
  static String startOperation(String operationName, {String? parentId}) {
    final operationId = 'op_${++_operationCounter}_${DateTime.now().millisecondsSinceEpoch}';
    _activeOperations[operationId] = operationName;

    info(
      'Operation started: $operationName',
      context: {
        'operationId': operationId,
        'operationName': operationName,
        if (parentId != null) 'parentOperationId': parentId,
      },
      correlationId: operationId,
    );

    return operationId;
  }

  /// End timing an operation and log the duration
  static Future<void> endOperation(String operationId) async {
    final operationName = _activeOperations.remove(operationId);
    if (operationName == null) {
      warning('Attempted to end unknown operation: $operationId');
      return;
    }

    // Extract start time from operation ID
    final parts = operationId.split('_');
    if (parts.length >= 3) {
      final startTime = int.tryParse(parts[2]);
      if (startTime != null) {
        final duration = DateTime.now().millisecondsSinceEpoch - startTime;
        final durationSeconds = duration / 1000.0;

        // Check if operation was slow
        final threshold = _service?.config.performanceThreshold ?? 1000;
        final level = duration > threshold ? LogLevel.warning : LogLevel.info;
        final message = duration > threshold
            ? 'Slow operation completed: $operationName (${durationSeconds.toStringAsFixed(2)}s)'
            : 'Operation completed: $operationName (${durationSeconds.toStringAsFixed(2)}s)';

        await _log(
          level,
          message,
          context: {
            'operationId': operationId,
            'operationName': operationName,
            'durationMs': duration,
            'durationSeconds': durationSeconds,
          },
          correlationId: operationId,
        );
      }
    }
  }

  /// Log navigation between screens
  static Future<void> logNavigation(
    String from,
    String to, {
    Map<String, dynamic>? context,
  }) async {
    await info(
      'Navigation: $from → $to',
      context: {
        'from': from,
        'to': to,
        'type': 'navigation',
        ...?context, // Merge additional context if provided
      },
    );
  }

  /// Log screen loading
  static Future<void> logScreenLoad(String screenName) async {
    await info(
      'Screen loaded: $screenName',
      context: {
        'screen': screenName,
        'type': 'screen_load',
      },
    );
  }

  /// Log app lifecycle changes
  static Future<void> logAppLifecycle(String state) async {
    await info(
      'App lifecycle: $state',
      context: {
        'state': state,
        'type': 'lifecycle',
      },
    );
  }

  /// Flush all log writers
  static Future<void> flush() async {
    await _service?.flush();
  }

  /// Close all log writers
  static Future<void> close() async {
    await _service?.close();
  }

  /// Internal logging method
  static Future<void> _log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? correlationId,
  }) async {
    if (_service == null) {
      // Fallback to print if service not initialized
      print('[${level.label}] $message');
      return;
    }

    // Detect calling module from stack trace
    final module = _detectModule(stackTrace ?? StackTrace.current);

    // Check if we should log this
    if (!_service!.shouldLog(level, module)) {
      return;
    }

    // Create and log entry
    final entry = _service!.createEntry(
      level,
      message,
      module,
      correlationId: correlationId,
      context: context,
      stackTrace: stackTrace,
    );

    await _service!.log(entry);
  }

  /// Detect the calling module from stack trace
  static String _detectModule(StackTrace stackTrace) {
    final lines = stackTrace.toString().split('\n');
    
    for (final line in lines) {
      // Skip AppLogger frames
      if (line.contains('app_logger.dart')) continue;
      
      // Look for lib/ paths
      final match = RegExp(r'lib/([^/]+)/').firstMatch(line);
      if (match != null) {
        return match.group(1) ?? 'unknown';
      }
      
      // Look for package paths
      final packageMatch = RegExp(r'package:([^/]+)/').firstMatch(line);
      if (packageMatch != null) {
        return packageMatch.group(1) ?? 'unknown';
      }
    }
    
    return 'unknown';
  }
}
