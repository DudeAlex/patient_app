# Performance Tracking Summary

## ✅ Phase 5 Complete: Performance Monitoring

Performance tracking is now fully integrated and actively measuring operation durations throughout the app!

### What's Tracking

**Bootstrap Process:**
- `bootstrap_app_container` - Total bootstrap time
  - `initialize_database` - Database opening time
  - `run_migrations` - Migration execution time
  - `register_capture_controller` - Capture system setup time

**RecordsService Initialization:**
- `create_records_service` - Total service creation time
  - `open_isar_database` - Isar database opening
  - `initialize_repositories` - Repository setup
  - `initialize_sync_system` - Sync system initialization

**SpaceProvider Initialization:**
- `initialize_space_provider` - Total provider initialization
  - `load_active_spaces` - Loading all active spaces
  - `load_current_space` - Loading current space selection

### How It Works

**Starting an Operation:**
```dart
final opId = AppLogger.startOperation('my_operation');
// ... do work ...
await AppLogger.endOperation(opId);
```

**Nested Operations:**
```dart
final parentOp = AppLogger.startOperation('parent_operation');
final childOp = AppLogger.startOperation('child_operation', parentId: parentOp);
// ... do work ...
await AppLogger.endOperation(childOp);
await AppLogger.endOperation(parentOp);
```

**Automatic Slow Operation Detection:**
- Operations exceeding 1000ms (configurable) are logged as **warnings**
- Normal operations are logged as **info**
- Duration shown in both milliseconds and seconds

### Example Log Output

**Console (Color-Coded):**
```
[INFO] Operation started: bootstrap_app_container
[INFO] Operation started: initialize_database
[INFO] Operation completed: initialize_database (0.45s)
[INFO] Operation started: run_migrations
[INFO] Running database migrations
[INFO] Migrations completed successfully
[INFO] Operation completed: run_migrations (0.12s)
[INFO] Operation started: register_capture_controller
[INFO] Operation completed: register_capture_controller (0.03s)
[INFO] Operation completed: bootstrap_app_container (0.60s)
```

**Slow Operation Warning:**
```
[WARNING] Slow operation completed: initialize_database (1.25s)
```

**Log File (JSON):**
```json
{
  "id": "uuid",
  "timestamp": "2025-11-16T10:30:45.123Z",
  "level": "info",
  "message": "Operation started: bootstrap_app_container",
  "module": "core",
  "correlationId": "op_1_1700123445123",
  "context": {
    "operationId": "op_1_1700123445123",
    "operationName": "bootstrap_app_container"
  },
  "environment": {...}
}
```

```json
{
  "id": "uuid",
  "timestamp": "2025-11-16T10:30:45.723Z",
  "level": "info",
  "message": "Operation completed: bootstrap_app_container (0.60s)",
  "module": "core",
  "correlationId": "op_1_1700123445123",
  "context": {
    "operationId": "op_1_1700123445123",
    "operationName": "bootstrap_app_container",
    "durationMs": 600,
    "durationSeconds": 0.6
  },
  "environment": {...}
}
```

### Benefits for Debugging

**Identify Bottlenecks:**
- See exactly which initialization step is slow
- Compare durations across app launches
- Track performance regressions

**Emulator Disconnection Investigation:**
- If the emulator disconnects during initialization, logs will show:
  - Which operation was running when it happened
  - How long operations were taking before the disconnect
  - Whether any operation was unusually slow

**Nested Operation Tracking:**
- Parent operations show total time
- Child operations show individual component times
- Easy to identify which sub-step is the bottleneck

### Configuration

**Performance Threshold (in logging_config.json):**
```json
{
  "performanceThreshold": 1000
}
```

- Default: 1000ms (1 second)
- Operations exceeding this threshold are logged as warnings
- Adjust based on your performance requirements

### Adding Performance Tracking to Your Code

**Simple Operation:**
```dart
Future<void> myFunction() async {
  final opId = AppLogger.startOperation('my_function');
  
  try {
    // Your code here
    await someWork();
    
    await AppLogger.endOperation(opId);
  } catch (e, stackTrace) {
    await AppLogger.error('Operation failed', error: e, stackTrace: stackTrace);
    await AppLogger.endOperation(opId);
    rethrow;
  }
}
```

**Nested Operations:**
```dart
Future<void> complexOperation() async {
  final mainOp = AppLogger.startOperation('complex_operation');
  
  try {
    final step1 = AppLogger.startOperation('step_1', parentId: mainOp);
    await doStep1();
    await AppLogger.endOperation(step1);
    
    final step2 = AppLogger.startOperation('step_2', parentId: mainOp);
    await doStep2();
    await AppLogger.endOperation(step2);
    
    await AppLogger.endOperation(mainOp);
  } catch (e, stackTrace) {
    await AppLogger.error('Complex operation failed', error: e, stackTrace: stackTrace);
    await AppLogger.endOperation(mainOp);
    rethrow;
  }
}
```

### Current Integration Points

✅ **Bootstrap Process** (`lib/core/di/bootstrap.dart`)
- Database initialization
- Migration execution
- Capture controller registration

✅ **RecordsService** (`lib/features/records/data/records_service.dart`)
- Database opening
- Repository initialization
- Sync system setup

✅ **SpaceProvider** (`lib/features/spaces/providers/space_provider.dart`)
- Active spaces loading
- Current space loading

### What to Track Next

Consider adding performance tracking to:
- **Record CRUD operations** - Save, fetch, delete timing
- **Search operations** - Query performance
- **Image processing** - Capture and processing time
- **Sync operations** - Backup and restore timing
- **Navigation** - Screen transition time

### Viewing Performance Data

**During Development:**
- Watch console for operation timing
- Look for slow operation warnings
- Compare times across runs

**From Log Files:**
```bash
# Extract all operation timings
adb shell run-as com.example.patient_app cat files/logs/app_log_*.log | grep "Operation completed"

# Find slow operations
adb shell run-as com.example.patient_app cat files/logs/app_log_*.log | grep "Slow operation"
```

**Future (Phase 10 - Diagnostics UI):**
- View performance metrics in-app
- See operation timing charts
- Export performance reports

## 🎯 Impact on Emulator Debugging

With performance tracking active, when the emulator disconnects you'll now see:

1. **Exact timing** of each initialization step
2. **Which operation was running** when the disconnect occurred
3. **Whether any operation was slow** (potential cause)
4. **Nested operation breakdown** to pinpoint the exact sub-step

This makes it much easier to identify if the disconnect is caused by:
- A specific slow operation timing out
- A particular initialization step failing
- Resource exhaustion during a heavy operation
- A deadlock or infinite loop in a specific component

## 📊 Current Status

**Overall Progress:** ~55% complete

**Completed Phases:**
- ✅ Phase 1: Core Models
- ✅ Phase 2: Configuration & Privacy
- ✅ Phase 3: Log Writers
- ✅ Phase 4: Core Logging Service
- ✅ Phase 5: Performance Tracking
- ✅ Phase 11: Main App Integration (partial)

**Next Priority:**
- Phase 6: Crash Detection - Will help identify if the emulator disconnect is actually a crash

The performance tracking system is now live and measuring! Run the app and watch the console for operation timings.
