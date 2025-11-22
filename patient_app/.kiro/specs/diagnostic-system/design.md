# Diagnostic and Debugging System - Design

## Overview

The Diagnostic System is a comprehensive logging and monitoring layer that provides visibility into application behavior, performance, and errors. It enables developers and AI to analyze crashes, performance bottlenecks, and unexpected behavior through centralized logging, crash detection, and exportable diagnostics.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Application Layer                        │
│  (Screens, Widgets, Providers, Services)                    │
└────────────────────┬────────────────────────────────────────┘
                     │ Log calls
                     ↓
┌─────────────────────────────────────────────────────────────┐
│                   Diagnostic Facade                          │
│  (AppLogger - Simple API for logging)                       │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────────┐
│                   Core Logging Engine                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Logger     │  │   Config     │  │   Context    │     │
│  │   Service    │  │   Manager    │  │   Provider   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────────┐
│                   Output Handlers                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Console    │  │     File     │  │   Crash      │     │
│  │   Writer     │  │   Writer     │  │   Detector   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────────┐
│                   Storage Layer                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Log Files   │  │    Config    │  │    Crash     │     │
│  │  (Rotated)   │  │     JSON     │  │    Marker    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. AppLogger (Facade)

**Location**: `lib/core/diagnostics/app_logger.dart`

Simple, static API for logging throughout the application.

```dart
class AppLogger {
  static void trace(String message, {Map<String, dynamic>? context});
  static void debug(String message, {Map<String, dynamic>? context});
  static void info(String message, {Map<String, dynamic>? context});
  static void warning(String message, {Map<String, dynamic>? context});
  static void error(String message, {Object? error, StackTrace? stackTrace});
  static void fatal(String message, {Object? error, StackTrace? stackTrace});
  
  // Performance timing
  static String startOperation(String operationName);
  static void endOperation(String operationId);
  
  // Lifecycle
  static void logNavigation(String from, String to);
  static void logScreenLoad(String screenName);
  static void logAppLifecycle(AppLifecycleState state);
}
```

### 2. LoggerService (Core Engine)

**Location**: `lib/core/diagnostics/services/logger_service.dart`

Central logging engine that processes and routes log entries.

```dart
class LoggerService {
  final LogConfig config;
  final ContextProvider contextProvider;
  final List<LogWriter> writers;
  final PrivacyFilter privacyFilter;
  
  void log(LogEntry entry);
  bool shouldLog(LogLevel level, String module);
  LogEntry createEntry(LogLevel level, String message, Map<String, dynamic>? context);
}
```

### 3. LogEntry (Data Model)

**Location**: `lib/core/diagnostics/models/log_entry.dart`

```dart
class LogEntry {
  final String id;                    // Unique log entry ID
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String module;                // Module/feature name
  final String? correlationId;        // Links related operations
  final Map<String, dynamic> context; // Additional data
  final StackTrace? stackTrace;
  final EnvironmentContext environment;
  
  String toJson();
  String toFormattedString();
}
```

### 4. EnvironmentContext (Metadata)

**Location**: `lib/core/diagnostics/models/environment_context.dart`

```dart
class EnvironmentContext {
  final String appVersion;
  final String buildNumber;
  final String environment;      // dev, test, prod
  final String deviceType;       // emulator, physical
  final String osVersion;
  final String platform;         // android, ios, windows, web
  final String sessionId;
  final String deviceId;
  
  static Future<EnvironmentContext> create();
}
```

### 5. LogConfig (Configuration)

**Location**: `lib/core/diagnostics/models/log_config.dart`

```dart
class LogConfig {
  final LogLevel minLevel;
  final bool consoleEnabled;
  final bool fileEnabled;
  final int maxFileSize;         // bytes
  final int maxFiles;
  final List<String> moduleFilters;  // Include patterns
  final List<String> moduleExcludes; // Exclude patterns
  final int performanceThreshold;    // ms
  
  static LogConfig fromJson(Map<String, dynamic> json);
  static Future<LogConfig> load();
}
```

**Config File**: `assets/config/logging_config.json`

```json
{
  "minLevel": "debug",
  "consoleEnabled": true,
  "fileEnabled": true,
  "maxFileSize": 5242880,
  "maxFiles": 5,
  "moduleFilters": ["*"],
  "moduleExcludes": [],
  "performanceThreshold": 1000
}
```

### 6. LogWriter (Output Interface)

**Location**: `lib/core/diagnostics/writers/log_writer.dart`

```dart
abstract class LogWriter {
  Future<void> write(LogEntry entry);
  Future<void> flush();
  Future<void> close();
}
```

**Implementations**:
- `ConsoleLogWriter` - Writes to console with color coding
- `FileLogWriter` - Writes to rotating log files
- `BufferedLogWriter` - Buffers entries for batch writing

### 7. FileLogWriter (File Output)

**Location**: `lib/core/diagnostics/writers/file_log_writer.dart`

```dart
class FileLogWriter implements LogWriter {
  final String logDirectory;
  final int maxFileSize;
  final int maxFiles;
  
  File? _currentFile;
  IOSink? _sink;
  int _currentSize = 0;
  
  Future<void> write(LogEntry entry);
  Future<void> _rotateIfNeeded();
  Future<void> _deleteOldFiles();
  String _generateFileName();  // app_log_2025-11-15_14-30-00.log
}
```

### 8. CrashDetector

**Location**: `lib/core/diagnostics/services/crash_detector.dart`

```dart
class CrashDetector {
  final String markerFilePath;
  
  Future<bool> didCrashLastTime();
  Future<void> markAppStarted();
  Future<void> markAppClosedGracefully();
  Future<void> preserveLastLog();
  Future<CrashInfo?> getLastCrashInfo();
}

class CrashInfo {
  final DateTime timestamp;
  final String? lastLogFile;
  final EnvironmentContext environment;
}
```

### 9. PerformanceTracker

**Location**: `lib/core/diagnostics/services/performance_tracker.dart`

```dart
class PerformanceTracker {
  final Map<String, OperationTimer> _activeOperations;
  final int warningThreshold;
  
  String startOperation(String name, {String? parentId});
  void endOperation(String operationId);
  OperationMetrics getMetrics(String operationId);
}

class OperationTimer {
  final String id;
  final String name;
  final DateTime startTime;
  final String? parentId;
  
  Duration get elapsed => DateTime.now().difference(startTime);
}
```

### 10. PrivacyFilter

**Location**: `lib/core/diagnostics/services/privacy_filter.dart`

```dart
class PrivacyFilter {
  static const List<String> sensitiveFields = [
    'email', 'password', 'token', 'title', 'text', 'notes', 
    'name', 'phone', 'address'
  ];
  
  Map<String, dynamic> redact(Map<String, dynamic> data);
  String redactString(String text);
  bool isSensitiveField(String fieldName);
}
```

### 11. DiagnosticExporter

**Location**: `lib/core/diagnostics/services/diagnostic_exporter.dart`

```dart
class DiagnosticExporter {
  Future<File> createDiagnosticPackage();
  Future<void> sharePackage(File package);
  
  Future<Map<String, dynamic>> _collectSystemInfo();
  Future<List<File>> _collectLogFiles();
  Future<CrashInfo?> _collectCrashInfo();
}
```

### 12. DiagnosticsScreen (UI)

**Location**: `lib/ui/diagnostics/diagnostics_screen.dart`

```dart
class DiagnosticsScreen extends StatelessWidget {
  // Displays:
  // - Current session info
  // - Log file list with sizes
  // - Crash detection status
  // - Export button
  // - Clear logs button
  // - Log level selector (for runtime adjustment)
}
```

### 13. GlobalErrorHandler

**Location**: `lib/core/diagnostics/global_error_handler.dart`

```dart
class GlobalErrorHandler {
  static void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.fatal(
        'Flutter Error: ${details.exception}',
        error: details.exception,
        stackTrace: details.stack,
      );
    };
    
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.fatal(
        'Unhandled Error: $error',
        error: error,
        stackTrace: stack,
      );
      return true;
    };
  }
}
```

## Data Flow

### Logging Flow

```
1. Application Code
   AppLogger.info("User logged in")
   
2. AppLogger (Facade)
   Creates LogEntry with context
   
3. LoggerService
   - Checks if should log (level, filters)
   - Adds environment context
   - Applies privacy filter
   
4. LogWriters (parallel)
   - ConsoleLogWriter → Console output
   - FileLogWriter → Log file (with rotation)
   
5. Storage
   - Log files in app documents directory
   - Automatic rotation when size limit reached
```

### Crash Detection Flow

```
1. App Startup
   CrashDetector.didCrashLastTime()
   
2. Check Marker File
   If exists → Previous crash detected
   
3. Log Crash Event
   AppLogger.warning("Previous session crashed")
   
4. Preserve Last Log
   Copy last log file to crash_logs/
   
5. Mark New Session
   Create new crash marker file
   
6. Normal Operation
   ...
   
7. Graceful Shutdown
   Remove crash marker file
```

### Performance Tracking Flow

```
1. Start Operation
   operationId = AppLogger.startOperation("Database Migration")
   
2. PerformanceTracker
   Creates OperationTimer with start time
   
3. Do Work
   ... heavy operation ...
   
4. End Operation
   AppLogger.endOperation(operationId)
   
5. Calculate Duration
   duration = endTime - startTime
   
6. Log Performance
   If duration > threshold:
     AppLogger.warning("Slow operation: Migration took 2.5s")
   Else:
     AppLogger.debug("Operation completed: Migration took 0.5s")
```

### Diagnostic Export Flow

```
1. User Taps "Export Diagnostics"
   
2. DiagnosticExporter.createDiagnosticPackage()
   
3. Collect Data
   - All log files
   - System information (device, OS, app version)
   - Crash marker status
   - Performance metrics summary
   
4. Create ZIP
   diagnostics_2025-11-15_14-30-00.zip
   ├── logs/
   │   ├── app_log_2025-11-15_14-00-00.log
   │   ├── app_log_2025-11-15_13-00-00.log
   │   └── crash_logs/
   ├── system_info.json
   └── crash_info.json
   
5. Share via Platform
   Platform share dialog (email, drive, etc.)
```

## File Structure

```
lib/core/diagnostics/
├── app_logger.dart                    # Public API facade
├── models/
│   ├── log_entry.dart
│   ├── log_level.dart
│   ├── log_config.dart
│   ├── environment_context.dart
│   └── crash_info.dart
├── services/
│   ├── logger_service.dart
│   ├── crash_detector.dart
│   ├── performance_tracker.dart
│   ├── privacy_filter.dart
│   ├── diagnostic_exporter.dart
│   └── config_manager.dart
├── writers/
│   ├── log_writer.dart               # Interface
│   ├── console_log_writer.dart
│   ├── file_log_writer.dart
│   └── buffered_log_writer.dart
└── global_error_handler.dart

lib/ui/diagnostics/
├── diagnostics_screen.dart
└── widgets/
    ├── log_file_list.dart
    ├── system_info_card.dart
    └── crash_status_card.dart

assets/config/
└── logging_config.json
```

## Integration Points

### 1. Main Initialization

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize diagnostics FIRST
  await DiagnosticSystem.initialize();
  
  // Set up global error handling
  GlobalErrorHandler.initialize();
  
  // Check for previous crash
  final didCrash = await CrashDetector.instance.didCrashLastTime();
  if (didCrash) {
    AppLogger.warning('Previous session ended unexpectedly');
  }
  
  // Mark app started
  await CrashDetector.instance.markAppStarted();
  
  // Log app startup
  AppLogger.info('App starting', context: {
    'version': '1.0.0',
    'buildNumber': '42',
  });
  
  // Continue with normal initialization
  await bootstrapAppContainer();
  
  runApp(const PatientApp());
}
```

### 2. Navigation Logging

```dart
class AppNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    AppLogger.logNavigation(
      previousRoute?.settings.name ?? 'none',
      route.settings.name ?? 'unknown',
    );
  }
}
```

### 3. Screen Lifecycle

```dart
class MyScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    AppLogger.logScreenLoad('MyScreen');
  }
}
```

### 4. Heavy Operations

```dart
Future<void> migrateDatabase() async {
  final opId = AppLogger.startOperation('Database Migration');
  try {
    // Do migration work
    await _performMigration();
    AppLogger.info('Migration completed successfully');
  } catch (e, stack) {
    AppLogger.error('Migration failed', error: e, stackTrace: stack);
    rethrow;
  } finally {
    AppLogger.endOperation(opId);
  }
}
```

### 5. Settings Integration

Add "Diagnostics" option to Settings screen:

```dart
ListTile(
  leading: Icon(Icons.bug_report),
  title: Text('Diagnostics'),
  subtitle: Text('View logs and export diagnostics'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => DiagnosticsScreen()),
  ),
)
```

## Configuration Examples

### Development (Verbose)

```json
{
  "minLevel": "trace",
  "consoleEnabled": true,
  "fileEnabled": true,
  "maxFileSize": 10485760,
  "maxFiles": 10,
  "moduleFilters": ["*"],
  "moduleExcludes": [],
  "performanceThreshold": 500
}
```

### Production (Minimal)

```json
{
  "minLevel": "warning",
  "consoleEnabled": false,
  "fileEnabled": true,
  "maxFileSize": 2097152,
  "maxFiles": 3,
  "moduleFilters": ["*"],
  "moduleExcludes": ["debug", "trace"],
  "performanceThreshold": 2000
}
```

### Investigation Mode (Temporary)

```json
{
  "minLevel": "trace",
  "consoleEnabled": true,
  "fileEnabled": true,
  "maxFileSize": 20971520,
  "maxFiles": 20,
  "moduleFilters": ["migration", "spaces", "records"],
  "moduleExcludes": [],
  "performanceThreshold": 100
}
```

## Privacy Considerations

### Redaction Rules

1. **Email addresses**: `user@example.com` → `[EMAIL_REDACTED]`
2. **Record titles**: `"Annual Checkup"` → `[TITLE_REDACTED]`
3. **Record content**: `"Patient notes..."` → `[CONTENT_REDACTED]`
4. **Tokens**: `"eyJhbGc..."` → `[TOKEN_REDACTED]`
5. **IDs are safe**: Record IDs, space IDs, operation IDs can be logged

### Safe to Log

- Record IDs (e.g., `recordId: 12345`)
- Space IDs (e.g., `spaceId: health`)
- Category types (e.g., `type: Checkup`)
- Counts (e.g., `recordCount: 42`)
- Durations (e.g., `duration: 1.5s`)
- Error types (e.g., `StateError`)
- Navigation routes (e.g., `/records/add`)

## Performance Impact

### Minimal Overhead

- **Console logging**: ~0.1ms per entry
- **File logging**: ~1-2ms per entry (buffered)
- **Context gathering**: ~0.5ms (cached per session)
- **Privacy filtering**: ~0.2ms per entry

### Optimization Strategies

1. **Buffered writes**: Batch file writes every 1 second
2. **Lazy context**: Cache environment context on first use
3. **Async file I/O**: Don't block main thread
4. **Level filtering**: Skip processing for filtered levels
5. **Conditional logging**: Use closures for expensive context

```dart
// Expensive context only evaluated if debug level is enabled
AppLogger.debug(() => 'Records: ${expensiveOperation()}');
```

## Testing Strategy

### Unit Tests

- LogEntry creation and formatting
- Privacy filter redaction rules
- Log level filtering logic
- File rotation logic
- Configuration parsing

### Integration Tests

- End-to-end logging flow
- Crash detection and recovery
- Diagnostic export creation
- Performance tracking accuracy

### Manual Tests

- Verify logs appear in console
- Verify log files are created and rotated
- Trigger crash and verify detection
- Export diagnostics and verify ZIP contents
- Test with different log levels

## Future Enhancements

1. **Remote logging**: Send logs to cloud service
2. **Log search**: In-app log viewer with search
3. **Performance dashboard**: Visual performance metrics
4. **Automatic crash reporting**: Auto-send crash logs
5. **Log compression**: Compress old log files
6. **Structured logging**: JSON format for machine parsing
7. **Log streaming**: Real-time log viewing over network

---

**Design Version**: 1.0
**Last Updated**: November 15, 2025
**Status**: Ready for Implementation
