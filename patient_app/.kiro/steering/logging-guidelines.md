---
inclusion: always
---

# Logging Guidelines for AI Agents

This steering file provides mandatory logging practices for all AI agents working on this project.

## Core Principle

**Every significant action, state change, or error MUST be logged using AppLogger.**

## When to Log

### ALWAYS Log These Events

1. **Function Entry/Exit** (for important operations)
   ```dart
   Future<void> importantOperation() async {
     await AppLogger.info('Starting important operation');
     try {
       // ... work ...
       await AppLogger.info('Important operation completed successfully');
     } catch (e, stackTrace) {
       await AppLogger.error('Important operation failed', error: e, stackTrace: stackTrace);
       rethrow;
     }
   }
   ```

2. **State Changes**
   ```dart
   await AppLogger.info('User logged in', context: {'userId': user.id});
   await AppLogger.info('Space switched', context: {'from': oldSpace, 'to': newSpace});
   ```

3. **Navigation**
   ```dart
   await AppLogger.logNavigation('HomeScreen', 'SettingsScreen');
   await AppLogger.logScreenLoad('SettingsScreen');
   ```

4. **Data Operations**
   ```dart
   await AppLogger.info('Record created', context: {'recordId': record.id, 'type': record.type});
   await AppLogger.info('Record updated', context: {'recordId': record.id, 'changes': changes});
   await AppLogger.info('Record deleted', context: {'recordId': record.id});
   ```

5. **Errors and Exceptions**
   ```dart
   try {
     await riskyOperation();
   } catch (e, stackTrace) {
     await AppLogger.error('Operation failed', error: e, stackTrace: stackTrace, context: {
       'operation': 'riskyOperation',
       'userId': currentUser?.id,
     });
     rethrow;
   }
   ```

6. **Performance-Critical Operations**
   ```dart
   final opId = AppLogger.startOperation('database_query');
   try {
     final results = await database.query();
     await AppLogger.endOperation(opId);
     return results;
   } catch (e) {
     await AppLogger.endOperation(opId);
     rethrow;
   }
   ```

7. **Lifecycle Events**
   ```dart
   @override
   void initState() {
     super.initState();
     AppLogger.info('MyWidget initialized');
   }
   
   @override
   void dispose() {
     AppLogger.info('MyWidget disposing');
     super.dispose();
   }
   ```

### DON'T Log These

1. **Build method calls** - Too noisy, use sparingly only for debugging specific issues
2. **Getter/setter calls** - Unless they have side effects
3. **Private implementation details** - Focus on public API and state changes
4. **Sensitive data** - Privacy filter will redact, but avoid logging passwords, tokens, etc.

## Log Levels

Use appropriate log levels:

- **`trace`** - Extremely detailed debugging (rarely used)
- **`debug`** - Development information (use during feature development, remove or change to info when done)
- **`info`** - Normal operational messages (default for most logging)
- **`warning`** - Potentially harmful situations (performance issues, deprecated usage)
- **`error`** - Error events that might still allow the app to continue
- **`fatal`** - Severe errors that will likely cause the app to crash

## Context is King

Always provide context with your logs:

```dart
// ❌ Bad - No context
await AppLogger.info('Operation completed');

// ✅ Good - Rich context
await AppLogger.info('Operation completed', context: {
  'operation': 'importRecords',
  'recordCount': records.length,
  'duration': duration.inMilliseconds,
  'source': 'file_picker',
});
```

## Privacy Considerations

The privacy filter automatically redacts:
- Email addresses
- Phone numbers
- Credit card numbers
- SSNs
- API keys/tokens

But you should still:
- Avoid logging full user data objects
- Use IDs instead of names when possible
- Be mindful of what context you include

## Performance Tracking

For operations that might be slow:

```dart
final opId = AppLogger.startOperation('load_records');
try {
  final records = await recordsRepository.getAll();
  await AppLogger.endOperation(opId);
  return records;
} catch (e, stackTrace) {
  await AppLogger.error('Failed to load records', error: e, stackTrace: stackTrace);
  await AppLogger.endOperation(opId);
  rethrow;
}
```

Operations taking longer than 1 second (configurable in `logging_config.json`) will be logged as warnings.

## Nested Operations

For complex operations with multiple steps:

```dart
final mainOp = AppLogger.startOperation('sync_data');
try {
  final fetchOp = AppLogger.startOperation('fetch_remote', parentId: mainOp);
  final remoteData = await fetchRemoteData();
  await AppLogger.endOperation(fetchOp);
  
  final mergeOp = AppLogger.startOperation('merge_local', parentId: mainOp);
  await mergeWithLocal(remoteData);
  await AppLogger.endOperation(mergeOp);
  
  await AppLogger.endOperation(mainOp);
} catch (e, stackTrace) {
  await AppLogger.error('Sync failed', error: e, stackTrace: stackTrace);
  await AppLogger.endOperation(mainOp);
  rethrow;
}
```

## Correlation IDs

For tracking related operations across multiple functions:

```dart
final correlationId = 'import_${DateTime.now().millisecondsSinceEpoch}';

await AppLogger.info('Starting import', correlationId: correlationId);
await processFile(file, correlationId);
await saveRecords(records, correlationId);
await AppLogger.info('Import complete', correlationId: correlationId);
```

## Common Patterns

### Widget Lifecycle
```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    AppLogger.info('MyWidget initialized');
  }
  
  @override
  void dispose() {
    AppLogger.info('MyWidget disposing');
    super.dispose();
  }
}
```

### Async Operations
```dart
Future<void> myAsyncOperation() async {
  await AppLogger.info('Starting async operation');
  try {
    final result = await someAsyncWork();
    await AppLogger.info('Async operation completed', context: {'result': result});
  } catch (e, stackTrace) {
    await AppLogger.error('Async operation failed', error: e, stackTrace: stackTrace);
    rethrow;
  }
}
```

### User Actions
```dart
void onButtonPressed() async {
  await AppLogger.info('User pressed save button', context: {
    'screen': 'EditRecordScreen',
    'recordId': record.id,
  });
  
  try {
    await saveRecord(record);
    await AppLogger.info('Record saved successfully');
  } catch (e, stackTrace) {
    await AppLogger.error('Failed to save record', error: e, stackTrace: stackTrace);
    // Show error to user
  }
}
```

## Debugging Crashes

When investigating crashes:

1. **Check crash logs first**:
   ```powershell
   .\get_crash_logs.ps1
   ```

2. **Look for patterns** in `retrieved_logs/`:
   - Last operations before crash
   - Memory warnings
   - Repeated errors

3. **Add more logging** if needed:
   - Increase log level to `debug` in `assets/config/logging_config.json`
   - Add operation tracking around suspected code
   - Log memory snapshots: `await DiagnosticSystem.getMemorySnapshot()`

4. **Check for common issues**:
   - Infinite rebuild loops (repeated log messages)
   - Memory leaks (increasing memory in logs)
   - Uncaught exceptions (fatal errors in logs)

## Configuration

Log configuration is in `assets/config/logging_config.json`:

```json
{
  "minLevel": "info",           // Change to "debug" for verbose logging
  "consoleEnabled": true,        // Console output
  "fileEnabled": true,           // File logging
  "maxFileSize": 5242880,        // 5MB per file
  "maxFiles": 5,                 // Keep 5 files
  "performanceThreshold": 1000   // Warn if operation > 1s
}
```

## AI Agent Checklist

When writing new code:

- [ ] Added `await AppLogger.info()` for significant operations
- [ ] Added `await AppLogger.error()` in catch blocks
- [ ] Used `AppLogger.startOperation()` for performance-critical code
- [ ] Included context with all log messages
- [ ] Avoided logging sensitive data
- [ ] Used appropriate log levels
- [ ] Tested that logs appear correctly
- [ ] Checked that no infinite logging loops exist

## References

- `DIAGNOSTIC_SYSTEM_INTEGRATION.md` - Full logging system documentation
- `GLOBAL_ERROR_HANDLING_SUMMARY.md` - Error handling patterns
- `CRASH_DETECTION_SUMMARY.md` - Crash detection and log preservation
- `PERFORMANCE_TRACKING_SUMMARY.md` - Performance logging details
- `KNOWN_ISSUES_AND_FIXES.md` - Common issues and solutions

## Quick Reference

```dart
// Info logging
await AppLogger.info('Message', context: {'key': 'value'});

// Error logging
await AppLogger.error('Error message', error: e, stackTrace: stackTrace);

// Performance tracking
final opId = AppLogger.startOperation('operation_name');
// ... work ...
await AppLogger.endOperation(opId);

// Navigation
await AppLogger.logNavigation('FromScreen', 'ToScreen');
await AppLogger.logScreenLoad('ScreenName');

// Lifecycle
await AppLogger.logAppLifecycle('paused');

// Memory snapshot
final snapshot = await DiagnosticSystem.getMemorySnapshot();
```

---

**Remember**: Good logging is your best debugging tool. When in doubt, log it!
