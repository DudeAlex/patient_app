Status: ACTIVE

# Diagnostic System Integration Summary

## Active Components
- **AppLogger**: info/error APIs, structured context.
- **Privacy filter**: redacts emails/passwords/tokens/PII/health text.
- **Console logging**: colored output + DevTools.
- **File logging**: rotating JSON (max 5MB, keep 10) in app docs dir.
- **Environment context**: app version/build, platform, device type, OS, session id, timestamp.

## Integration Points
- `main.dart`: `DiagnosticSystem.initialize()`, log app start, bootstrap DI, log lifecycle (`logAppLifecycle`).
- `app.dart`: lifecycle observer, init/error logging, screen load tracking.
- Logging now covers startup, diagnostics init, lifecycle changes, RecordsService/SpaceProvider init, onboarding flow, screen loads, debug seeding.

## Config (default `assets/logging_config.json`)
```json
{
  "minLevel": "debug",
  "consoleEnabled": true,
  "fileEnabled": true,
  "maxFileSize": 5242880,
  "maxFiles": 10,
  "performanceThreshold": 1000,
  "enabledModules": ["*"],
  "disabledModules": []
}
```

## Usage
- Info: `await AppLogger.info('Message', context: {...});`
- Error: `await AppLogger.error('Message', error: e, stackTrace: st, context: {...});`
- Navigation/screen: `logNavigation`, `logScreenLoad`; lifecycle: `logAppLifecycle`.
- Performance: `startOperation/endOperation` (warn if > threshold).

## Benefits
- Replay logs via console/DevTools or JSON files; includes context for emulator disconnects.

## Next Steps
- Finish performance tracking, crash detection, global error handling, diagnostics UI/export.
- Add module logging coverage as features land; avoid sensitive data.

## Quick Test
1) `flutter run`
2) Expect logs: "Diagnostic system initialized", "App starting", lifecycle, screen loads, service init success/fail.
3) Inspect `logs/` in app docs dir (or via `tool/get_crash_logs.ps1`).
