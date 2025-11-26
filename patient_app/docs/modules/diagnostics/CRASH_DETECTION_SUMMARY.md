Status: ACTIVE

# Crash Detection Summary

## System
- Marker file `.app_running` created on start, removed on graceful shutdown.
- On next start: if marker exists -> crash detected; log error, preserve last log file, save crash info.

## Preservation
- Logs: rotating in `logs/`; preserved copies in `crash_logs/` as `crash_YYYY-MM-DD_HH-MM-SS.log`.
- Metadata: `last_crash.json` with crashTime, detectedTime, lastLogFile, context.

## API
- `DiagnosticSystem.getLastCrashInfo()` -> `CrashInfo?` with description/log path.
- `DiagnosticSystem.getCrashLogFiles()` -> list preserved logs.
- `DiagnosticSystem.clearCrashLogs()` -> cleanup.
- Direct detector access: `DiagnosticSystem.crashDetector` to mark start/stop.

## Lifecycle Hook Example
```dart
class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      DiagnosticSystem.shutdown(); // removes marker, flushes logs
    }
  }
}
```

## Usage (Android paths)
- Marker: `/data/data/com.example.patient_app/files/.app_running`
- Logs: `/data/data/com.example.patient_app/files/logs/`
- Crash logs: `/data/data/com.example.patient_app/files/crash_logs/`

## Testing
- Force crash (throw/exit/assert); restart app; expect "Previous crash detected" log + preserved file.

## Limitations
- Instant kills/power loss/ADB kill may be indistinguishable; check context + device logs.

## Future Enhancements
- Diagnostics UI: view/export/clear crash logs, history, trends, analytics.
