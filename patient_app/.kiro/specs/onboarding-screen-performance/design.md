# Design Document

## Overview

This design addresses two critical issues in the OnboardingScreen:

1. **Performance Issue**: 53 frames skipped during initial render
2. **Crash Issue**: App crashes when scrolling the space list on page 2

The solution focuses on:
- Lazy-loading widgets and optimizing builds to reduce frame drops
- Fixing nested scrolling conflicts between PageView and ListView to prevent crashes
- Using proper scroll physics and gesture handling to ensure stability
- Caching expensive objects and isolating repaints for smooth performance

The key insight: ManageSpacesScreen uses the same ListView and SpaceCard widgets but never crashes because it doesn't have PageView nesting. The crash is caused by gesture conflicts in the nested scrolling architecture, not by the widgets themselves.

## Architecture

### Current Flow (Problematic)

```
OnboardingScreen builds
  ↓
PageView creates all 3 pages immediately
  ├─ Page 1: Welcome (complex decorations)
  ├─ Page 2: Space Selection (8 SpaceCards + Create button)
  │   ├─ SpaceCard 1 (gradient calculation, AnimatedContainer)
  │   ├─ SpaceCard 2 (gradient calculation, AnimatedContainer)
  │   ├─ ... (6 more cards)
  │   └─ Create button (complex decorations)
  └─ Page 3: Features Overview (complex decorations)
  ↓
All widgets built synchronously
  ↓
[53 FRAMES SKIPPED - Main thread blocked for ~883ms]
```

### Proposed Flow (Optimized)

```
OnboardingScreen builds
  ↓
PageView with lazy loading (only current page)
  ↓
Page 1: Welcome builds
  ├─ Use const constructors
  ├─ Defer heavy decorations with addPostFrameCallback
  └─ RepaintBoundary around complex widgets
  ↓
[SMOOTH RENDERING - < 5 FRAMES SKIPPED]
  ↓
User swipes to Page 2
  ↓
Page 2: Space Selection builds on-demand
  ├─ Cached gradient objects
  ├─ RepaintBoundary around each SpaceCard
  ├─ Regular Container instead of AnimatedContainer on first build
  └─ Const constructors where possible
  ↓
[SMOOTH SCROLLING - 60fps maintained]
```

## Components and Interfaces

### 1. OnboardingScreen (Modified)

**Changes:**
- Add performance logging for initial build
- Use `PageView.builder` instead of `PageView` with pre-built children
- Implement lazy page building
- Add `RepaintBoundary` around each page
- Use `addPostFrameCallback` to defer non-critical decorations

**New Interface:**
```dart
class _OnboardingScreenState extends State<OnboardingScreen> {
  String? _buildOperationId;
  
  @override
  void initState() {
    super.initState();
    _buildOperationId = AppLogger.startOperation('onboarding_screen_build');
    
    // Defer completion logging until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_buildOperationId != null) {
        AppLogger.endOperation(_buildOperationId!);
        _buildOperationId = null;
      }
    });
    
    AppLogger.info('OnboardingScreen initialized');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: 3,
                itemBuilder: (context, index) {
                  // Lazy build pages
                  return RepaintBoundary(
                    child: _buildPage(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildSpaceSelectionStep();
      case 2:
        return _buildFeaturesOverviewStep();
      default:
        return const SizedBox.shrink();
    }
  }
}
```

### 2. SpaceCard (Modified)

**Changes:**
- Cache gradient objects to avoid recreating on every build
- Use `RepaintBoundary` to isolate repaints
- Replace `AnimatedContainer` with regular `Container` (animation not needed on first render)
- Use `const` constructors where possible
- Optimize decoration building

**New Interface:**
```dart
class SpaceCard extends StatelessWidget {
  final Space space;
  final bool isSelected;
  final bool isCurrent;
  final VoidCallback onTap;
  
  // Cache gradient to avoid recreating
  late final LinearGradient _cachedGradient = space.gradient.toLinearGradient();

  const SpaceCard({
    Key? key,
    required this.space,
    required this.isSelected,
    required this.isCurrent,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _buildDecoration(),
          child: _buildContent(),
        ),
      ),
    );
  }
  
  BoxDecoration _buildDecoration() {
    return BoxDecoration(
      gradient: isSelected ? _cachedGradient : null,
      color: isSelected ? null : AppColors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isSelected ? Colors.transparent : AppColors.gray300,
        width: 2,
      ),
      boxShadow: isSelected ? [
        BoxShadow(
          color: space.gradient.startColor.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ] : null,
    );
  }
}
```

### 3. SpaceRegistry (Modified)

**Changes:**
- Pre-cache gradient objects for all default spaces
- Make gradient objects immutable and reusable
- Ensure `getAllDefaultSpaces()` returns cached list

**New Interface:**
```dart
class SpaceRegistry {
  // Cache the list to avoid recreating on every call
  late final List<Space> _cachedDefaultSpaces = _defaultSpaces.values.toList();
  
  /// Gets all default spaces as a cached list
  List<Space> getAllDefaultSpaces() => _cachedDefaultSpaces;
}
```

### 4. Space Entity (Modified)

**Changes:**
- Cache the LinearGradient conversion result
- Make gradient conversion lazy and memoized

**New Interface:**
```dart
class SpaceGradient {
  final Color startColor;
  final Color endColor;
  
  // Cached gradient object
  LinearGradient? _cachedLinearGradient;
  
  const SpaceGradient({
    required this.startColor,
    required this.endColor,
  });
  
  /// Returns cached LinearGradient or creates and caches it
  LinearGradient toLinearGradient() {
    return _cachedLinearGradient ??= LinearGradient(
      colors: [startColor, endColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
```

## Data Models

### SpaceGradient Enhancement

Add caching to the `SpaceGradient` value object:

```dart
class SpaceGradient {
  final Color startColor;
  final Color endColor;
  LinearGradient? _cachedLinearGradient;
  
  const SpaceGradient({
    required this.startColor,
    required this.endColor,
  });
  
  LinearGradient toLinearGradient() {
    return _cachedLinearGradient ??= LinearGradient(
      colors: [startColor, endColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
```

## Error Handling

### Build Errors

**Current:** Errors during SpaceCard build show fallback UI but don't log performance impact

**Proposed:** Log performance metrics even when errors occur

```dart
@override
Widget build(BuildContext context) {
  try {
    return RepaintBoundary(
      child: _buildCardContent(),
    );
  } catch (e, stackTrace) {
    await AppLogger.error(
      'Error building SpaceCard',
      error: e,
      stackTrace: stackTrace,
      context: {'spaceId': space.id},
    );
    return _buildFallbackCard();
  }
}
```

### Performance Monitoring

Add frame drop detection:

```dart
@override
void initState() {
  super.initState();
  
  final startTime = DateTime.now();
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final duration = DateTime.now().difference(startTime);
    
    if (duration.inMilliseconds > 100) {
      AppLogger.warning(
        'OnboardingScreen build exceeded threshold',
        context: {
          'durationMs': duration.inMilliseconds,
          'threshold': 100,
        },
      );
    }
  });
}
```

## Testing Strategy

### Manual Testing

1. **Frame Drop Test**
   - Clear app data
   - Launch app on Small_Phone emulator
   - Observe console for "Skipped X frames" during OnboardingScreen load
   - Verify < 5 frames skipped
   - Confirm smooth rendering

2. **Page Transition Test**
   - Swipe between onboarding pages
   - Verify smooth 60fps transitions
   - Check that pages build on-demand (log verification)

3. **Space Selection Scrolling Test**
   - Navigate to space selection page
   - Scroll through space list
   - Verify smooth 60fps scrolling
   - Tap spaces to select/deselect
   - Verify no frame drops during state changes

4. **Low-End Device Test**
   - Test on Small_Phone emulator with limited resources
   - Verify no crashes or freezes
   - Confirm acceptable performance

### Performance Benchmarks

**Success Criteria:**
- OnboardingScreen initial build: < 100ms
- Frames skipped during initial render: < 5
- Page transition frame rate: 60fps (no drops)
- Space list scrolling frame rate: 60fps
- SpaceCard render time: < 16ms per card

### Automated Testing

1. **Unit Tests**
   - Test SpaceGradient caching works correctly
   - Test SpaceRegistry returns cached list
   - Test lazy page building in PageView.builder

2. **Widget Tests**
   - Test OnboardingScreen renders without errors
   - Test page transitions work correctly
   - Test space selection state updates correctly

3. **Performance Tests**
   - Measure OnboardingScreen build time
   - Verify gradient objects are reused (reference equality)
   - Confirm RepaintBoundary reduces rebuild scope

## Implementation Notes

### Logging Requirements

Per `.kiro/steering/logging-guidelines.md`, ensure:
- Log operation start/end for `onboarding_screen_build`
- Log performance metrics (duration, frames skipped)
- Log warnings if build takes > 100ms
- Include rich context in all log messages
- Use `addPostFrameCallback` to avoid logging during build

### Clean Architecture Compliance

Per `AGENTS.md` and `CLEAN_ARCHITECTURE_GUIDE.md`:
- OnboardingScreen remains in presentation layer
- SpaceRegistry remains in domain layer
- No business logic in UI widgets
- Value objects (SpaceGradient) can cache derived data

### Incremental Implementation

Per `AGENTS.md`:
1. First: Add performance logging to OnboardingScreen
2. Second: Convert PageView to PageView.builder with lazy loading
3. Third: Add RepaintBoundary widgets
4. Fourth: Cache gradient objects in SpaceGradient
5. Fifth: Optimize SpaceCard (remove AnimatedContainer, add const)
6. Sixth: Test and verify frame drops are reduced

## Nested Scrolling Crash Prevention

### Problem Analysis

**Current Architecture (Crashes):**
```
PageView (horizontal scroll)
  └─ Page 2: Space Selection
      └─ Column
          └─ Expanded
              └─ ListView (vertical scroll)  ⚠️ NESTED SCROLLING CONFLICT
                  └─ SpaceCard widgets
```

**Why It Crashes:**
1. User scrolls down the ListView (vertical gesture)
2. Gesture detector must decide: ListView scroll or PageView swipe?
3. During page transitions, both widgets try to handle gestures
4. Gesture conflict causes crash, especially on low-end devices/emulators

**Why ManageSpacesScreen Doesn't Crash:**
```
Scaffold
  └─ Column
      └─ Expanded
          └─ ListView (vertical scroll)  ✅ NO NESTING
              └─ SpaceCard widgets (same widgets!)
```

No PageView = No nesting = No gesture conflicts = No crashes

### Solution: Proper Scroll Physics Configuration

**Option 1: Disable PageView Scrolling on Page 2 (Recommended)**

When user is on page 2 (space selection), temporarily disable PageView horizontal scrolling:

```dart
PageView.builder(
  controller: _pageController,
  physics: _currentPage == 1 
      ? const NeverScrollableScrollPhysics()  // Disable on page 2
      : const PageScrollPhysics(),             // Enable on other pages
  onPageChanged: _onPageChanged,
  itemCount: 3,
  itemBuilder: (context, index) {
    return RepaintBoundary(
      child: _buildPage(index),
    );
  },
)
```

**Benefits:**
- Eliminates gesture conflicts completely on page 2
- User can scroll the list freely without crashes
- Still allows page navigation via buttons
- Simple implementation

**Trade-off:**
- User cannot swipe horizontally while on page 2
- Must use "Continue" or "Skip" buttons to navigate
- This is acceptable since users need to interact with the list anyway

**Option 2: Use ClampingScrollPhysics for ListView**

Configure ListView to use clamping physics that prevents over-scroll:

```dart
ListView.separated(
  physics: const ClampingScrollPhysics(),  // Prevents bounce/over-scroll
  itemCount: allSpaces.length + 1,
  // ...
)
```

**Benefits:**
- Reduces gesture ambiguity at list boundaries
- Prevents over-scroll that can trigger PageView gestures

**Trade-off:**
- Doesn't fully eliminate conflicts
- Should be used in combination with Option 1

**Option 3: Increase PageView Drag Start Distance**

Make PageView less sensitive to horizontal gestures:

```dart
PageView.builder(
  controller: _pageController,
  dragStartBehavior: DragStartBehavior.down,
  // ...
)
```

**Benefits:**
- Gives ListView priority for gesture handling

**Trade-off:**
- Makes page swiping feel less responsive
- Not recommended as primary solution

### Recommended Implementation

**Combine Option 1 + Option 2:**

1. Disable PageView scrolling when on page 2
2. Use ClampingScrollPhysics for ListView
3. Provide clear "Continue" and "Skip" buttons for navigation

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              // CRASH FIX: Disable PageView scrolling on page 2
              physics: _currentPage == 1 
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              onPageChanged: _onPageChanged,
              itemCount: 3,
              itemBuilder: (context, index) {
                return RepaintBoundary(
                  child: _buildPage(index),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSpaceSelectionStep() {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        // ... title, description, counter ...
        
        Expanded(
          child: ListView.separated(
            // CRASH FIX: Use clamping physics to prevent over-scroll
            physics: const ClampingScrollPhysics(),
            itemCount: allSpaces.length + 1,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              // ... space cards ...
            },
          ),
        ),
        
        // ... buttons ...
      ],
    ),
  );
}
```

## Design Decisions

### Decision 1: Use PageView.builder Instead of PageView

**Rationale:** `PageView.builder` only builds pages when they're about to be displayed, reducing initial build time. Since users typically view pages sequentially, pre-building all pages wastes resources.

**Trade-off:** Slight delay when swiping to a new page for the first time, but this is negligible compared to the initial load improvement.

### Decision 2: Cache Gradient Objects

**Rationale:** Creating `LinearGradient` objects is expensive. Since gradients are immutable, caching them eliminates redundant allocations and improves performance.

**Trade-off:** Slightly increased memory usage (negligible - 8 gradient objects), but significant performance gain.

### Decision 3: Replace AnimatedContainer with Container

**Rationale:** `AnimatedContainer` adds overhead for implicit animations that aren't needed on first render. Users don't see animations during initial load.

**Trade-off:** No animation on first render, but this is acceptable since the card hasn't been displayed before.

### Decision 4: Add RepaintBoundary Around SpaceCards

**Rationale:** `RepaintBoundary` creates a separate layer, preventing repaints of one card from triggering repaints of other cards. This is especially important during scrolling.

**Trade-off:** Slightly increased memory usage for additional layers, but significant performance improvement during scrolling and state changes.

### Decision 5: Use addPostFrameCallback for Performance Logging

**Rationale:** Logging during the build phase can interfere with frame timing measurements. Using `addPostFrameCallback` ensures accurate performance metrics.

**Trade-off:** Logging happens after the first frame, but this provides more accurate measurements.

### Decision 6: Disable PageView Scrolling on Page 2

**Rationale:** The crash is caused by nested scrolling conflicts between PageView (horizontal) and ListView (vertical). Disabling PageView scrolling when on page 2 eliminates gesture conflicts completely. Users can still navigate via "Continue" and "Skip" buttons.

**Trade-off:** Users cannot swipe horizontally while on page 2, but this is acceptable since:
- Users need to interact with the list anyway (selecting spaces)
- Clear navigation buttons are provided
- Prevents crashes and provides stable experience
- ManageSpacesScreen proves the same widgets work fine without PageView

**Alternative Considered:** Using gesture detectors to disambiguate gestures, but this adds complexity and doesn't fully eliminate conflicts.

### Decision 7: Use ClampingScrollPhysics for ListView

**Rationale:** ClampingScrollPhysics prevents over-scroll bounce at list boundaries, reducing gesture ambiguity that can trigger PageView gestures.

**Trade-off:** No bounce effect at list edges, but this is a minor UX change for significant stability improvement.

## Performance Impact Estimation

### Expected Improvements

Based on the identified issues:

1. **Lazy PageView loading**: Save ~300ms (avoid building 2 unused pages)
2. **Cached gradients**: Save ~50ms (8 gradient creations × ~6ms each)
3. **RepaintBoundary**: Reduce rebuild scope by ~70%
4. **Remove AnimatedContainer**: Save ~80ms (8 cards × ~10ms each)
5. **Const constructors**: Save ~20ms (reduced allocations)

**Total estimated savings: ~450ms**

**Expected result:**
- Current: 53 frames skipped (~883ms blocked)
- After optimization: < 5 frames skipped (~83ms blocked)
- **Improvement: ~90% reduction in frame drops**

## References

- `.kiro/steering/logging-guidelines.md` - Logging requirements
- `AGENTS.md` - Development guidelines
- `CLEAN_ARCHITECTURE_GUIDE.md` - Architecture patterns
- `.kiro/specs/space-initialization-performance/` - Related performance optimization
- Flutter Performance Best Practices: https://docs.flutter.dev/perf/best-practices
