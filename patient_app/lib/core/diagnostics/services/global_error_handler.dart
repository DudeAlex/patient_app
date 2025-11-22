import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../app_logger.dart';

/// Global error handler that intercepts all uncaught exceptions.
/// 
/// Captures errors from:
/// - Flutter framework (FlutterError.onError)
/// - Dart runtime (PlatformDispatcher.onError)
/// - Async errors (runZonedGuarded)
class GlobalErrorHandler {
  static bool _isInitialized = false;
  static FlutterExceptionHandler? _originalFlutterErrorHandler;
  static ErrorCallback? _originalPlatformErrorHandler;

  /// Initialize global error handling
  /// 
  /// This should be called early in main() before runApp()
  static void initialize() {
    if (_isInitialized) return;

    // Capture Flutter framework errors
    _originalFlutterErrorHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log the error
      _handleFlutterError(details);

      // Call original handler if it exists
      _originalFlutterErrorHandler?.call(details);
    };

    // Capture platform/Dart errors
    _originalPlatformErrorHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      // Log the error
      _handlePlatformError(error, stack);

      // Call original handler if it exists
      if (_originalPlatformErrorHandler != null) {
        return _originalPlatformErrorHandler!(error, stack);
      }

      // Return true to indicate error was handled
      return true;
    };

    _isInitialized = true;
  }

  /// Restore original error handlers
  static void restore() {
    if (!_isInitialized) return;

    FlutterError.onError = _originalFlutterErrorHandler;
    PlatformDispatcher.instance.onError = _originalPlatformErrorHandler;

    _isInitialized = false;
  }

  /// Handle Flutter framework errors
  static void _handleFlutterError(FlutterErrorDetails details) {
    // Determine if this is a fatal error
    final isFatal = !details.silent;

    // Log the error
    AppLogger.error(
      'Flutter error: ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
      context: {
        'library': details.library ?? 'unknown',
        'context': details.context?.toString() ?? 'none',
        'silent': details.silent,
        'fatal': isFatal,
        'informationCollector': details.informationCollector?.call() ?? 'none',
      },
    );

    // If fatal, this might be a crash
    if (isFatal) {
      AppLogger.fatal(
        'Fatal Flutter error detected',
        error: details.exception,
        stackTrace: details.stack,
        context: {
          'summary': details.summary.toString(),
          'library': details.library ?? 'unknown',
        },
      );
    }
  }

  /// Handle platform/Dart errors
  static void _handlePlatformError(Object error, StackTrace stack) {
    AppLogger.fatal(
      'Uncaught platform error',
      error: error,
      stackTrace: stack,
      context: {
        'errorType': error.runtimeType.toString(),
        'errorString': error.toString(),
      },
    );
  }

  /// Run code in a guarded zone that catches async errors
  /// 
  /// Use this to wrap your main app:
  /// ```dart
  /// void main() {
  ///   GlobalErrorHandler.runGuarded(() async {
  ///     await DiagnosticSystem.initialize();
  ///     runApp(MyApp());
  ///   });
  /// }
  /// ```
  static void runGuarded(Future<void> Function() body) {
    runZonedGuarded(
      () async {
        // Initialize error handling
        initialize();

        // Run the app
        await body();
      },
      (error, stack) {
        // Catch async errors that escape the Flutter framework
        AppLogger.fatal(
          'Uncaught async error',
          error: error,
          stackTrace: stack,
          context: {
            'errorType': error.runtimeType.toString(),
            'zone': 'root',
          },
        );
      },
    );
  }

  /// Check if error handling is initialized
  static bool get isInitialized => _isInitialized;
}
