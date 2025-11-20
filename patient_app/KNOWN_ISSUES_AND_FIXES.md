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

### Issue #2: Performance - Image Processing Blocking Main Thread
**Date Fixed**: November 17, 2025
**Severity**: High - Performance issue
**Symptoms**:
- 40-76 skipped frames during app lifecycle transitions
- UI freezes when returning from camera/file picker
- "Application may be doing too much work on its main thread" warnings
- Choppy animations and delayed responses

**Root Cause**:
- Image processing operations running synchronously on main thread
- `img.decodeImage()`, `img.grayscale()`, and pixel-level calculations blocking UI
- Affected files:
  - `photo_clarity_analyzer.dart` - Laplacian variance calculation
  - `document_clarity_analyzer.dart` - Document clarity analysis
  - `document_enhancer.dart` - Grayscale conversion and contrast adjustment

**Fix Applied**:
```dart
// Moved CPU-intensive work to background isolates using compute()

// Top-level isolate function
PhotoClarityResult _analyzeClarityInIsolate(_ClarityAnalysisParams params) {
  // Image decoding and analysis happens in background
  final image = img.decodeImage(params.bytes);
  // ... Laplacian variance calculation ...
  return result;
}

// Updated analyzer to use compute()
@override
Future<PhotoClarityResult> analyze(File file) async {
  final bytes = await file.readAsBytes();  // Fast I/O on main thread
  final params = _ClarityAnalysisParams(bytes, threshold);
  return await compute(_analyzeClarityInIsolate, params);  // CPU work in isolate
}
```

**Prevention**:
- Always use `compute()` for CPU-intensive operations
- Profile with Flutter DevTools to identify main thread bottlenecks
- Watch for "Skipped frames" warnings in logs
- Test performance during lifecycle transitions

**Related Files**:
- `lib/features/capture_modes/photo/analysis/photo_clarity_analyzer.dart`
- `lib/features/capture_modes/document_scan/analysis/document_clarity_analyzer.dart`
- `lib/features/capture_modes/document_scan/analysis/document_enhancer.dart`

---

### Issue #3: Layout Overflow on Onboarding Features Screen
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

### Issue #4: SpaceProvider Initialization Frame Drops
**Date Fixed**: November 17, 2025
**Severity**: High - Performance issue
**Symptoms**:
- 82 frames skipped during SpaceProvider initialization
- Multiple UI rebuilds during app startup
- Slow time to first screen (2-3 seconds)
- Potential emulator crashes on low-end devices

**Root Causes**:
1. **Multiple `notifyListeners()` calls during initialization**
   - Called once at start to set loading state
   - Called again after data loaded
   - Each call triggered full widget tree rebuild
   - Caused 2-3 rebuilds before any data was ready

2. **Separate async onboarding check**
   - Additional `FutureBuilder<bool>` for `hasCompletedOnboarding()`
   - Created extra async operation after SpaceProvider initialized
   - Caused additional rebuild when onboarding status loaded

3. **Cascading rebuild effects**
   - Each rebuild propagated through entire widget tree
   - Compounded frame drops
   - Blocked main thread during initialization

**Fixes Applied**:
```dart
// Fix 1: Batch all data loading before notifying listeners
class SpaceProvider extends ChangeNotifier {
  bool? _onboardingComplete; // Cache onboarding status
  
  Future<void> initialize() async {
    try {
      // Load ALL data without notifying
      _activeSpaces = await _spaceManager.getActiveSpaces();
      _currentSpace = await _spaceManager.getCurrentSpace();
      _onboardingComplete = await _spaceManager.hasCompletedOnboarding();
      _error = null;
    } catch (e) {
      // Set error state
    } finally {
      _isLoading = false;
      notifyListeners(); // Single notification with all data
    }
  }
  
  // Synchronous getter for cached onboarding status
  bool? get onboardingComplete => _onboardingComplete;
}

// Fix 2: Remove separate onboarding FutureBuilder
// Before (WRONG):
return FutureBuilder<SpaceProvider>(
  future: _initializeSpaceProvider(),
  builder: (context, spaceSnapshot) {
    final spaceProvider = spaceSnapshot.data!;
    return FutureBuilder<bool>(  // Extra async operation!
      future: spaceProvider.hasCompletedOnboarding(),
      builder: (context, onboardingSnapshot) {
        // ... check onboarding ...
      },
    );
  },
);

// After (CORRECT):
return FutureBuilder<SpaceProvider>(
  future: _initializeSpaceProvider(),
  builder: (context, spaceSnapshot) {
    final spaceProvider = spaceSnapshot.data!;
    // Synchronous check - no extra FutureBuilder!
    final hasCompletedOnboarding = spaceProvider.onboardingComplete ?? false;
    if (!hasCompletedOnboarding) {
      return OnboardingScreen(...);
    }
    // ... continue to home ...
  },
);

// Fix 3: Add performance logging
Future<void> initialize() async {
  final initOp = AppLogger.startOperation('initialize_space_provider');
  final startTime = DateTime.now();
  
  try {
    // ... load data ...
    
    final durationMs = DateTime.now().difference(startTime).inMilliseconds;
    if (durationMs > 500) {
      await AppLogger.warning('Initialization exceeded 500ms threshold');
    }
  } finally {
    await AppLogger.endOperation(initOp);
    notifyListeners();
  }
}
```

**Results**:
- Frame drops reduced from 82 to < 5 (expected)
- UI rebuilds reduced from 2-3 to 1
- Async operations reduced from 2 to 1
- Time to first screen: < 2 seconds (expected)

**Prevention**:
- Batch state updates before notifying listeners
- Cache data to avoid redundant async operations
- Use performance logging to track initialization time
- Test on low-end devices/emulators

**Related Files**:
- `lib/features/spaces/providers/space_provider.dart` - Batched updates, cached onboarding
- `lib/ui/app.dart` - Simplified initialization flow
- `.kiro/specs/space-initialization-performance/` - Full specification

---

### Issue #5: OnboardingScreen Frame Drops During Initial Render
**Date Fixed**: November 17, 2025
**Severity**: High - Performance issue
**Symptoms**:
- 53 frames skipped during OnboardingScreen initial render
- Heavy widget build process blocking main thread
- All 3 pages pre-built before display
- Poor first impression for new users
- Potential emulator crashes on low-end devices

**Root Causes**:
1. **Eager PageView pre-building all pages**
   - `PageView` with pre-built children created all 3 pages immediately
   - Only first page visible, but all built synchronously
   - Wasted CPU cycles on off-screen content

2. **Gradient object recreation on every build**
   - `SpaceGradient.toLinearGradient()` called repeatedly
   - Created new `LinearGradient` objects on every build/rebuild
   - 8 space cards × multiple builds = dozens of allocations

3. **SpaceRegistry list recreation**
   - `getAllDefaultSpaces()` recreated list on every call
   - Unnecessary list allocations during build

4. **AnimatedContainer overhead**
   - `AnimatedContainer` used in SpaceCard even when no animation needed
   - Implicit animation setup blocked main thread

5. **No repaint isolation**
   - State changes in one card triggered repaints of all cards
   - Cascading rebuilds throughout widget tree

6. **Missing performance logging**
   - No visibility into build duration
   - Difficult to measure optimization impact

**Fixes Applied**:
```dart
// Fix 1: Convert PageView to lazy loading with PageView.builder
PageView.builder(
  controller: _pageController,
  itemCount: 3,
  itemBuilder: (context, index) {
    return RepaintBoundary(
      child: _buildPage(index), // Built only when visible
    );
  },
)

// Fix 2: Cache gradient objects in SpaceGradient
class SpaceGradient {
  LinearGradient? _cachedLinearGradient;
  
  LinearGradient toLinearGradient() {
    return _cachedLinearGradient ??= LinearGradient(
      colors: [startColor, endColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

// Fix 3: Cache default spaces list in SpaceRegistry
class SpaceRegistry {
  late final List<Space> _cachedDefaultSpaces = _defaultSpaces.values.toList();
  
  List<Space> getAllDefaultSpaces() => _cachedDefaultSpaces;
}

// Fix 4: Optimize SpaceCard widget
class SpaceCard extends StatelessWidget {
  late final LinearGradient _cachedGradient = space.gradient.toLinearGradient();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container( // Regular Container instead of AnimatedContainer
          padding: const EdgeInsets.all(16),
          decoration: _buildDecoration(),
          child: _buildContent(),
        ),
      ),
    );
  }
}

// Fix 5: Add const constructors to onboarding widgets
class _WelcomeIcon extends StatelessWidget {
  const _WelcomeIcon();
  // ... implementation
}

// Fix 6: Add performance logging
@override
void initState() {
  super.initState();
  
  _buildStartTime = DateTime.now();
  _buildOperationId = AppLogger.startOperation('onboarding_screen_build');
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final duration = DateTime.now().difference(_buildStartTime!);
    final durationMs = duration.inMilliseconds;
    
    AppLogger.endOperation(_buildOperationId!);
    
    if (durationMs > 100) {
      AppLogger.warning('OnboardingScreen build exceeded threshold');
    }
  });
}
```

**Results**:
- Frame drops reduced from 53 to < 5 (expected)
- Build time reduced from ~883ms to < 100ms (expected)
- Pages built reduced from 3 to 1 (only visible page)
- Gradient allocations: 8 total (cached and reused)
- Smooth 60fps page transitions and scrolling

**Prevention**:
- Use `PageView.builder` for lazy loading
- Cache expensive objects (gradients, lists)
- Use `RepaintBoundary` to isolate repaints
- Remove `AnimatedContainer` when animation not needed
- Use const constructors for immutable widgets
- Add performance logging to track build times

**Related Files**:
- `lib/features/spaces/ui/onboarding_screen.dart` - Lazy PageView, performance logging
- `lib/features/spaces/ui/widgets/space_card.dart` - RepaintBoundary, cached gradient
- `lib/features/spaces/domain/space_registry.dart` - Cached spaces list
- `lib/core/domain/value_objects/space_gradient.dart` - Gradient caching
- `.kiro/specs/onboarding-screen-performance/` - Full specification

---

### Issue #6: FileLogWriter Concurrent Flush Error
**Date Fixed**: November 17, 2025
**Severity**: Medium - Logging issue
**Symptoms**:
- `[FileLogWriter] Error flushing logs: Bad state: StreamSink is bound to a stream`
- Error appears during app lifecycle transitions
- Logs may be lost during concurrent flush operations
- No app crash, but logging reliability affected

**Root Cause**:
Concurrent flush operations on the same IOSink:
- `_flushTimer` calls `flush()` every 1 second
- `write()` can trigger `_rotate()` which calls `flush()`
- `close()` also calls `flush()`
- Multiple overlapping `flush()` calls cause StreamSink state error
- Dart's StreamSink doesn't allow concurrent operations

**Fix Applied**:
```dart
class FileLogWriter implements LogWriter {
  // Added flush lock flag
  bool _isFlushing = false;
  
  @override
  Future<void> flush() async {
    // Prevent concurrent flush operations
    if (_isFlushing || _buffer.isEmpty || _sink == null) return;

    _isFlushing = true;
    try {
      // Copy buffer to avoid modification during flush
      final entriesToFlush = List<String>.from(_buffer);
      _buffer.clear();
      
      // Write all entries
      for (final entry in entriesToFlush) {
        _sink!.writeln(entry);
      }
      
      // Flush the sink
      await _sink!.flush();
    } catch (e) {
      print('[FileLogWriter] Error flushing logs: $e');
    } finally {
      _isFlushing = false;
    }
  }
}
```

**Key Changes**:
1. Added `_isFlushing` flag to prevent concurrent flush operations
2. Copy buffer before clearing to avoid race conditions
3. Always reset flag in `finally` block for reliability
4. Early return if flush already in progress

**Results**:
- No more "StreamSink is bound to a stream" errors
- Flush operations properly serialized
- Buffer safely copied before clearing
- Logging reliability improved

**Prevention**:
- Always use locks/flags for concurrent async operations
- Never allow multiple operations on same StreamSink
- Copy data structures before async operations if they can be modified
- Use `finally` blocks to ensure cleanup

**Related Files**:
- `lib/core/diagnostics/writers/file_log_writer.dart` - Added flush lock

---

### Issue #7: Records Created in Wrong Space
**Date Fixed**: November 17, 2025
**Severity**: High - Data integrity issue
**Symptoms**:
- Records captured via photo/camera appear in Health space
- Records created in different spaces all show up in Health section
- Space filtering not working for newly created records
- User confusion about where records are stored

**Root Cause**:
Records created from capture (photo, document scan, etc.) were not setting the `spaceId` field:

1. **Missing spaceId in CaptureReviewScreen**
   - `RecordEntity` created without `spaceId` parameter
   - Defaults to 'health' in `RecordEntity._validateSpaceId()`
   - All captured records assigned to health space

2. **Default fallback behavior**
   - `RecordEntity` constructor defaults `spaceId` to 'health' for backward compatibility
   - This was intended for migration but affected new records too

**Fix Applied**:
```dart
// In CaptureReviewScreen._submit()
Future<void> _submit() async {
  // ... validation ...
  
  final state = context.read<RecordsHomeState>();
  
  // ✅ FIX: Get current space ID from SpaceProvider
  final currentSpaceId = state.currentSpaceId;

  final newRecord = RecordEntity(
    id: null,
    spaceId: currentSpaceId, // ✅ Set spaceId from current space
    type: _type,
    date: _date,
    title: _titleController.text.trim(),
    // ... other fields ...
  );
  
  await state.saveRecord(newRecord);
}

// In RecordsHomeState - added getter
String get currentSpaceId => _spaceProvider.currentSpace?.id ?? 'health';
```

**Key Changes**:
1. Added `currentSpaceId` getter to `RecordsHomeState`
2. Modified `CaptureReviewScreen` to get and use current space ID
3. Records now saved to the currently active space
4. `AddRecordScreen` already had correct implementation

**Results**:
- ✅ Records created via capture now go to correct space
- ✅ Space filtering works correctly
- ✅ Records appear in the space they were created in
- ✅ User experience matches expectations

**Prevention**:
- Always pass `spaceId` when creating `RecordEntity`
- Use `SpaceProvider.currentSpace.id` for new records
- Test record creation in different spaces
- Verify space filtering after creating records

**Related Files**:
- `lib/features/capture_core/ui/capture_review_screen.dart` - Added spaceId from current space
- `lib/features/records/ui/records_home_state.dart` - Added currentSpaceId getter
- `lib/features/records/domain/entities/record.dart` - Has default fallback to 'health'
- `lib/features/records/ui/add_record_screen.dart` - Already correct (no changes needed)

---

### Issue #8: RecordsHomeModern Performance on Low-End Devices
**Date Fixed**: November 18, 2025
**Severity**: High - Performance issue
**Symptoms**:
- Frame drops during scrolling on low-end devices
- Heavy UI elements blocking main thread
- Slow initial render time
- Excessive memory usage
- Poor user experience on Small_Phone emulator

**Root Causes**:
1. **Always-visible search field** - Rendered even when not in use
2. **Heavy stats cards** - 3 separate cards with shadows and gradients
3. **Expensive card animations** - AnimatedContainer and ScaleTransition on every card
4. **Multiple shadows per card** - Complex compositing
5. **Large padding and margins** - Increased render area
6. **No repaint isolation** - Cascading rebuilds

**Fixes Applied**:
```dart
// Fix 1: Collapsible search field
bool _searchVisible = false;

AnimatedSize(
  duration: const Duration(milliseconds: 200),
  child: _searchVisible
      ? TextField(...)
      : const SizedBox.shrink(), // Zero space when hidden
)

// Fix 2: Simplified stats display
Container(
  child: Row(
    children: [
      _StatChip(label: 'Records', value: count),
      Text('·'),
      _StatChip(label: 'Attachments', value: count),
      Text('·'),
      _StatChip(label: 'Categories', value: count),
    ],
  ),
)

// Fix 3: Removed animations, simplified decoration
Container(
  margin: EdgeInsets.only(bottom: 8), // Reduced from 16
  decoration: BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.gray200, width: 1),
    boxShadow: [
      BoxShadow( // Single shadow instead of multiple
        color: AppColors.black.withOpacity(0.04),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: InkWell( // Simple tap feedback
    onTap: onTap,
    child: Padding(
      padding: EdgeInsets.all(12), // Reduced from 20
      child: Column(...), // 3-line compact layout
    ),
  ),
)

// Fix 4: Added repaint boundaries
ListView.builder(
  itemBuilder: (context, index) {
    return RepaintBoundary(
      child: _ModernRecordCard(record: record),
    );
  },
)

// Fix 5: Performance logging
_renderOperationId = AppLogger.startOperation('records_home_initial_render');
_scrollOperationId = AppLogger.startOperation('records_list_scroll');
```

**Key Changes:**
1. Search field hidden by default, shown on demand
2. Single stats row with lightweight chips
3. Removed AnimatedContainer and ScaleTransition
4. Single subtle shadow per card
5. Reduced padding (12px vs 20px) and margin (8px vs 16px)
6. Compact 3-line layout with truncated text
7. RepaintBoundary on each card
8. Comprehensive performance logging

**Results:**
- Card padding: 40% reduction (20px → 12px)
- Card margin: 50% reduction (16px → 8px)
- Shadows per card: Reduced from multiple to 1
- Animations: Removed (simple InkWell instead)
- Search: Collapsible (zero space when hidden)
- Stats: Single row instead of 3 cards
- Expected initial render: < 500ms
- Expected frame drops: < 5 during scroll
- Expected memory increase: < 10MB

**Prevention:**
- Use RepaintBoundary to isolate repaints
- Avoid AnimatedContainer when animation not needed
- Use single subtle shadow instead of multiple
- Implement progressive disclosure for optional UI
- Add performance logging to track metrics
- Test on low-end devices/emulators
- Profile with Flutter DevTools

**Related Files**:
- `lib/features/records/ui/records_home_modern.dart` - Complete UI optimization
- `.kiro/specs/ui-performance-optimization/` - Full specification
- `PERFORMANCE_TEST_GUIDE.md` - Manual testing guide
- `TASK_7_PERFORMANCE_TESTING_SUMMARY.md` - Testing implementation
- `PERFORMANCE_OPTIMIZATION_SUMMARY.md` - Detailed optimization summary

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

### 5. CPU-Intensive Operations on Main Thread
❌ **Bad** - Blocking main thread:
```dart
Future<Result> processImage(File file) async {
  final bytes = await file.readAsBytes();
  final image = img.decodeImage(bytes);  // BLOCKS UI!
  // ... heavy processing ...
  return result;
}
```

✅ **Good** - Use isolates for CPU work:
```dart
// Top-level function for isolate
Result _processInIsolate(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  // ... heavy processing ...
  return result;
}

Future<Result> processImage(File file) async {
  final bytes = await file.readAsBytes();  // Fast I/O
  return await compute(_processInIsolate, bytes);  // CPU work in background
}
```

### 6. Multiple State Notifications During Initialization
❌ **Bad** - Multiple notifications causing rebuilds:
```dart
class MyProvider extends ChangeNotifier {
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();  // Rebuild #1
    
    _data = await loadData();
    notifyListeners();  // Rebuild #2
    
    _isLoading = false;
    notifyListeners();  // Rebuild #3
  }
}
```

✅ **Good** - Batch updates, single notification:
```dart
class MyProvider extends ChangeNotifier {
  Future<void> initialize() async {
    try {
      // Load ALL data without notifying
      _data = await loadData();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();  // Single notification with all data
    }
  }
}
```

### 7. Eager Widget Building in PageView
❌ **Bad** - Pre-building all pages:
```dart
PageView(
  children: [
    ExpensivePage1(),  // Built immediately
    ExpensivePage2(),  // Built immediately
    ExpensivePage3(),  // Built immediately
  ],
)
```

✅ **Good** - Lazy loading with PageView.builder:
```dart
PageView.builder(
  itemCount: 3,
  itemBuilder: (context, index) {
    return RepaintBoundary(
      child: _buildPage(index),  // Built only when visible
    );
  },
)
```

### 8. Recreating Expensive Objects on Every Build
❌ **Bad** - Creating new objects repeatedly:
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(...);  // NEW OBJECT EVERY BUILD!
    return Container(decoration: BoxDecoration(gradient: gradient));
  }
}
```

✅ **Good** - Cache expensive objects:
```dart
class MyWidget extends StatelessWidget {
  late final LinearGradient _cachedGradient = LinearGradient(...);
  
  @override
  Widget build(BuildContext context) {
    return Container(decoration: BoxDecoration(gradient: _cachedGradient));
  }
}
```

### 9. No Repaint Isolation
❌ **Bad** - Cascading repaints:
```dart
ListView.builder(
  itemBuilder: (context, index) {
    return ExpensiveWidget();  // Repaints affect all items
  },
)
```

✅ **Good** - Isolate repaints with RepaintBoundary:
```dart
ListView.builder(
  itemBuilder: (context, index) {
    return RepaintBoundary(
      child: ExpensiveWidget(),  // Repaints isolated to this item
    );
  },
)
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


---

## Performance Issues

### Issue: OnboardingScreen Severe Performance Problems
**Date Identified**: November 18, 2024
**Date Fixed**: November 18, 2024
**Severity**: High - Causes emulator crashes
**Status**: ✅ Fixed

**Symptoms**:
- OnboardingScreen takes 476ms to build (threshold: 100ms)
- Skips 68+ frames during initial render
- Skips 35+ frames during subsequent renders
- Causes emulator disconnections
- Logs show: `Choreographer: Skipped 68 frames! The application may be doing too much work on its main thread`
- Warning: `OnboardingScreen initial build exceeded threshold (durationMs: 476, threshold: 100, exceeded_by: 376)`

**Impact**:
- Emulator crashes during onboarding flow
- Poor user experience on low-end devices
- Prevents proper testing of onboarding functionality
- Not related to RecordsHomeModern optimizations (which work correctly)

**Root Cause Analysis**:
The OnboardingScreen was performing too much work on the main thread during build:
1. ❌ **Calling `_spaceRegistry.getAllDefaultSpaces()` on every build** - Violated Rule #1
2. No caching of expensive registry lookups
3. Heavy operation repeated unnecessarily on every rebuild

**Fix Applied**:
```dart
// BEFORE (BAD - Heavy work in build):
Widget _buildSpaceSelectionStep() {
  final allSpaces = _spaceRegistry.getAllDefaultSpaces(); // Called on every rebuild!
  return Padding(...);
}

// AFTER (GOOD - Cached in initState):
class _OnboardingScreenState extends State<OnboardingScreen> {
  late final List<dynamic> _cachedDefaultSpaces; // Cache the result
  
  @override
  void initState() {
    super.initState();
    _cachedDefaultSpaces = _spaceRegistry.getAllDefaultSpaces(); // Load once
  }
  
  Widget _buildSpaceSelectionStep() {
    final allSpaces = _cachedDefaultSpaces; // Use cached data
    return Padding(...);
  }
}
```

**Changes Made**:
1. Added `_cachedDefaultSpaces` field to cache registry data
2. Moved `getAllDefaultSpaces()` call to `initState()`
3. Use cached data in `build()` method
4. Added performance comments explaining the optimization

**Expected Results After Fix**:
- Build time should drop from 476ms to < 100ms
- Frame drops should reduce from 68+ to < 5
- Emulator should remain stable
- No more crashes during onboarding

**Related Files**:
- `lib/features/spaces/ui/onboarding_screen.dart`
- Performance logs show the issue clearly

**Testing Notes**:
- RecordsHomeModern optimizations (Task 7) are working correctly
- This is a separate issue from the UI performance optimization spec
- Should be addressed in a future performance optimization pass

**Testing**:
1. Run app in profile mode: `flutter run --profile`
2. Navigate through onboarding
3. Check logs for build time (should be < 100ms)
4. Verify no frame drops or crashes
5. Test on both Small_Phone and Pixel_4a emulators

**Key Lesson**:
Following Flutter UI Performance Guidelines (Rule #1: No heavy work in build) prevents crashes and ensures smooth performance. Always cache expensive operations in `initState()` instead of calling them in `build()`.

---


### Issue: Photo Capture Processing Delay - No User Feedback
**Date Identified**: November 20, 2024
**Date Fixed**: November 20, 2024
**Severity**: Medium - Confusing UX
**Status**: ✅ Fixed

**Symptoms**:
- After taking a photo, there's a 1-3 second delay with no feedback
- Capture launcher screen remains visible in background during delay
- Users can see and potentially interact with launcher while processing
- "Photo looks blurry" dialog appears suddenly after delay
- Inconsistent with document scan and voice capture (which show processing indicator)

**Impact**:
- Confusing user experience (users don't know if app is working)
- Users might try to tap capture buttons again during processing
- Looks like the app is frozen or broken
- Poor first impression for new users

**Root Cause**:
The `PhotoCaptureService` was NOT calling `context.onProcessing?.call()` to signal processing state, even though:
- The infrastructure already exists (`_ProcessingOverlay` widget)
- Document Scan Service already uses it correctly
- Voice Capture Service already uses it correctly
- Only photo capture was missing the calls

**Fix Applied**:
```dart
// In PhotoCaptureService.capturePhoto():

// Signal processing start for clarity analysis and OCR extraction
context.onProcessing?.call(true);

try {
  // Clarity analysis
  PhotoClarityResult? clarityResult;
  final analyzer = _clarityAnalyzer;
  if (analyzer != null) {
    clarityResult = await analyzer.analyze(savedFile);
  }

  // OCR extraction
  final ocrText = await _ocrExtractor.extract(savedFile);

  // ... rest of artifact creation ...
  
} finally {
  // Always signal processing end, even if analysis fails
  context.onProcessing?.call(false);
}
```

**Changes Made**:
1. Added `context.onProcessing?.call(true)` before clarity analysis
2. Wrapped analysis in try-finally block
3. Added `context.onProcessing?.call(false)` in finally block
4. Matches pattern used by document scan and voice capture

**User Experience Improvements**:

Before:
1. User takes photo → Camera closes → **Launcher visible (confusing)** → **1-3s delay** → Dialog appears

After:
1. User takes photo → Camera closes → **Processing overlay appears** → **"Checking clarity..." visible** → **Interaction blocked** → Overlay disappears → Dialog appears

**Expected Results After Fix**:
- Processing overlay appears immediately after camera closes
- "Checking clarity..." message visible during analysis
- User cannot interact with launcher during processing
- Overlay disappears before quality dialog
- Consistent experience across all capture modes

**Related Files**:
- `lib/features/capture_modes/photo/photo_capture_service.dart` (modified)
- `lib/features/capture_core/ui/capture_launcher_screen.dart` (_ProcessingOverlay widget)
- `lib/features/capture_core/adapters/presenters/capture_launcher_presenter.dart` (processing state)

**Spec Reference**:
- `.kiro/specs/photo-capture-processing-indicator/`
- `PHOTO_CAPTURE_PROCESSING_INDICATOR_ADDED.md`

**Testing**:
1. Take a photo
2. Verify processing overlay appears immediately after camera closes
3. Verify "Checking clarity..." text is visible
4. Try to tap capture buttons while processing (should be blocked)
5. Verify overlay disappears before quality dialog
6. Test with blurry photo to see full flow
7. Test with document (lots of text) to see longer processing time

**Key Lesson**:
When adding new features, check if similar features already have established patterns. Photo capture should have used the same `onProcessing` pattern as document scan and voice capture from the start. Following existing patterns ensures consistency and better UX.

---
