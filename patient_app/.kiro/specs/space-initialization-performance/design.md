# Design Document

## Overview

This design addresses the performance issue where 82 frames are skipped during SpaceProvider initialization, causing stuttering and potential crashes on small/low-end devices. The solution focuses on batching state updates, deferring UI notifications until initialization is complete, and ensuring the main thread remains responsive.

## Architecture

### Current Flow (Problematic)

```
App Start
  ↓
_RecordsLoader builds
  ↓
FutureBuilder<RecordsService> completes
  ↓
FutureBuilder<SpaceProvider> starts
  ↓
SpaceProvider.initialize() called
  ├─ notifyListeners() [Loading state]
  ├─ Load active spaces (async)
  ├─ Load current space (async)
  └─ notifyListeners() [Loaded state]
  ↓
FutureBuilder<bool> (onboarding check) starts
  ↓
hasCompletedOnboarding() called
  ↓
OnboardingScreen builds
  ↓
[82 FRAMES SKIPPED HERE]
```

### Proposed Flow (Optimized)

```
App Start
  ↓
_RecordsLoader builds
  ↓
FutureBuilder<RecordsService> completes
  ↓
FutureBuilder<SpaceProvider> starts
  ↓
SpaceProvider.initialize() called
  ├─ Load active spaces (async)
  ├─ Load current space (async)
  ├─ Check onboarding status (async)
  └─ notifyListeners() [Single update with all data]
  ↓
OnboardingScreen or HomeScreen builds
  ↓
[SMOOTH RENDERING - < 5 FRAMES SKIPPED]
```

## Components and Interfaces

### 1. SpaceProvider (Modified)

**Changes:**
- Remove `notifyListeners()` call at the start of `initialize()` (loading state)
- Batch all data loading before calling `notifyListeners()` once
- Add `_onboardingComplete` field to cache onboarding status
- Expose `onboardingComplete` getter to avoid separate async call

**New Interface:**
```dart
class SpaceProvider extends ChangeNotifier {
  bool? _onboardingComplete; // null = not loaded, true/false = loaded
  
  bool? get onboardingComplete => _onboardingComplete;
  
  Future<void> initialize() async {
    // Load all data WITHOUT notifying
    _activeSpaces = await _spaceManager.getActiveSpaces();
    _currentSpace = await _spaceManager.getCurrentSpace();
    _onboardingComplete = await _spaceManager.hasCompletedOnboarding();
    _isLoading = false;
    
    // Single notification after all data is loaded
    notifyListeners();
  }
}
```

### 2. _RecordsLoaderState (Modified)

**Changes:**
- Remove separate `FutureBuilder<bool>` for onboarding check
- Access `spaceProvider.onboardingComplete` synchronously after initialization
- Simplify widget tree to reduce rebuild overhead

**New Build Flow:**
```dart
Widget build(BuildContext context) {
  return FutureBuilder<RecordsService>(
    // ... existing code ...
    child: FutureBuilder<SpaceProvider>(
      future: _initializeSpaceProvider(),
      builder: (context, spaceSnapshot) {
        if (spaceSnapshot.connectionState != ConnectionState.done) {
          return LoadingScreen();
        }
        
        final spaceProvider = spaceSnapshot.data!;
        
        // Synchronous check - no additional FutureBuilder needed
        if (spaceProvider.onboardingComplete == false && !_onboardingCompleted) {
          return OnboardingScreen(...);
        }
        
        return FutureBuilder<void>(
          future: seedDebugRecordsIfEmpty(service.records),
          builder: (context, seedSnapshot) {
            // ... existing code ...
          },
        );
      },
    ),
  );
}
```

## Data Models

No changes to data models required. The Space entity and related value objects remain unchanged.

## Error Handling

### Initialization Errors

**Current:** Errors during initialization call `notifyListeners()` twice (once for loading, once for error)

**Proposed:** Single `notifyListeners()` call in the `finally` block, regardless of success or error

```dart
Future<void> initialize() async {
  final initOp = AppLogger.startOperation('initialize_space_provider');
  
  try {
    _activeSpaces = await _spaceManager.getActiveSpaces();
    _currentSpace = await _spaceManager.getCurrentSpace();
    _onboardingComplete = await _spaceManager.hasCompletedOnboarding();
    _error = null;
  } catch (e, stackTrace) {
    _error = 'Failed to load spaces: ${e.toString()}';
    _activeSpaces = [];
    _currentSpace = null;
    _onboardingComplete = false;
    
    await AppLogger.error(
      'SpaceProvider initialization failed',
      error: e,
      stackTrace: stackTrace,
    );
  } finally {
    _isLoading = false;
    await AppLogger.endOperation(initOp);
    notifyListeners(); // Single notification
  }
}
```

### Frame Drop Monitoring

Add logging to track frame drops during initialization:

```dart
// In app.dart, after SpaceProvider initialization
final binding = WidgetsBinding.instance;
final frameCount = binding.frameCounter; // If available
await AppLogger.info('SpaceProvider initialized', context: {
  'frames_since_start': frameCount,
});
```

## Testing Strategy

### Manual Testing

1. **Small Phone Emulator Test**
   - Launch app on Small_Phone emulator
   - Observe frame drops in console output
   - Verify "Skipped X frames" message shows < 5 frames
   - Confirm app doesn't crash or freeze

2. **Performance Profiling**
   - Use Flutter DevTools Timeline
   - Record app startup
   - Verify SpaceProvider.initialize() completes in < 500ms
   - Check for long-running operations on UI thread

3. **Onboarding Flow Test**
   - Clear app data
   - Launch app
   - Verify onboarding screen appears smoothly
   - Complete onboarding
   - Verify home screen loads without stuttering

### Automated Testing

1. **Unit Tests**
   - Test SpaceProvider.initialize() calls notifyListeners() exactly once
   - Test onboardingComplete getter returns correct value after initialization
   - Test error handling sets all fields correctly

2. **Integration Tests**
   - Test app startup flow from launch to onboarding screen
   - Test app startup flow from launch to home screen (onboarding complete)
   - Verify no exceptions during initialization

### Performance Benchmarks

**Success Criteria:**
- SpaceProvider initialization: < 500ms
- Frames skipped during initialization: < 5
- Time to first screen: < 2 seconds
- No crashes on Small_Phone emulator

## Implementation Notes

### Logging Requirements

Per `.kiro/steering/logging-guidelines.md`, ensure:
- Log operation start/end for `initialize_space_provider`
- Log performance metrics (duration, frames skipped)
- Log warnings if initialization takes > 500ms
- Include rich context in all log messages

### Clean Architecture Compliance

Per `AGENTS.md` and `CLEAN_ARCHITECTURE_GUIDE.md`:
- SpaceProvider remains in presentation layer
- SpaceManager remains in application layer
- No business logic in SpaceProvider
- All orchestration through SpaceManager

### Incremental Implementation

Per `AGENTS.md`:
1. First: Modify SpaceProvider.initialize() to batch notifications
2. Second: Add onboardingComplete field and getter
3. Third: Update _RecordsLoaderState to use synchronous check
4. Fourth: Test and verify frame drops are reduced
5. Fifth: Add performance logging

## Design Decisions

### Decision 1: Batch State Updates

**Rationale:** Multiple `notifyListeners()` calls during initialization cause multiple rebuilds of the widget tree. By loading all data first and calling `notifyListeners()` once, we reduce rebuilds from 2-3 to 1.

**Trade-off:** Users don't see a loading indicator during initialization, but the total time is the same and the experience is smoother.

### Decision 2: Cache Onboarding Status in SpaceProvider

**Rationale:** The current implementation requires a separate async call to check onboarding status, adding another FutureBuilder and potential rebuild. Caching it in SpaceProvider allows synchronous access.

**Trade-off:** Slightly increases SpaceProvider's responsibility, but keeps the data co-located with related space state.

### Decision 3: Remove Loading State Notification

**Rationale:** The loading state notification triggers a rebuild before data is ready, causing wasted work. Since initialization is fast (< 500ms), users won't notice the difference.

**Trade-off:** No intermediate loading UI, but the splash screen or initial loading indicator covers this period.

## References

- `.kiro/steering/logging-guidelines.md` - Logging requirements
- `AGENTS.md` - Development guidelines
- `CLEAN_ARCHITECTURE_GUIDE.md` - Architecture patterns
- `PERFORMANCE_OPTIMIZATION_SUMMARY.md` - Previous performance fixes
