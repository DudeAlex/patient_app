Status: ACTIVE

# Log Structure Guide

## Format
- JSON entries with id, timestamp, level, message, module, context, environment (appVersion, buildNumber, platform, deviceType, osVersion, sessionId).
- Levels: trace/debug/info/warning/error/fatal.
- Files: rotating logs in app docs dir (`logs/`), max 5MB, keep 10.

## Usage
- Info: `AppLogger.info('msg', context: {...});`
- Error: `AppLogger.error('msg', error: e, stackTrace: st, context: {...});`
- Navigation/screen: `logNavigation`, `logScreenLoad`; lifecycle: `logAppLifecycle`.
- Performance: `startOperation/endOperation` with optional parentId; warns if duration > threshold.

## Context Tips
- Always include operation identifiers, record/space ids, counts, durations; avoid sensitive data (filter redacts common PII).
- Use correlation ids for multi-step flows.

## File Locations
- Regular logs: `.../files/logs/`
- Crash-preserved logs: `.../files/crash_logs/`

## Debugging
- For crashes/disconnects, pull latest log or crash log; review context/durations; raise log level to debug in config if needed.
