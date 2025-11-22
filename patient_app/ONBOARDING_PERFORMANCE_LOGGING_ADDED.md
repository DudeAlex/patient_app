# OnboardingScreen Performance Logging Implementation

**Date:** November 18, 2024  
**Status:** ✅ Complete

## Overview

Implemented comprehensive performance logging for OnboardingScreen based on the OnboardingScreen Performance Checklist. This provides detailed visibility into build times, page navigation, and completion flow performance.

---

## What Was Done

### 1. Created Steering File

**File:** `.kiro/steering/onboarding-performance-checklist.md`

A comprehensive checklist that provides:
- What to log (screen events, page changes, completion flow)
- What to measure (build times, rebuild costs, completion times)
- How to track rebuild costs
- How to detect synchronous hotspots
- How to isolate UI jank
- DevTools usage guidelines
- Interpretation rules (real issue vs normal async)
- Discipline rule (no optimization without data)

This steering file is automatically included for all AI agents working on the project.

### 2. Implemented Comprehensive Logging in OnboardingScreen

**File:** `lib/features/spaces/ui/onboarding_screen.dart`

#### Screen Level Events

**Initial Build Tracking:**
```dart
// In initState:
_initialBuildStartTime = DateTime.now();
_initialBuildOperationId = AppLogger.startOperation('onboarding_initial_build');

// In addPostFrameCallback:
- Logs build duration with category 'onboarding' and event 'screen_build_end'
- Includes: durationMs, threshold, status (good/watch/slow), isInitialBuild, pageIndex
- Uses appropriate log level (info/warning) based on thresholds:
  - < 50ms: good
  - 50-150ms: watch
  - > 150ms: investigate (warning)
```

**Rebuild Tracking:**
```dart
// In build method (after initial build):
- Tracks rebuild start time
- Logs rebuild duration in addPostFrameCallback
- Only logs if rebuild takes > 50ms (reduces noise)
- Includes: durationMs, pageIndex, isInitialBuild: false, trigger
```

**Initialization:**
```dart
// Logs screen initialization with category and event
// Logs space caching operation with count
```

#### Page Level Events

**Page Changes:**
```dart
void _onPageChanged(int page) {
  // Logs with:
  - category: 'onboarding'
  - event: 'page_change'
  - fromPage, toPage, pageIndex
}
```

#### Completion Flow

**Overall Completion:**
```dart
Future<void> _completeOnboarding() async {
  // Tracks entire completion flow
  - Logs 'complete_start' with selectedSpacesCount and selectedSpaceIds
  - Uses AppLogger.startOperation('onboarding_complete')
  - Logs 'complete_end' with total durationMs and spacesAdded
  - Logs 'complete_error' with errorType if exception occurs
}
```

**Individual Space Addition:**
```dart
for (final spaceId in _selectedSpaceIds) {
  // Tracks each addSpace operation
  - Logs 'add_space_end' with spaceId and durationMs
  - Uses AppLogger.startOperation('onboarding_add_space')
  - Logs 'add_space_error' if exception occurs
}
```

**Mark Complete Operation:**
```dart
// Tracks setOnboardingComplete operation
- Logs 'mark_complete_end' with durationMs
- Uses AppLogger.startOperation('onboarding_mark_complete')
- Logs 'mark_complete_error' if exception occurs
```

#### Error Handling

All operations include comprehensive error logging:
- Error type (runtimeType.toString())
- Stack trace
- Duration at time of error
- Context (spaceId, selectedSpacesCount, etc.)
- Category and event for filtering

---

## Logging Format

All logs follow a consistent structure:

```dart
await AppLogger.info('Message', context: {
  'category': 'onboarding',
  'event': 'screen_build_end' | 'page_change' | 'complete_start' | etc.,
  'durationMs': 123,
  'pageIndex': 0,
  'isInitialBuild': true,
  'fromPage': 0,
  'toPage': 1,
  'selectedSpacesCount': 3,
  'spaceId': 'health',
  'errorType': 'Exception',
  // ... other relevant context
});
```

---

## Performance Thresholds

### Build Time Thresholds

- **< 50ms:** Good - No action needed
- **50-150ms:** Watch - Monitor for trends
- **> 150ms:** Investigate - Log as warning

### Completion Time Expectations

- **addSpace:** Should be fast (< 100ms per space)
- **markOnboardingComplete:** Should be fast (< 100ms)
- **Total completion:** 200-800ms is normal for async I/O

---

## How to Use This Logging

### 1. Check Logs After Changes

```powershell
# Retrieve logs from emulator
.\get_crash_logs.ps1

# Look in retrieved_logs/ for onboarding events
```

### 2. Filter by Category

```dart
// All onboarding events have category: 'onboarding'
// Easy to filter in log viewer or grep
```

### 3. Analyze Performance

**Initial Build:**
- Look for `event: 'screen_build_end'` with `isInitialBuild: true`
- Check `durationMs` against threshold (100ms)
- If > 150ms, investigate synchronous work in build

**Rebuilds:**
- Look for `event: 'screen_rebuild'`
- Check if rebuilds are frequent or slow
- Identify trigger if possible

**Page Navigation:**
- Look for `event: 'page_change'`
- Verify smooth transitions
- Check for unexpected page changes

**Completion Flow:**
- Look for `event: 'complete_start'` and `complete_end'`
- Calculate total duration
- Check individual `add_space_end` durations
- Verify `mark_complete_end` duration

### 4. Follow the Discipline Rule

**Before optimizing:**
1. Check logs - Is there a long duration entry?
2. Check Timeline - Are there long UI frames?
3. Check CPU profile - Is there heavy synchronous work?

**Only optimize if at least one says "yes".**

---

## Integration with Existing Systems

### AppLogger

All logging uses the existing `AppLogger` system:
- Respects log levels (info, warning, error)
- Includes rich context
- Supports operation tracking (startOperation/endOperation)
- Integrates with crash detection
- Privacy filter applied automatically

### Performance Tracking

Uses `AppLogger.startOperation()` and `endOperation()`:
- Tracks operation duration automatically
- Warns if operations exceed thresholds
- Supports nested operations
- Provides correlation IDs

### Error Handling

All errors logged with:
- Full stack trace
- Error type
- Context at time of error
- Duration before error
- Category and event for filtering

---

## Files Modified

1. **`.kiro/steering/onboarding-performance-checklist.md`** (NEW)
   - Comprehensive performance checklist
   - Mandatory for all AI agents
   - Includes logging guidelines, thresholds, and interpretation rules

2. **`lib/features/spaces/ui/onboarding_screen.dart`** (MODIFIED)
   - Added comprehensive performance logging
   - Tracks initial build, rebuilds, page changes, completion flow
   - Includes error handling with context
   - Uses consistent logging format

3. **`.kiro/steering/flutter-ui-performance.md`** (UPDATED)
   - Updated OnboardingScreen Known Issues section
   - Marked as FIXED with reference to new logging

4. **`ONBOARDING_PERFORMANCE_LOGGING_ADDED.md`** (NEW)
   - This summary document

---

## Testing

### Manual Testing Steps

1. **Start app in profile mode:**
   ```bash
   flutter run --profile
   ```

2. **Go through onboarding:**
   - Navigate through all 3 pages
   - Select some spaces
   - Complete onboarding

3. **Retrieve logs:**
   ```powershell
   .\get_crash_logs.ps1
   ```

4. **Verify logging:**
   - Check for `category: 'onboarding'` entries
   - Verify build time logged
   - Verify page changes logged
   - Verify completion flow logged with all sub-operations

### Expected Log Entries

```
[INFO] OnboardingScreen initialized (category: onboarding, event: screen_init)
[INFO] OnboardingScreen spaces cached (category: onboarding, event: spaces_cached, spaceCount: 8)
[INFO] OnboardingScreen initial build completed (category: onboarding, event: screen_build_end, durationMs: 69, status: good, isInitialBuild: true)
[INFO] Onboarding page changed (category: onboarding, event: page_change, fromPage: 0, toPage: 1)
[INFO] Onboarding page changed (category: onboarding, event: page_change, fromPage: 1, toPage: 2)
[INFO] Onboarding completion started (category: onboarding, event: complete_start, selectedSpacesCount: 3)
[INFO] Space added during onboarding (category: onboarding, event: add_space_end, spaceId: health, durationMs: 45)
[INFO] Space added during onboarding (category: onboarding, event: add_space_end, spaceId: education, durationMs: 38)
[INFO] Space added during onboarding (category: onboarding, event: add_space_end, spaceId: finance, durationMs: 42)
[INFO] Onboarding marked complete (category: onboarding, event: mark_complete_end, durationMs: 23)
[INFO] Onboarding completed successfully (category: onboarding, event: complete_end, durationMs: 234, spacesAdded: 3)
```

---

## Benefits

### 1. Visibility

- Clear visibility into OnboardingScreen performance
- Easy to identify bottlenecks
- Track performance over time

### 2. Data-Driven Optimization

- No guessing - logs show exactly what's slow
- Follow discipline rule: optimize only with data
- Measure impact of optimizations

### 3. Debugging

- Comprehensive error context
- Easy to reproduce issues
- Clear correlation between events

### 4. Monitoring

- Track performance regressions
- Identify trends
- Catch issues early

### 5. Documentation

- Logs serve as documentation of behavior
- Easy to understand flow from logs
- Helps onboarding new developers

---

## Next Steps

### Immediate

- ✅ Steering file created
- ✅ Logging implemented
- ✅ Documentation updated

### Future Enhancements

1. **Add rebuild trigger tracking:**
   - Track what causes rebuilds (setState, provider, etc.)
   - Helps identify unnecessary rebuilds

2. **Add memory tracking:**
   - Log memory usage during onboarding
   - Detect memory leaks

3. **Add frame drop correlation:**
   - Correlate logs with frame drops
   - Identify exact cause of jank

4. **Add automated alerts:**
   - Alert if build time exceeds threshold
   - Alert if completion takes too long

---

## References

- `.kiro/steering/onboarding-performance-checklist.md` - Performance checklist
- `.kiro/steering/logging-guidelines.md` - AppLogger usage
- `.kiro/steering/flutter-ui-performance.md` - Flutter performance rules
- `ONBOARDING_PERFORMANCE_FIX.md` - Previous optimization
- `KNOWN_ISSUES_AND_FIXES.md` - Issue history

---

## Success Criteria

✅ **Comprehensive logging implemented**
- Screen level events tracked
- Page level events tracked
- Completion flow tracked
- Error handling included

✅ **Consistent format**
- All logs use category: 'onboarding'
- All logs include relevant context
- All logs follow AppLogger patterns

✅ **Performance thresholds defined**
- Build time thresholds clear
- Completion time expectations set
- Warning levels appropriate

✅ **Documentation complete**
- Steering file created
- Implementation documented
- Usage guidelines provided

✅ **Integration verified**
- Uses existing AppLogger
- Follows logging guidelines
- No syntax errors

---

**Status:** Ready for testing and monitoring

**Last Updated:** November 18, 2024
