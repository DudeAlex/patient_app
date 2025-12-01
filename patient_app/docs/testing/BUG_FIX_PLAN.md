# Bug Fix Plan - November 2024 Testing Session

**Based on:** `docs/testing/bugs/BUGS_COLLECTED_2024-11-28.md`  
**Created:** November 29, 2024  
**Status:** Planning Phase

---

## 📋 Summary

**Total Bugs:** 7  
**Fixed:** 2 (AiChatController lifecycle, Backend server setup)  
**Remaining:** 5  
**Priority:** 1 Critical, 2 Warning, 2 Minor

---

## 🎯 Fix Priority Order

### Phase 1: Critical Fixes (Blocking Issues)
1. ✅ **Bug #1: AiChatController Lifecycle** - ALREADY FIXED
2. 🔴 **Bug #7: ContextMetricsCard Crash** - NEEDS FIX NOW

### Phase 2: Performance Improvements
3. ⚠️ **Bug #2: OnboardingScreen Performance** - Verify fix
4. ⚠️ **Bug #3: SpaceProvider Initialization** - Optimize

### Phase 3: Minor Improvements
5. 🔵 **Bug #6: Keyboard Animation Jank** - Polish
6. 🔵 **Bug #4: AI Response Time** - Environment/Backend issue

---

## 🔴 Phase 1: Critical Fixes

### Bug #7: ContextMetricsCard Crash (PRIORITY 1)

**Status:** 🔴 CRITICAL - Blocks Scenario 7 testing  
**Estimated Time:** 15-30 minutes  
**Difficulty:** Easy

**Problem:**
```
Bad state: No ProviderScope found
File: lib/ui/settings/widgets/context_metrics_card.dart:21
```

**Root Cause:**
- ContextMetricsCard is a ConsumerWidget trying to watch providers
- Widget is not wrapped in ProviderScope
- Settings screen navigation doesn't preserve provider scope

**Solution Options:**

**Option A: Wrap in ProviderScope (Recommended)**
```dart
// In settings_screen.dart
ProviderScope(
  child: ContextMetricsCard(),
)
```

**Option B: Check if provider exists**
```dart
// In context_metrics_card.dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  try {
    final metrics = ref.watch(contextMetricsProvider);
    // ... render metrics
  } catch (e) {
    return Text('Metrics unavailable');
  }
}
```

**Option C: Make it a regular StatelessWidget**
```dart
// If metrics can be passed as props instead
class ContextMetricsCard extends StatelessWidget {
  final ContextMetrics metrics;
  // ...
}
```

**Implementation Steps:**
1. Read `lib/ui/settings/widgets/context_metrics_card.dart`
2. Read `lib/ui/settings/settings_screen.dart`
3. Identify where ContextMetricsCard is used
4. Check if ProviderScope exists in widget tree
5. Apply fix (Option A recommended)
6. Test: Navigate to Settings → verify no crash
7. Verify metrics display correctly

**Testing:**
- [ ] Navigate to Settings screen
- [ ] Scroll to Context Metrics section
- [ ] Verify no crash
- [ ] Verify metrics display correctly
- [ ] Send AI chat message
- [ ] Return to Settings
- [ ] Verify metrics updated

**Success Criteria:**
- ✅ No crash when viewing Settings
- ✅ Context metrics display correctly
- ✅ Metrics update after AI chat usage

---

## ⚠️ Phase 2: Performance Improvements

### Bug #2: OnboardingScreen Performance

**Status:** ⚠️ WARNING - Already has fix, needs verification  
**Estimated Time:** 30 minutes (testing only)  
**Difficulty:** Easy (just verification)

**Problem:**
- Initial build: 898ms (target: <100ms)
- 64 frames skipped

**Fix Already Applied:**
- Spaces cached in `initState()`
- Using `_cachedDefaultSpaces` in build

**Action Required:**
1. **Verify fix works** after clean build
2. **Measure new build time**
3. **Update documentation** if fixed

**Implementation Steps:**
1. Add performance logging to OnboardingScreen (if not already there)
2. Run app with clean build
3. Navigate to onboarding
4. Check logs for build time
5. If < 150ms: Mark as fixed
6. If still > 150ms: Investigate further

**Testing:**
- [ ] Clean build: `flutter clean && flutter pub get`
- [ ] Run app
- [ ] Navigate to onboarding
- [ ] Check logs for build time
- [ ] Verify < 150ms (acceptable) or < 100ms (target)

**Success Criteria:**
- ✅ Build time < 150ms (acceptable)
- ✅ Build time < 100ms (ideal)
- ✅ < 10 frames skipped

---

### Bug #3: SpaceProvider Initialization Slow

**Status:** ⚠️ WARNING - Needs optimization  
**Estimated Time:** 1-2 hours  
**Difficulty:** Medium

**Problem:**
- Initialization: 1,177ms (threshold: 500ms)
- 153 frames skipped
- Slow app startup

**Root Cause:**
- Sequential async operations
- Not parallelized

**Solution:**
Parallelize independent operations using `Future.wait()`

**Current (Sequential):**
```dart
Future<void> initialize() async {
  await loadSpaces();        // Wait...
  await loadCurrentSpace();  // Wait...
  await loadOnboarding();    // Wait...
  // Total: 1,177ms
}
```

**Proposed (Parallel):**
```dart
Future<void> initialize() async {
  await Future.wait([
    loadSpaces(),
    loadCurrentSpace(),
    loadOnboarding(),
  ]);
  // Expected: 300-500ms
}
```

**Implementation Steps:**
1. Find SpaceProvider initialization code
2. Identify independent operations
3. Group operations that can run in parallel
4. Use `Future.wait()` for parallel execution
5. Keep dependent operations sequential
6. Add performance logging
7. Test and measure improvement

**Testing:**
- [ ] Measure baseline: Current init time
- [ ] Apply parallelization
- [ ] Measure new init time
- [ ] Verify < 500ms
- [ ] Check for race conditions
- [ ] Verify app state is correct after init

**Success Criteria:**
- ✅ Initialization < 500ms
- ✅ < 50 frames skipped
- ✅ No race conditions
- ✅ App state correct after init

---

## 🔵 Phase 3: Minor Improvements

### Bug #6: Keyboard Animation Jank

**Status:** 🔵 MINOR - Polish  
**Estimated Time:** 30-45 minutes  
**Difficulty:** Easy

**Problem:**
- 3-6 frames skipped during keyboard animation
- Slight stutter when keyboard opens

**Solution:**
Use `RepaintBoundary` to isolate keyboard area

**Implementation:**
```dart
Column(
  children: [
    RepaintBoundary(
      child: ExpensiveHeader(),
    ),
    TextField(), // Keyboard triggers here
    RepaintBoundary(
      child: ExpensiveList(),
    ),
  ],
)
```

**Implementation Steps:**
1. Identify screens with keyboard input (AI Chat, Record Edit, etc.)
2. Wrap expensive widgets in `RepaintBoundary`
3. Test keyboard animation
4. Measure frame drops
5. Verify improvement

**Testing:**
- [ ] Open AI Chat screen
- [ ] Tap input field (keyboard opens)
- [ ] Check logs for frame drops
- [ ] Verify < 3 frames skipped
- [ ] Test on multiple screens

**Success Criteria:**
- ✅ < 3 frames skipped during keyboard animation
- ✅ Smooth keyboard transition
- ✅ No visual glitches

---

### Bug #4: AI Response Time (Environment Issue)

**Status:** 🔵 MINOR - Mostly environment/backend  
**Estimated Time:** 1 hour (if addressing)  
**Difficulty:** Medium

**Problem:**
- Initial responses: 127-128s (with timeouts)
- After fix: 2.5-2.8s (acceptable)

**Root Cause:**
- Backend server not running initially
- 60s timeout + retries
- Possible slow LLM API

**Current Status:**
- ✅ Backend server now running
- ✅ Response time now 2.5-2.8s (acceptable)
- ⚠️ Could be improved further

**Optional Improvements:**
1. **Reduce timeout** from 60s to 30s
2. **Add cancel button** for long requests
3. **Better loading indicators** with progress
4. **Streaming responses** (future enhancement)

**Implementation Steps (Optional):**
1. Reduce timeout in `http_ai_chat_service.dart`
2. Add cancel functionality to UI
3. Improve loading indicators
4. Test with slow network

**Testing:**
- [ ] Test with 30s timeout
- [ ] Test cancel functionality
- [ ] Verify user experience improved
- [ ] Test with slow network simulation

**Success Criteria:**
- ✅ Timeout reduced to 30s
- ✅ Cancel button works
- ✅ Better user feedback during wait

---

## 📅 Implementation Timeline

### Week 1: Critical Fixes
- **Day 1:** Fix Bug #7 (ContextMetricsCard crash)
- **Day 1:** Verify Bug #2 (OnboardingScreen performance)

### Week 2: Performance
- **Day 3-4:** Fix Bug #3 (SpaceProvider initialization)
- **Day 5:** Testing and verification

### Week 3: Polish (Optional)
- **Day 6:** Fix Bug #6 (Keyboard jank)
- **Day 7:** Improve Bug #4 (AI response time) if needed

---

## 🧪 Testing Checklist

### After Each Fix:
- [ ] Run app with clean build
- [ ] Test specific bug scenario
- [ ] Check logs for errors
- [ ] Verify no regressions
- [ ] Update bug status in BUGS_COLLECTED document
- [ ] Commit with clear message

### Before Marking Complete:
- [ ] All critical bugs fixed
- [ ] All tests passing
- [ ] Performance metrics improved
- [ ] Documentation updated
- [ ] User experience validated

---

## 📊 Success Metrics

### Performance Targets:
| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| OnboardingScreen build | 898ms | <100ms | ⏳ Verify |
| SpaceProvider init | 1,177ms | <500ms | ⏳ Fix |
| AI response time | 2.6s | <3s | ✅ Good |
| Keyboard animation | 3-6 frames | <3 frames | ⏳ Fix |

### Bug Status:
- 🔴 Critical: 0 remaining (1 to fix)
- ⚠️ Warning: 2 remaining
- 🔵 Minor: 2 remaining
- ✅ Fixed: 2 complete

---

## 🔄 Next Steps

1. **Start with Bug #7** (ContextMetricsCard) - Highest priority
2. **Verify Bug #2** (OnboardingScreen) - Quick win
3. **Fix Bug #3** (SpaceProvider) - Biggest impact
4. **Polish Bug #6** (Keyboard) - User experience
5. **Consider Bug #4** (AI timeout) - Optional improvement

---

## 📝 Notes

- All fixes should include performance logging
- Follow Flutter performance guidelines (`.kiro/steering/flutter-ui-performance.md`)
- Use AppLogger for all logging (`.kiro/steering/logging-guidelines.md`)
- Test on both emulator and real device
- Update BUGS_COLLECTED document after each fix

---

**Created:** November 29, 2024  
**Last Updated:** November 29, 2024  
**Status:** Ready for Implementation
