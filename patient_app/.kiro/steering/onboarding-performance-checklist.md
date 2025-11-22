---
inclusion: always
---

# OnboardingScreen Performance Checklist

Patient App – OnboardingScreen

## GOAL

Separate real synchronous performance problems from normal async I/O.

Focus on measurable bottlenecks in OnboardingScreen:
- build cost
- navigation between pages
- completion flow (_completeOnboarding)

---

## 1. WHAT TO LOG

Log only what gives you signal:

### 1.1 Screen Level Events

**OnboardingScreen first build:**
- start time
- end time
- durationMs

**OnboardingScreen rebuilds:**
- reason if you can infer it (page change, state change)

### 1.2 Page Level Events

**Page index changes:**
- {pageIndex, fromPage, toPage}

**Any heavy widget initialization:**
- complex images
- large lists
- large layouts

### 1.3 Completion Flow

**_completeOnboarding:**
- start timestamp
- end timestamp
- durationMs
- count of selected spaces

**Each call to addSpace:**
- spaceId
- start and end timestamps
- durationMs

**markOnboardingComplete:**
- start and end timestamps
- durationMs

### 1.4 Error and Fallback

**Any exception inside _completeOnboarding:**
- error type
- message
- stack trace (shortened)

**Timeouts or manual cancellation if you add them**

### Logging Format

Use AppLogger with structured context:

```dart
await AppLogger.info('Onboarding event', context: {
  'category': 'onboarding',
  'event': 'screen_build_start', // or screen_build_end, page_change, complete_start, etc.
  'pageIndex': currentPage,
  'durationMs': duration.inMilliseconds,
  'selectedSpacesCount': selectedSpaces.length,
  'spaceId': spaceId,
  // ... other relevant context
});
```

---

## 2. WHAT TO MEASURE

On each meaningful run, you care about:

### 2.1 Initial Build Time

- OnboardingScreen initial build durationMs
- **Target:** ideally under 100 ms on your emulator; definitely under 200 ms

### 2.2 Rebuild Costs

- Duration of build when page changes
- **Target:** tens of ms, not hundreds

### 2.3 Completion Time

- _completeOnboarding total durationMs
- Duration per addSpace
- Duration of markOnboardingComplete

### 2.4 Jank Correlation

- Look at moments where you feel lag or stutter
- Compare with log timestamps:
  - which event was running
  - was it build or long async work

**If there is lag with no long duration in any log event:**
- suspect emulator or device; not your code

---

## 3. HOW TO TRACK REBUILD COSTS

Your goal: know how expensive OnboardingScreen builds are.

### 3.1 Instrument Build

**At the top of build method of OnboardingScreen:**
- record start time

**At the end:**
- record end time
- compute duration
- log:

```dart
await AppLogger.info('Onboarding screen build', context: {
  'category': 'onboarding',
  'event': 'screen_build',
  'durationMs': duration.inMilliseconds,
  'pageIndex': _currentPage,
  'isInitialBuild': _isFirstBuild,
});
```

### 3.2 Track Rebuild Reasons

If you can, add a simple debug flag or note in context:
- trigger: "page_change" or "locale_change" or "theme_change" or "other"
- You can pass this trigger via a simple field when you call setState

### 3.3 Set Thresholds

- **< 50 ms:** good
- **50 – 150 ms:** watch
- **> 150 ms:** investigate

### 3.4 Use DevTools Rebuild Stats

- Open Flutter DevTools
- Widget rebuild stats:
  - watch OnboardingScreen and any nested heavy widget
  - see how often they rebuild when you swipe pages

**If you see frequent rebuilds of widgets that should not change when page changes:**
- your state management or layout is wrong

---

## 4. HOW TO DETECT SYNCHRONOUS HOTSPOTS

The rule: **synchronous work in build or event handlers is the real enemy.**

### 4.1 Code Inspection

Look inside:
- OnboardingScreen.build
- _buildFeaturesOverviewStep
- any helper methods called from build

**Red flags:**
- loops over large lists
- map/filter/sort on large collections
- JSON decode / encode
- heavy string construction
- reading from DB inside build
- reading from file system inside build
- date or number formatting in a loop

### 4.2 Handler Inspection

Check onTap, onPressed, onPageChanged handlers

**Red flags:**
- heavy sync transforms before first await
- for example:
  - building giant lists
  - scanning storage
  - parsing big blobs

### 4.3 Timing Around Build

If build durationMs is high and you know there is no heavy async in that section:
- the culprit is synchronous work in build itself

**Move heavy work:**
- to initState
- to ViewModel
- to a separate precomputation step

### 4.4 Confirm with DevTools

Use the CPU profiler in DevTools during slow operations

**Look for:**
- long sync Dart functions in call tree
- not just long periods of waiting on futures

---

## 5. HOW TO ISOLATE UI JANK

Jank means frames are not rendered in time.

### 5.1 Use Performance Overlay

```bash
flutter run --profile
```

In app: enable Performance Overlay (from DevTools or debug options)

**Watch:**
- tall spikes in the top chart (build)
- tall spikes in the bottom chart (rasterization)

### 5.2 Reproduce Problem Precisely

- Go to onboarding page 2
- Swipe between pages 1, 2, 3
- Tap "Continue" or "Finish onboarding"
- Note the exact interaction where jank happens

### 5.3 Correlate with Logs

Check timestamps around those interactions

**Look for:**
- long build durations
- long _completeOnboarding durations
- repeated rebuild logs when they should not happen

### 5.4 Isolate by Temporary Switches

Temporarily remove:
- complex images
- big lists
- fancy layout or animations

**If jank disappears after removing one element:**
- you found the hotspot

### 5.5 Check Device vs Emulator

Run the same scenario on real device

**If jank exists only on emulator:**
- do not waste time "optimizing" code for emulator limitations

---

## 6. WHAT TO WATCH IN DEVTOOLS TIMELINE

Timeline is your objective truth for frames.

### 6.1 Frames

Look at the Timeline at the moment you:
- change onboarding pages
- complete onboarding

**Watch the bars for:**
- UI (Dart)
- GPU (raster)

### 6.2 Long Frames

- Any frame above 16 ms is missing 60 FPS
- Frames above 32 ms are clearly visible as jank

**If the UI bar is tall:**
- you have heavy Dart work in this frame

**If the GPU bar is tall:**
- rendering is heavy: large shadows, complex clips, many layers

### 6.3 Dart CPU Profile

Switch to CPU profile around a slow interaction

**Look for:**
- functions with highest self time
- functions with highest total time

**If you see your onboarding widgets or any data preparation here:**
- this is a real hotspot to refactor

### 6.4 Rebuild Counts

DevTools → Flutter Inspector → Rebuild stats:
- see how many times OnboardingScreen and sub widgets rebuild during:
  - page swipes
  - completing onboarding

**If they rebuild many times per gesture:**
- you have over eager state changes

---

## 7. INTERPRETATION: REAL ISSUE VS NORMAL ASYNC

Use this logic:

### 7.1 Real Performance Issue

**If:**
- build durationMs is high (hundreds of ms)
- Timeline shows tall UI bar
- CPU profile shows heavy synchronous functions

**Then:**
- Real performance issue: fix sync hotspots.

### 7.2 Normal Async I/O

**If:**
- build durationMs is low
- _completeOnboarding total durationMs is moderate (for example 200–800 ms)
- Timeline shows mostly idle time or I/O waits

**Then:**
- This is normal async I/O; not a performance bug.

### 7.3 Environment Issue

**If:**
- App is fine on real device
- Only emulator disconnects or lags heavily

**Then:**
- Environment issue; not your app; do not over optimize code for that.

---

## 8. DISCIPLINE RULE

**Before you change code "for performance":**

1. **Check logs:**
   - Is there a long duration entry for this interaction?

2. **Check Timeline:**
   - Are there long UI frames?

3. **Check CPU profile:**
   - Is there a heavy synchronous function?

**Only if at least one of these says "yes": you optimize.**

**No data; no optimization.**

---

## AI Agent Instructions

When working on OnboardingScreen performance:

1. **Always instrument before optimizing** - Add logging first, measure, then optimize
2. **Use AppLogger consistently** - Follow the logging format specified in section 1
3. **Set clear thresholds** - Use the targets in section 2 to determine if optimization is needed
4. **Distinguish sync from async** - Remember: async I/O is not a performance problem
5. **Profile with DevTools** - Use Timeline and CPU profiler to confirm issues before fixing
6. **Follow the discipline rule** - Never optimize without data

---

## References

- `.kiro/steering/logging-guidelines.md` - AppLogger usage patterns
- `.kiro/steering/flutter-ui-performance.md` - General Flutter performance rules
- `ONBOARDING_PERFORMANCE_FIX.md` - Previous OnboardingScreen optimization
- `KNOWN_ISSUES_AND_FIXES.md` - Known performance issues

---

**Last Updated:** November 18, 2024
**Status:** Active - Mandatory for OnboardingScreen performance work
