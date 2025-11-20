# Diagnostic System - Implementation Tasks

## Implementation Status

**Completed:** Phase 1-7 (Core through Global Error Handling) + App Integration  
**Current Phase:** Phase 8 (Lifecycle Logging)  
**Next Up:** Task 11 - Lifecycle tracking helpers

### What's Done
- ✅ All core models (LogLevel, LogEntry, EnvironmentContext, LogConfig, CrashInfo)
- ✅ Configuration JSON file with default settings
- ✅ All dependencies added to pubspec.yaml
- ✅ PrivacyFilter service with comprehensive redaction
- ✅ LogWriter interface with Console and File implementations
- ✅ File rotation and cleanup logic
- ✅ Core LoggerService with filtering and privacy
- ✅ AppLogger static facade with simple API
- ✅ DiagnosticSystem initialization
- ✅ **Integrated into main.dart and app.dart**
- ✅ **Lifecycle logging active**
- ✅ **Error logging in app initialization**
- ✅ **Performance tracking (startOperation/endOperation)**
- ✅ **Timing in bootstrap, RecordsService, SpaceProvider**
- ✅ **Slow operation warnings**
- ✅ **Crash detection with marker file**
- ✅ **Crash log preservation**
- ✅ **Graceful shutdown handling**
- ✅ **Global error handler (FlutterError, PlatformDispatcher, async)**
- ✅ **All uncaught exceptions logged**
- ✅ **Fatal error detection**

### What's Remaining
- Navigation observer (automatic route logging)
- UI components (DiagnosticsScreen)
- Diagnostic export functionality
- Additional logging integration with features

---

## Task Overview

This implementation plan breaks down the diagnostic system into incremental, testable tasks. Each task builds on previous work and can be verified independently.

---

## Phase 1: Core Infrastructure ✅ COMPLETED

### Task 1: Core Models and Enums ✅ COMPLETED

- [x] 1.1 Create LogLevel enum (trace, debug, info, warning, error, fatal)
  - Define enum with severity ordering
  - Add comparison methods
  - _Requirements: 1.3, 4.2_

- [x] 1.2 Create LogEntry model
  - Implement all fields (id, timestamp, level, message, context, etc.)
  - Add toJson() and toFormattedString() methods
  - Add factory constructor for creation
  - _Requirements: 1.4, 5.1-5.6_

- [x] 1.3 Create EnvironmentContext model
  - Implement device detection (emulator vs physical)
  - Gather OS version, platform, app version
  - Generate session ID
  - Cache context for reuse
  - _Requirements: 5.1-5.6_

- [x] 1.4 Create LogConfig model
  - Define all configuration fields
  - Implement fromJson() factory
  - Add validation logic
  - _Requirements: 4.1-4.5_

---

## Phase 2: Configuration and Privacy ✅ COMPLETED

### Task 2: Configuration Management ✅ COMPLETED

- [x] 2.1 Create logging_config.json asset file
  - Define default configuration
  - Add comments explaining each field
  - _Requirements: 4.1_

- [x] 2.2 Implement ConfigManager service (integrated into LogConfig)
  - Load configuration from JSON file
  - Support runtime config updates
  - Provide default fallback config
  - _Requirements: 4.1, 4.6_

### Task 3: Privacy and Security ✅ COMPLETED

- [x] 3.1 Implement PrivacyFilter service
  - Define sensitive field list (email, password, health data, etc.)
  - Implement redaction logic for maps (recursive)
  - Implement redaction logic for strings (regex patterns)
  - Add whitelist for safe fields (IDs, counts, timestamps)
  - _Requirements: 10.1-10.5_

- [ ]* 3.2 Add privacy filter tests
  - Test email redaction
  - Test content redaction
  - Test safe field pass-through
  - _Requirements: 10.1-10.5_

---

## Phase 3: Log Writers ✅ COMPLETED

### Task 4: Log Writer Interface and Console Writer ✅ COMPLETED

- [x] 4.1 Create LogWriter interface
  - Define write(), flush(), close() methods
  - _Requirements: 1.2_

- [x] 4.2 Implement ConsoleLogWriter
  - Write formatted logs to console
  - Add color coding by log level (ANSI colors)
  - Integration with Flutter DevTools
  - Implement flush and close (no-ops for console)
  - _Requirements: 1.2, 4.4_

### Task 5: File Log Writer with Rotation ✅ COMPLETED

- [x] 5.1 Implement FileLogWriter
  - Write logs to file with buffering
  - Generate timestamped file names
  - JSON format for structured logging
  - _Requirements: 1.2, 4.3, 9.1_

- [x] 5.2 Add log rotation logic
  - Check file size before writing
  - Rotate to new file when limit reached
  - Automatic initialization and file management
  - _Requirements: 9.1, 9.2, 9.5_

- [x] 5.3 Add old file cleanup
  - Track number of log files
  - Delete oldest files when limit exceeded
  - Sorted by timestamp for proper cleanup
  - _Requirements: 9.3, 9.4_

---

## Phase 4: Core Logging Service ✅ COMPLETED

### Task 6: Logger Service Implementation ✅ COMPLETED

- [x] 6.1 Implement LoggerService
  - Initialize with config and writers
  - Implement log() method with filtering
  - Add shouldLog() level and module filtering
  - Multi-writer support with error handling
  - _Requirements: 1.1, 1.3, 4.2, 4.3_

- [x] 6.2 Integrate PrivacyFilter into LoggerService
  - Apply filter to all log context data
  - Redact sensitive fields automatically
  - Configurable privacy filter
  - _Requirements: 10.1-10.5_

- [x] 6.3 Add environment context to all logs
  - Inject EnvironmentContext into every LogEntry
  - Cache context for performance
  - Session tracking
  - _Requirements: 5.1-5.6_

### Task 7: AppLogger Facade ✅ COMPLETED

- [x] 7.1 Create AppLogger static facade
  - Implement trace(), debug(), info(), warning(), error(), fatal()
  - Add optional context parameter
  - Add error and stackTrace parameters for error/fatal
  - Simple, clean API for app-wide use
  - _Requirements: 1.1, 1.3_

- [x] 7.2 Add module detection to AppLogger
  - Automatically detect calling module from stack trace
  - Regex-based module extraction
  - Fallback to 'unknown' module
  - _Requirements: 4.3_

---

## Phase 5: Performance Tracking ✅ COMPLETED

### Task 8: Performance Monitoring ✅ COMPLETED

- [x] 8.1 Create OperationTimer model
  - Track operation ID, name, start time, parent ID (integrated into AppLogger)
  - Calculate elapsed duration from timestamp in operation ID
  - _Requirements: 6.1, 6.2_

- [x] 8.2 Implement PerformanceTracker service
  - Manage active operations map (integrated into AppLogger)
  - Generate unique operation IDs with timestamps
  - Support nested operations via parentId parameter
  - _Requirements: 6.1, 6.4_

- [x] 8.3 Add performance methods to AppLogger
  - Implement startOperation() with parentId support
  - Implement endOperation() with duration logging
  - Log warning if duration exceeds threshold (from config)
  - Integrated into bootstrap, RecordsService, and SpaceProvider
  - _Requirements: 6.2, 6.3_

---

## Phase 6: Crash Detection ✅ COMPLETED

### Task 9: Crash Detection System ✅ COMPLETED

- [x] 9.1 Create CrashInfo model
  - Store crash timestamp and detection time
  - Store last log file path
  - Human-readable description
  - JSON serialization
  - _Requirements: 7.3, 7.5_

- [x] 9.2 Implement CrashDetector service
  - Create crash marker file on app start
  - Remove marker on graceful shutdown
  - Detect crash on next startup by checking marker
  - Initialize and manage marker file
  - _Requirements: 7.1, 7.2, 7.3_

- [x] 9.3 Add crash log preservation
  - Copy last log file to crash_logs/ directory
  - Include crash timestamp in filename
  - Automatic preservation on crash detection
  - Methods to list and clear crash logs
  - _Requirements: 7.4_

- [x] 9.4 Integrate crash detection into app startup
  - Check for crash on app launch
  - Log crash detection event with full context
  - Mark app started after check
  - Integrated into DiagnosticSystem.initialize()
  - _Requirements: 7.3_

---

## Phase 7: Global Error Handling ✅ COMPLETED

### Task 10: Error Interception ✅ COMPLETED

- [x] 10.1 Create GlobalErrorHandler
  - Intercept FlutterError.onError for framework errors
  - Intercept PlatformDispatcher.onError for platform errors
  - Use runZonedGuarded for async errors
  - Log all errors with full context
  - Distinguish between fatal and non-fatal errors
  - Preserve original error handlers
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 10.2 Mark crashes in error handler
  - Fatal errors logged with AppLogger.fatal()
  - Crash marker remains set (not removed on fatal error)
  - CrashDetector will detect crash on next startup
  - Integrated into main() via runGuarded()
  - _Requirements: 3.5_

---

## Phase 8: Lifecycle Logging

### Task 11: Lifecycle Tracking

- [ ] 11.1 Add navigation logging helper
  - Implement logNavigation() in AppLogger
  - _Requirements: 2.2_

- [ ] 11.2 Add screen load logging helper
  - Implement logScreenLoad() in AppLogger
  - _Requirements: 2.2_

- [ ] 11.3 Add app lifecycle logging helper
  - Implement logAppLifecycle() in AppLogger
  - _Requirements: 2.5_

- [ ] 11.4 Create AppNavigatorObserver
  - Observe route changes
  - Log navigation events automatically
  - _Requirements: 2.2_

---

## Phase 9: Diagnostic Export

### Task 12: Export Functionality

- [ ] 12.1 Implement DiagnosticExporter service
  - Collect all log files
  - Collect system information
  - Collect crash information
  - _Requirements: 8.2, 8.3, 8.4, 8.5_

- [ ] 12.2 Add ZIP creation
  - Create organized ZIP structure
  - Include logs, system info, crash info
  - Generate timestamped filename
  - _Requirements: 8.2_

- [ ] 12.3 Add platform share integration
  - Use share_plus package
  - Share ZIP file via platform dialog
  - _Requirements: 8.6_

---

## Phase 10: User Interface

### Task 13: Diagnostics Screen

- [ ] 13.1 Create DiagnosticsScreen
  - Display current session information
  - Show log file list with sizes
  - Show crash detection status
  - _Requirements: 8.1_

- [ ] 13.2 Add export button
  - Trigger diagnostic export
  - Show progress indicator
  - Handle errors gracefully
  - _Requirements: 8.2_

- [ ] 13.3 Add clear logs button
  - Delete all log files
  - Confirm with user dialog
  - _Requirements: 9.3_

- [ ] 13.4 Add log level selector
  - Allow runtime log level adjustment
  - Update configuration
  - _Requirements: 4.2, 4.6_

### Task 14: Settings Integration

- [ ] 14.1 Add Diagnostics option to Settings screen
  - Add list tile with icon
  - Navigate to DiagnosticsScreen
  - _Requirements: 8.1, 11.5_

---

## Phase 11: Integration and Testing

### Task 15: Main App Integration ✅ PARTIALLY COMPLETED

- [x] 15.1 Initialize diagnostic system in main()
  - Load configuration
  - Initialize logger service
  - Log app startup
  - Log app lifecycle events
  - _Requirements: 2.1, 3.1, 7.3, 11.1_

- [ ] 15.2 Add graceful shutdown handling
  - Remove crash marker on app dispose
  - Flush all log writers
  - _Requirements: 7.2_

- [x] 15.3 Add logging to app initialization
  - Log RecordsService initialization (with errors)
  - Log SpaceProvider initialization (with errors)
  - Log onboarding flow
  - Log screen loads
  - _Requirements: 2.3, 2.4_

### Task 16: Add Logging to Existing Features

- [ ] 16.1 Add logging to RecordsService
  - Log database operations
  - Log query performance
  - _Requirements: 2.3, 6.1_

- [ ] 16.2 Add logging to SpaceManager
  - Log space operations
  - Log space switching
  - _Requirements: 2.3_

- [ ] 16.3 Add logging to MigrationService
  - Already has some logging, enhance with AppLogger
  - Add performance tracking
  - _Requirements: 2.3, 2.4, 6.1_

---

## Phase 12: Documentation and Polish

### Task 17: Documentation

- [ ]* 17.1 Create DIAGNOSTIC_SYSTEM_USAGE.md
  - Document how to use AppLogger
  - Provide code examples
  - Explain configuration options
  - _Requirements: All_

- [ ]* 17.2 Update README.md
  - Add Diagnostics System to features
  - Mention diagnostic export capability
  - _Requirements: All_

- [ ]* 17.3 Add inline code documentation
  - Document all public APIs
  - Add usage examples in doc comments
  - _Requirements: All_

---

## Dependencies Between Tasks

```
Phase 1 (Tasks 1) → Phase 2 (Tasks 2-3) → Phase 3 (Tasks 4-5) → Phase 4 (Tasks 6-7)
                                                                         ↓
Phase 5 (Task 8) ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ←
     ↓
Phase 6 (Task 9) → Phase 7 (Task 10) → Phase 8 (Task 11) → Phase 9 (Task 12)
                                                                         ↓
                                                            Phase 10 (Tasks 13-14)
                                                                         ↓
                                                            Phase 11 (Tasks 15-16)
                                                                         ↓
                                                            Phase 12 (Task 17)
```

## Testing Strategy

### Unit Tests (Per Task)
- Test models (LogEntry, EnvironmentContext, etc.)
- Test privacy filter redaction
- Test log level filtering
- Test file rotation logic
- Test performance tracking

### Integration Tests (After Phase 11)
- Test end-to-end logging flow
- Test crash detection and recovery
- Test diagnostic export
- Test configuration loading

### Manual Tests (After Phase 12)
- Verify logs in console
- Verify log files created
- Trigger crash and verify detection
- Export diagnostics and verify contents
- Test with different log levels

---

## Implementation Notes

### Completed Work
Phase 1 is fully complete with all core models implemented and tested. The foundation is solid with:
- Comprehensive LogLevel enum with severity ordering
- Rich LogEntry model with JSON serialization and formatted output
- EnvironmentContext with device detection and caching
- LogConfig with pattern matching for module filtering
- Configuration JSON file ready to use

### Next Steps
Start with Task 2.2 (ConfigManager service) to enable runtime configuration management. This will allow the logging system to be configured dynamically and provide the foundation for the core logging engine.

### Key Dependencies
- Tasks 2-3 must complete before Task 4 (Writers need privacy filtering)
- Tasks 4-5 must complete before Task 6 (LoggerService needs writers)
- Task 6 must complete before Task 7 (AppLogger facade needs LoggerService)
- Task 7 must complete before Tasks 8-16 (all features depend on AppLogger)

### Testing Strategy
- Optional test tasks (marked with *) focus on unit testing individual components
- Core functionality testing happens during implementation via manual verification
- Integration testing occurs in Phase 11 after all components are wired together

---

**Total Tasks**: 17 major tasks, ~60 subtasks  
**Completed**: 1 major task (Phase 1) + configuration file  
**Remaining**: 16 major tasks  
**Estimated Effort**: 2-3 weeks for full implementation  
**Priority**: High - Critical for debugging emulator issues
