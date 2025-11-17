# Known Issues and Fixes

This document tracks resolved issues and their fixes to help future debugging and prevent regressions.

## Critical Fixes (November 2025)

### Issue #1: App Crash on Onboarding - Infinite Rebuild Loop
**Date Fixed**: November 16, 2025
**Severity**: Critical - App crashed emulator
**Symptoms**:
- App crashes after navigating through onboarding pages
- Emulator disconnects ("Lost connection to device")
- Logs show repeated "Building space selection step" messages
- No crash logs preserved (crash too severe)

**Root Causes**:
1. **FutureBuilder creating new Future on every build** in `lib/ui/app.dart`
   - `FutureBuilder(future: spaceProvider.hasCompletedOnboarding())` was called on every build
   - This created a new Future each time, triggering infinite rebuilds
   - Each rebuild triggered more state changes, cascading into crash

2. **Invalid Color serialization** in `lib/core/domain/value_objects/space_gradient.dart`
   - Used non-existent `Color.toARGB32()` method
   - Should have been `Color.value` property
   - Caused crashes when trying to serialize gradients

3. **Unnecessary ChangeNotifierProvider wrapper** in `lib/ui/app.dart`
   - OnboardingScreen was wrapped in `ChangeNotifierProvider.value(value: spaceProvider)`
   - This caused the entire screen to rebuild every time SpaceProvider called `notifyListeners()`
   - OnboardingScreen doesn't need to listen to provider changes, only needs the instance
   - This was the primary cause of the rapid rebuilds and crash

**Fixes Applied**:
```dart
// Fix 1: Cache FutureBuilder futures in _RecordsLoaderState
class _RecordsLoaderState extends State<_RecordsLoader> {
  Future<SpaceProvider>? _spaceProviderFuture;
  Future<bool>? _onboardingCheckFuture;  // Added this cache
  
  // In build method:
  _onboardingCheckFuture ??= spaceProvider.hasCompletedOnboarding();
  return FutureBuilder<bool>(
    future: _onboardingCheckFuture,  // Use cached future
    ...
  );
}

// Fix 2: Correct Color serialization in SpaceGradient
Map<String, dynamic> toJson() {
  return {
    'startColor': startColor.value,  // Changed from toARGB32()
    'endColor': endColor.value,      // Changed from toARGB32()
  };
}

// Fix 3: Remove unnecessary ChangeNotifierProvider wrapper
// Before (WRONG):
if (!hasCompletedOnboarding && !_onboardingCompleted) {
  return ChangeNotifierProvider.value(  // This caused rebuilds!
    value: spaceProvider,
    child: OnboardingScreen(
      spaceProvider: spaceProvider,
      onComplete: _handleOnboardingComplete,
    ),
  );
}

// After (CORRECT):
if (!hasCompletedOnboarding && !_onboardingCompleted) {
  return OnboardingScreen(  // No provider wrapper needed
    spaceProvider: spaceProvider,
    onComplete: _handleOnboardingComplete,
  );
}
```

**Prevention**:
- Always cache Future instances used in FutureBuilder
- Never create new Futures in build methods
- Use `getDiagnostics` tool to check for compilation errors
- Test with memory monitoring enabled

**Related Files**:
- `lib/ui/app.dart` - Main app initialization and FutureBuilder caching
- `lib/core/domain/value_objects/space_gradient.dart` - Color serialization
- `lib/features/spaces/ui/onboarding_screen.dart` - Onboarding flow

---

### Issue #2: Layout Overflow on Onboarding Features Screen
**Date Fixed**: November 16, 2025
**Severity**: Medium - Visual issue
**Symptoms**:
- Yellow and black striped pattern at bottom of screen
- "RenderFlex overflowed by 68 pixels" error
- Content not scrollable on smaller screens

**Root Cause**:
- Features overview step used `Column` with `mainAxisAlignment: center`
- Content height exceeded available space
- No scrolling mechanism provided

**Fix Applied**:
```dart
// Changed from Padding + Column to SingleChildScrollView
Widget _buildFeaturesOverviewStep() {
  return SingleChildScrollView(  // Added scrolling
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ... content
      ],
    ),
  );
}
```

**Prevention**:
- Use `SingleChildScrollView` for content that might overflow
- Test on different screen sizes
- Watch for overflow warnings in logs

**Related Files**:
- `lib/features/spaces/ui/onboarding_screen.dart`

---

## Debugging Tools Added

### Memory Monitor
**Location**: `lib/core/diagnostics/services/memory_monitor.dart`
**Purpose**: Track memory usage and detect leaks
**Usage**:
```dart
// Automatically started by DiagnosticSystem
// Logs memory snapshots every 5 seconds
// Warns when memory increases > 10MB

// Manual snapshot:
final snapshot = await DiagnosticSystem.getMemorySnapshot();
```

### Crash Log Retrieval Script
**Location**: `get_crash_logs.ps1`
**Purpose**: Retrieve logs from Android emulator
**Usage**:
```powershell
# Start emulator first
flutter emulators --launch Pixel

# Wait for boot, then retrieve logs
.\get_crash_logs.ps1

# Logs saved to retrieved_logs/ directory
```

**What it retrieves**:
- Crash logs from `crash_logs/` directory
- Last crash info from `last_crash.json`
- Recent regular logs from `logs/` directory
- Crash marker file status
- System logcat errors

---

## Common Patterns to Avoid

### 1. FutureBuilder Anti-Pattern
❌ **Bad** - Creates new Future on every build:
```dart
FutureBuilder(
  future: someAsyncMethod(),  // NEW FUTURE EVERY BUILD!
  builder: (context, snapshot) { ... }
)
```

✅ **Good** - Cache the Future:
```dart
class _MyWidgetState extends State<MyWidget> {
  Future<Data>? _dataFuture;
  
  @override
  void initState() {
    super.initState();
    _dataFuture = someAsyncMethod();  // Create once
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _dataFuture,  // Reuse cached future
      builder: (context, snapshot) { ... }
    );
  }
}
```

### 2. Color Serialization
❌ **Bad** - Non-existent method:
```dart
'color': color.toARGB32()  // Does not exist!
```

✅ **Good** - Use value property:
```dart
'color': color.value  // Returns int representation
```

### 3. Scrollable Content
❌ **Bad** - Fixed height content:
```dart
Column(
  children: [
    // Lots of content that might overflow
  ],
)
```

✅ **Good** - Scrollable when needed:
```dart
SingleChildScrollView(
  child: Column(
    children: [
      // Content can scroll if needed
    ],
  ),
)
```

### 4. Provider Wrapping
❌ **Bad** - Unnecessary provider wrapper:
```dart
// Widget doesn't need to listen to changes
return ChangeNotifierProvider.value(
  value: myProvider,
  child: MyWidget(provider: myProvider),
);
```

✅ **Good** - Only wrap when widget needs to listen:
```dart
// Widget only needs provider instance, not listening
return MyWidget(provider: myProvider);

// OR if widget needs to listen to changes:
return Consumer<MyProvider>(
  builder: (context, provider, child) {
    return MyWidget(data: provider.data);
  },
);
```

---

## Diagnostic System Overview

### Log Levels
- `TRACE` - Detailed debugging (disabled in production)
- `DEBUG` - Development information
- `INFO` - General informational messages
- `WARN` - Warnings about potential issues
- `ERROR` - Error events
- `FATAL` - Severe failures

### Log Configuration
**File**: `assets/config/logging_config.json`
```json
{
  "minLevel": "info",           // Set to "debug" for verbose logs
  "consoleEnabled": true,        // Console output
  "fileEnabled": true,           // File logging
  "maxFileSize": 5242880,        // 5MB per file
  "maxFiles": 5,                 // Keep 5 files
  "performanceThreshold": 1000   // Warn if operation > 1s
}
```

### Crash Detection
- Marker file (`.app_running`) created on app start
- Removed on graceful shutdown
- If marker exists on next start → crash detected
- Crash logs automatically preserved to `crash_logs/`

### Memory Monitoring
- Tracks RSS (Resident Set Size) memory
- Logs warnings when memory increases > 10MB
- Periodic snapshots every 30 seconds
- Available via `DiagnosticSystem.getMemorySnapshot()`

---

## Testing Checklist After Fixes

When fixing crashes or performance issues:

1. ✅ Run `dart analyze` - Check for compilation errors
2. ✅ Test on emulator - Verify fix works
3. ✅ Check logs - Ensure no new errors introduced
4. ✅ Monitor memory - Watch for leaks
5. ✅ Test edge cases - Different screen sizes, orientations
6. ✅ Update documentation - Record the fix
7. ✅ Add prevention notes - Help future developers

---

## Future Improvements

### Potential Enhancements
1. Add automated memory leak detection
2. Implement performance profiling tools
3. Create automated crash reporting
4. Add UI for viewing logs in-app
5. Implement log export/sharing functionality

### Known Limitations
- Memory monitor only tracks RSS, not detailed heap analysis
- Crash detection doesn't catch instant kills (OOM, force stop)
- Log retrieval requires emulator to be running
- No automated crash reporting to external service

---

## References

- `CRASH_DETECTION_SUMMARY.md` - Detailed crash detection documentation
- `DIAGNOSTIC_SYSTEM_INTEGRATION.md` - Logging system architecture
- `TROUBLESHOOTING.md` - General troubleshooting guide
- `AGENTS.md` - Development workflow and rules
