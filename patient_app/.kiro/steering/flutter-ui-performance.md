---
inclusion: always
---

# Flutter UI Performance Guidelines

## Purpose

Mandatory performance standards for all Flutter UI code in the Patient App. These rules prevent common performance pitfalls that cause frame drops, crashes, and poor user experience.

## Goal

Keep every screen light, predictable, and easy to debug. No heavy widgets, no accidental rebuild storms.

---

## 1. Build Functions (No Heavy Work in Build)

### Rules

- ❌ **NO** loops, sorting, filtering, or data transformations inside `build`
- ❌ **NO** `map/filter/sort` on big collections inside `build`
- ❌ **NO** async calls inside `build`
- ❌ **NO** expensive formatting (date, number, string) inside `build` on every frame
- ❌ **NO** database calls or complex calculations inside `build`

### Why

The `build` method can be called many times per second. Any heavy **synchronous** work causes frame drops and janky UI.

### Important Distinction

**What blocks the UI thread:**
- ❌ Heavy synchronous work: loops, sorting, filtering, JSON parsing, crypto
- ❌ Expensive calculations, string operations, data transformations

**What does NOT block the UI thread:**
- ✅ Sequential `await` operations (async I/O, database, network)
- ✅ The UI thread yields while waiting for async operations

**Example:**
```dart
// ❌ BLOCKS UI - synchronous loop processing
for (var i = 0; i < 10000; i++) {
  list.add(expensiveCalculation(i)); // Synchronous work
}

// ✅ Does NOT block UI - async I/O
for (final id in ids) {
  await database.save(id); // Yields to UI thread while waiting
}
```

### Solution

Move all data preparation and transformations into:
- ViewModel / Controller / Provider (before widget builds)
- `initState` or `didChangeDependencies`
- Computed properties that cache results

### Example

```dart
// ❌ BAD - Heavy work in build
@override
Widget build(BuildContext context) {
  final sortedItems = items.sort((a, b) => a.date.compareTo(b.date)); // BAD!
  final formattedDate = DateFormat.yMMMd().format(DateTime.now()); // BAD!
  
  return ListView(
    children: sortedItems.map((item) => ItemCard(item)).toList(), // BAD!
  );
}

// ✅ GOOD - Prepare data before build
class MyWidgetState extends State<MyWidget> {
  late List<Item> sortedItems;
  late String formattedDate;
  
  @override
  void initState() {
    super.initState();
    _prepareData();
  }
  
  void _prepareData() {
    sortedItems = items.toList()..sort((a, b) => a.date.compareTo(b.date));
    formattedDate = DateFormat.yMMMd().format(DateTime.now());
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: sortedItems.length,
      itemBuilder: (context, index) => ItemCard(sortedItems[index]),
    );
  }
}
```

---

## 2. Rebuilds and State

### Rules

- ✅ `setState` should **only** rebuild the minimal part that changed
- ✅ Use `ValueListenableBuilder`, `Selector`, `AnimatedBuilder` to limit rebuilds
- ✅ Separate UI into small widgets so only the minimal part rebuilds
- ❌ **NO** rebuilding entire screen when only one label changes

### Why

Unnecessary rebuilds waste CPU and cause frame drops. If only a number changes, only that widget should rebuild.

### Solution

```dart
// ❌ BAD - Entire screen rebuilds for counter
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  int counter = 0;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpensiveHeader(), // Rebuilds unnecessarily!
        Text('Count: $counter'),
        ExpensiveFooter(), // Rebuilds unnecessarily!
      ],
    );
  }
}

// ✅ GOOD - Only counter widget rebuilds
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpensiveHeader(), // Never rebuilds
        CounterWidget(), // Only this rebuilds
        ExpensiveFooter(), // Never rebuilds
      ],
    );
  }
}

class CounterWidget extends StatefulWidget {
  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int counter = 0;
  
  @override
  Widget build(BuildContext context) {
    return Text('Count: $counter'); // Minimal rebuild
  }
}
```

---

## 3. Lists and Collections

### Rules

- ✅ **ALWAYS** use `ListView.builder`, `GridView.builder`, or `SliverList` for lists
- ❌ **NO** `Column(children: bigList)` for more than ~10 items
- ❌ **NO** rendering hundreds of widgets at once
- ✅ List item widgets must be simple and light

### Why

Non-lazy lists render all items immediately, causing memory issues and slow scrolling.

### Critical Rule

**Any list with more than 20 items MUST be lazy (use `.builder`).**

### Example

```dart
// ❌ BAD - Renders all items immediately
Column(
  children: records.map((r) => RecordCard(r)).toList(), // BAD for large lists!
)

// ✅ GOOD - Lazy rendering
ListView.builder(
  itemCount: records.length,
  itemBuilder: (context, index) => RecordCard(records[index]),
)
```

---

## 4. Images

### Rules

- ✅ Use `Image.asset` or `CachedNetworkImage`
- ✅ **ALWAYS** provide `width` and `height` when possible
- ❌ **NO** loading very large images unnecessarily
- ❌ **NO** heavy image transformations in real time

### Why

Images without dimensions cause layout jumps. Large images consume memory and cause crashes.

---

## 5. Widget Tree and Layout

### Rules

- ❌ **NO** extremely deep nesting: `Column → Row → Container → Padding → Column → Row`
- ✅ Extract repeated or complex parts into separate `StatelessWidget`
- ✅ Keep layouts simple and predictable
- ✅ If a widget is > 100 lines or deeply nested, split it

### Why

Deep nesting makes code hard to read and can cause performance issues. Small widgets are easier to optimize.

### Example

```dart
// ❌ BAD - Deep nesting, hard to read
Widget build(BuildContext context) {
  return Container(
    child: Padding(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                child: Padding(
                  child: Column(
                    children: [
                      // 50 more lines...
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// ✅ GOOD - Split into small widgets
Widget build(BuildContext context) {
  return Column(
    children: [
      _HeaderSection(),
      _ContentSection(),
      _FooterSection(),
    ],
  );
}
```

---

## 6. Animations

### Rules

- ✅ Use animation widgets carefully: `AnimatedBuilder`, `AnimatedOpacity`
- ❌ **NO** animations that cause constant large rebuilds
- ❌ **NO** complex animations running all the time on every screen
- ✅ Turn off animations when not visible

### Why

Animations can cause constant rebuilds. Use them sparingly and wisely.

### RecordsHomeModern Example

We **removed** expensive animations (AnimatedContainer, ScaleTransition) to improve performance from 400+ frame drops to smooth scrolling.

---

## 7. Performance Diagnostics

### Required Actions

During development, **regularly**:

1. Enable Performance Overlay in Flutter
2. Use DevTools to inspect:
   - Rebuild counts
   - Flame chart for slow frames
   - CPU and GPU spikes

### Rule

**If a screen feels laggy, profile it BEFORE randomly changing the UI.**

### Tools

```bash
# Run with performance overlay
flutter run --profile

# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

---

## 8. Caching and Data Usage

### Rules

- ✅ Cache data that doesn't change frequently
- ✅ Load large lists gradually or page by page
- ❌ **NO** recreating heavy objects on every frame/build
- ✅ Keep in memory only what's needed for current screen

### Example

```dart
// ❌ BAD - Creates new formatter every build
Widget build(BuildContext context) {
  final formatter = DateFormat.yMMMd(); // BAD!
  return Text(formatter.format(date));
}

// ✅ GOOD - Cache formatter
class MyWidget extends StatelessWidget {
  static final _formatter = DateFormat.yMMMd(); // Cached
  
  @override
  Widget build(BuildContext context) {
    return Text(_formatter.format(date));
  }
}
```

---

## 9. Avoid Common Anti-Patterns

### ❌ Never Do This

1. **Huge FutureBuilder/StreamBuilder** that rebuild heavy trees frequently
2. **SingleChildScrollView** around large complex content with many children
3. **Very large Stack** with many Positioned children without reason
4. **Deep nested layouts** that are hard to parse
5. **Multiple scroll views** nested inside each other
6. **Heavy work in build closures** (map, where, etc.)

---

## 10. Mandatory Checklist for All UI Code

When writing or reviewing Flutter UI code, verify:

- [ ] No heavy logic inside `build` methods
- [ ] All data preparation happens before UI build
- [ ] Using lazy lists (`ListView.builder`) for any list > 20 items
- [ ] Small `StatelessWidget`s used to limit rebuild areas
- [ ] Not rebuilding entire screen for small state changes
- [ ] No deep nesting of layout widgets
- [ ] Split complex widgets into smaller components
- [ ] No heavy objects created inside `build` or closures repeatedly
- [ ] Performance risks documented with comments
- [ ] Profiled with DevTools if screen feels laggy

---

## AI Agent Instructions

When building or refactoring any Flutter UI screen, you **MUST**:

1. **Follow all rules above** - No exceptions without explicit approval
2. **Add comments** where performance risks may exist
3. **Propose lighter alternatives** if a design seems heavy
4. **Profile before and after** significant UI changes
5. **Document performance decisions** in code comments

### Example Comment

```dart
// PERFORMANCE: Using ListView.builder for lazy rendering
// to handle potentially large record lists (100+ items).
// Each card is wrapped in RepaintBoundary to isolate rebuilds.
```

---

## Success Stories

### RecordsHomeModern Optimization (November 2024)

**Before:**
- 400+ frame drops during scroll
- Expensive animations on every card
- Complex nested decorations

**After:**
- Smooth 60fps scrolling
- Removed AnimatedContainer and ScaleTransition
- Added RepaintBoundary for isolation
- Simplified card decorations
- Result: < 5 frame drops target achieved

**Key Lessons:**
- Animations are expensive - use sparingly
- RepaintBoundary prevents unnecessary repaints
- Simple decorations perform better than complex ones

---

## Known Issues

### OnboardingScreen Performance Problem (November 2024)

**Status:** ✅ FIXED (November 18, 2024)

**Original Symptoms:**
- 476ms build time (threshold: 100ms)
- 68+ frame drops
- Causes emulator crashes

**Root Cause:**
- Heavy work in build method (getAllDefaultSpaces() called on every build)

**Fix Applied:**
- Cached default spaces in initState
- Build time reduced from 476ms to 69ms (85% improvement)
- Comprehensive performance logging added

**Monitoring:**
- See `.kiro/steering/onboarding-performance-checklist.md` for logging guidelines
- Performance tracked via AppLogger with detailed metrics
- Build time, page changes, and completion flow all logged

**Details:** See KNOWN_ISSUES_AND_FIXES.md and ONBOARDING_PERFORMANCE_FIX.md

---

## References

- Flutter Performance Best Practices: https://docs.flutter.dev/perf/best-practices
- Flutter DevTools: https://docs.flutter.dev/tools/devtools
- RecordsHomeModern Optimization: `.kiro/specs/ui-performance-optimization/`
- Logging Guidelines: `.kiro/steering/logging-guidelines.md`

---

## Enforcement

These guidelines are **mandatory** for all Flutter UI code. Code reviews should verify compliance. Performance regressions should be caught early through profiling.

**Remember:** Fast UI = Happy Users = Successful App

---

**Last Updated:** November 18, 2024
**Status:** Active - Mandatory for all UI development
