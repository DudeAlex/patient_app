# Diagnostic and Debugging System - Requirements

## Introduction

A comprehensive diagnostic and logging system to help developers and AI understand application behavior, especially during crashes, performance issues, and unexpected behavior. The system provides centralized logging, crash detection, performance monitoring, and exportable diagnostics.

## Glossary

- **Logger**: The central logging service that collects and writes log entries
- **Log Level**: Severity classification (trace, debug, info, warning, error, fatal)
- **Log Entry**: A single logged event with timestamp, level, message, and metadata
- **Crash Marker**: A flag indicating the previous app session ended unexpectedly
- **Correlation ID**: A unique identifier linking related log entries across operations
- **Session ID**: A unique identifier for the current app session
- **Log Rotation**: Automatic archiving and deletion of old log files
- **Diagnostic Export**: User-initiated export of logs and system information
- **Context Metadata**: Environment information attached to every log entry
- **Performance Marker**: Timing information for heavy operations

## Requirements

### Requirement 1: Centralized Logging System

**User Story:** As a developer, I want a unified logging system so that all important events are collected in one place.

#### Acceptance Criteria

1. THE System SHALL provide a singleton Logger service accessible throughout the application
2. WHEN a log entry is created, THE Logger SHALL write it to both console and local file
3. THE Logger SHALL support multiple log levels (trace, debug, info, warning, error, fatal)
4. THE Logger SHALL format log entries consistently with timestamp, level, and message
5. THE Logger SHALL be thread-safe for concurrent logging operations

### Requirement 2: Lifecycle and Initialization Logging

**User Story:** As a developer, I want to track application lifecycle events so that I can identify what happens before crashes.

#### Acceptance Criteria

1. WHEN the application starts, THE System SHALL log app initialization with version and build number
2. WHEN a screen is navigated to, THE System SHALL log the navigation event with screen name
3. WHEN a heavy operation begins, THE System SHALL log the operation start with operation ID
4. WHEN a heavy operation completes, THE System SHALL log the operation end with duration
5. WHEN the application is paused or resumed, THE System SHALL log the lifecycle state change

### Requirement 3: Global Error and Exception Handling

**User Story:** As a developer, I want all unhandled errors captured so that no crash goes unnoticed.

#### Acceptance Criteria

1. THE System SHALL intercept all unhandled Dart exceptions with FlutterError.onError
2. THE System SHALL intercept all unhandled async errors with PlatformDispatcher.onError
3. WHEN an exception is caught, THE System SHALL log the full stack trace
4. WHEN an exception is caught, THE System SHALL log relevant context metadata
5. THE System SHALL mark a crash occurred for detection on next startup

### Requirement 4: Configurable Logging Control

**User Story:** As a developer, I want to control logging behavior without changing code so that I can adjust verbosity as needed.

#### Acceptance Criteria

1. THE System SHALL read logging configuration from a JSON file
2. THE Configuration SHALL support setting minimum log level (trace, debug, info, warning, error, fatal)
3. THE Configuration SHALL support per-module log filtering with include/exclude patterns
4. THE Configuration SHALL support enabling or disabling file output
5. THE Configuration SHALL support enabling or disabling console output
6. WHEN configuration changes, THE System SHALL apply new settings without restart

### Requirement 5: Context Metadata in Every Log Entry

**User Story:** As a developer, I want environment information in every log so that I can understand the context of issues.

#### Acceptance Criteria

1. THE System SHALL include app version and build number in every log entry
2. THE System SHALL include environment (dev, test, prod) in every log entry
3. THE System SHALL detect and include device type (emulator or physical) in every log entry
4. THE System SHALL include OS version in every log entry
5. THE System SHALL include session ID in every log entry
6. THE System SHALL include correlation ID when provided for operation grouping

### Requirement 6: Performance Timing and Heavy Operation Markers

**User Story:** As a developer, I want to measure operation duration so that I can identify performance bottlenecks.

#### Acceptance Criteria

1. THE System SHALL provide a method to start timing an operation with a unique ID
2. THE System SHALL provide a method to end timing and log the duration
3. WHEN an operation exceeds a threshold (configurable), THE System SHALL log a warning
4. THE System SHALL support nested operation timing with parent-child relationships
5. THE System SHALL include operation timing in diagnostic exports

### Requirement 7: Crash Marker System

**User Story:** As a developer, I want to know if the previous session crashed so that I can investigate the cause.

#### Acceptance Criteria

1. WHEN the app starts, THE System SHALL create a crash marker file
2. WHEN the app shuts down gracefully, THE System SHALL remove the crash marker file
3. WHEN the app starts and a crash marker exists, THE System SHALL log "Previous session crashed"
4. WHEN a crash is detected, THE System SHALL preserve the last log file for analysis
5. THE System SHALL include crash detection status in diagnostic exports

### Requirement 8: Exportable Diagnostics

**User Story:** As a user, I want to export diagnostic logs so that I can share them for analysis.

#### Acceptance Criteria

1. THE System SHALL provide a diagnostics screen accessible from settings
2. WHEN the user taps "Export Diagnostics", THE System SHALL create a ZIP file containing logs and system info
3. THE Export SHALL include all log files from the current session
4. THE Export SHALL include a system information file with device details
5. THE Export SHALL include crash marker status and last crash timestamp
6. THE System SHALL use the platform share dialog to export the ZIP file

### Requirement 9: Log Rotation and Size Limits

**User Story:** As a developer, I want logs to be automatically managed so that they don't consume excessive storage.

#### Acceptance Criteria

1. THE System SHALL limit individual log files to a maximum size (configurable, default 5MB)
2. WHEN a log file reaches maximum size, THE System SHALL rotate to a new file
3. THE System SHALL keep a maximum number of log files (configurable, default 5)
4. WHEN the maximum number of files is reached, THE System SHALL delete the oldest file
5. THE System SHALL include rotation timestamp in log file names

### Requirement 10: Privacy and Redaction Rules

**User Story:** As a user, I want my sensitive data protected in logs so that my privacy is maintained.

#### Acceptance Criteria

1. THE System SHALL NOT log user email addresses in plain text
2. THE System SHALL NOT log health record content (titles, notes, attachments)
3. THE System SHALL redact sensitive fields with "[REDACTED]" placeholder
4. THE System SHALL log only record IDs and types, not content
5. THE System SHALL provide a whitelist of safe fields that can be logged

### Requirement 11: Smooth Integration

**User Story:** As a developer, I want the diagnostic system to integrate cleanly so that existing code is not disrupted.

#### Acceptance Criteria

1. THE System SHALL be initialized in main() before runApp()
2. THE System SHALL not require changes to existing screens or widgets
3. THE System SHALL provide simple helper methods for common logging patterns
4. THE System SHALL work with existing error handling without conflicts
5. THE System SHALL be optional and can be disabled via configuration

