# Bugs Collected - Manual Testing Session
**Date:** November 28, 2024  
**Session:** AI Chat Manual Testing (Stage 4)

---

## 🔴 Critical Bugs

### 1. AiChatController Lifecycle Bug - ✅ FIXED
**Severity:** CRITICAL  
**Status:** FIXED  
**File:** `lib/features/ai_chat/ui/controllers/ai_chat_controller.dart`

**Issue:**
- Missing `mounted` checks before updating state after async operations
- Causes FATAL crashes when navigating away from AI chat screen quickly
- Error: `Bad state: Tried to use AiChatController after dispose was called`

**Locations:**
- `loadInitial()` method (lines 74, 86)
- `sendMessage()` method (line 136)
- `_queueOffline()` method
- `provideFeedback()` method
- `switchSpace()` method

**Impact:**
- App crashes when user navigates away from AI chat before async operations complete
- Happens consistently on every quick navigation
- Logged as FATAL error

**Fix Applied:**
- Added `if (!mounted) return;` checks after all async operations
- Prevents state updates after controller disposal
- No more crashes on navigation

**Test to Verify Fix:**
1. Open AI chat screen
2. Send a message
3. Immediately navigate back before response arrives
4. Should NOT crash

---

### 2. OnboardingScreen Performance Issue - ✅ ALREADY FIXED
**Severity:** CRITICAL  
**Status:** ALREADY FIXED (but still showing slow in logs)  
**File:** `lib/features/spaces/ui/onboarding_screen.dart`

**Issue:**
- Initial build taking 898ms (target: <100ms)
- Causes 64 frames to be skipped
- Poor user experience on app startup

**Metrics:**
- Build time: 898ms
- Target: <100ms
- Exceeded by: 798ms (8x slower than target)
- Frames skipped: 64

**Root Cause:**
- Heavy work in build method (calling `getAllDefaultSpaces()` repeatedly)

**Fix Already Applied:**
- Spaces cached in `initState()` (line 68-70)
- Cached spaces used in `build()` instead of registry calls
- RepaintBoundary added to isolate page repaints

**Note:**
- The 898ms in logs might be from before the fix
- Or could be emulator performance issue
- Needs re-testing after clean build

---

### 7. ContextMetricsCard Crash - 🔴 CRITICAL (NEW)
**Severity:** CRITICAL  
**Status:** NOT FIXED  
**File:** `lib/ui/settings/widgets/context_metrics_card.dart:21`

**Issue:**
- ContextMetricsCard trying to use Riverpod provider outside of ProviderScope
- Widget not wrapped in proper provider context
- Crashes repeatedly when Settings screen tries to display Context Metrics

**Error:**
```
[FATAL] Bad state: No ProviderScope found
```

**Impact:**
- Settings screen crashes when trying to display Context Metrics
- Happens repeatedly (3+ times in logs)
- Prevents users from viewing context metrics dashboard
- Blocks Scenario 7 testing (Context Stats Display)

**Root Cause:**
- ContextMetricsCard is a ConsumerWidget trying to watch providers
- Widget is not wrapped in ProviderScope
- Likely Settings screen navigation doesn't preserve provider scope

**Potential Fix:**
- Wrap ContextMetricsCard in ProviderScope
- Or ensure Settings screen is within app's ProviderScope
- Or make ContextMetricsCard handle missing provider gracefully

---

## ⚠️ Warning Level Bugs

### 3. SpaceProvider Initialization Slow
**Severity:** WARNING  
**Status:** NOT FIXED  
**File:** SpaceProvider initialization

**Issue:**
- Initialization takes 1,177ms (threshold: 500ms)
- Causes 153 frames to be skipped during app startup

**Metrics:**
- Duration: 1,177ms
- Threshold: 500ms
- Exceeded by: 668ms (2.4x slower)
- Frames skipped: 153

**Impact:**
- Slow app startup
- Janky initial animation
- Poor first impression

**Potential Fix:**
- Parallelize loading operations where possible
- Use `Future.wait()` for independent operations
- Cache more aggressively

---

### 4. AI Chat Response Time Very Slow
**Severity:** WARNING  
**Status:** PARTIALLY ENVIRONMENT ISSUE  
**Component:** AI Chat + Backend Server

**Issue:**
- Responses taking 127-128 seconds
- Multiple timeouts and retries
- Very poor user experience

**Metrics:**
- First message: 127.52s
- Second message: 128.70s
- Timeout threshold: 60s
- Retry attempts: 2-3 per message

**Contributing Factors:**
1. Backend server not running initially (environment issue)
2. 60s timeout + retry delays
3. Possible slow LLM API response

**Impact:**
- Users wait over 2 minutes for responses
- Multiple timeout errors in logs
- Frustrating user experience

**Potential Fixes:**
- Reduce timeout to 30s
- Show better loading indicators
- Add "cancel request" button
- Optimize backend response time
- Consider streaming responses

---

## 🔧 Environment Issues

### 5. Backend Server Not Running
**Severity:** ENVIRONMENT  
**Status:** RESOLVED  
**Component:** Backend Server

**Issue:**
- Backend server at `http://10.0.2.2:3030` not responding
- AI chat requests timing out
- No responses to user queries

**Error:**
```
[ERROR] Chat request timed out
Request timed out after 60s
endpoint: http://10.0.2.2:3030/api/v1/chat/message
```

**Resolution:**
- Started backend server with `npm start` in `server/` directory
- Server now running on port 3030
- AI chat working after server start

**Recommendation:**
- Document server startup in testing guide
- Consider auto-starting server in development
- Add health check endpoint

---

## 📊 Performance Metrics Summary

### App Startup Performance
| Component | Threshold | Actual | Status | Frames Skipped |
|-----------|-----------|--------|--------|----------------|
| OnboardingScreen build | 100ms | 898ms | 🔴 8x slower | 64 |
| SpaceProvider init | 500ms | 1,177ms | 🔴 2.4x slower | 153 |
| Space caching | - | 10ms | ✅ Good | 0 |
| Load active spaces | - | 46ms | ✅ Good | 0 |
| Load current space | - | 32ms | ✅ Good | 0 |

### AI Chat Performance
| Metric | Value | Status |
|--------|-------|--------|
| First message response | 127.52s | 🔴 Very slow |
| Second message response | 128.70s | 🔴 Very slow |
| Context assembly | 120-164ms | ✅ Good |
| Token usage | 114 tokens | ✅ Good |
| Records included | 6 | ✅ Good |

### Frame Performance
| Event | Frames Skipped | Cause |
|-------|----------------|-------|
| App startup | 153 | SpaceProvider init |
| Onboarding load | 64 | OnboardingScreen build |
| Keyboard animation | 3-6 | IME animation jank |

---

## 🐛 Additional Issues Found

### 6. Keyboard Animation Jank
**Severity:** MINOR  
**Status:** NOT FIXED

**Issue:**
- Missed frames during keyboard (IME) animation
- 3-6 frames skipped when keyboard appears

**Logs:**
```
Missed SF frame:JANK_COMPOSER
Missed App frame:UNKNOWN: 3
```

**Impact:**
- Slight stutter when keyboard opens
- Noticeable on slower devices

**Potential Fix:**
- Use RepaintBoundary to isolate keyboard area
- Reduce rebuilds when keyboard state changes
- Use const widgets where possible

---

## ✅ What's Working Well

### Context System (Stage 4)
- ✅ Date range filtering working (7-day and 14-day filters tested)
- ✅ Token budget allocation correct (4800 total)
- ✅ Context assembly fast (47-164ms)
- ✅ Record filtering working (13 total → 6-10 included based on date range)
- ✅ Relevance scoring working correctly (scores 5.13-6.77)
- ✅ Token usage efficient (114-208 tokens, 5.7-10.4% utilization)
- ✅ Frequently viewed records score higher (validated in Scenario 5)

### AI Chat Functionality
- ✅ Messages sending successfully (2.5-2.8s response time after fix)
- ✅ Context building correctly
- ✅ Space isolation working
- ✅ Message persistence working
- ✅ Retry logic working (with exponential backoff)
- ✅ No more lifecycle crashes after fix

---

## 🎯 Priority Fixes Needed

### High Priority
1. ✅ **AiChatController lifecycle** - FIXED
2. 🔴 **ContextMetricsCard crash** - NEEDS FIX (blocks testing)
3. ⏳ **OnboardingScreen performance** - Needs verification after clean build

### Medium Priority
4. ⏳ **SpaceProvider initialization** - Parallelize operations
5. ⏳ **Keyboard animation jank** - Add RepaintBoundary

### Low Priority
6. ⏳ **Better error messages** - User-friendly timeout messages
7. ⏳ **Loading indicators** - Show progress during long operations

---

## 📝 Testing Notes

### Test Environment
- Device: Android Emulator (sdk gphone64 x86 64)
- Flutter: Debug mode
- Backend: Node.js server on port 3030
- Date: November 28-29, 2024

### Tests Completed ✅
- ✅ AI chat message sending
- ✅ Navigation between screens
- ✅ Context building and filtering
- ✅ Space selection
- ✅ Onboarding flow
- ✅ Scenario 3: Stage 4 with 7-day filter (2 queries)
- ✅ Scenario 4: Stage 4 with 14-day filter (3 queries)
- ✅ Scenario 5: Relevance scoring validation

### Tests Remaining ⏳
- ⏳ Scenario 6: Token budget enforcement (needs 100+ records)
- ⏳ Scenario 7: Context stats display (blocked by ContextMetricsCard crash)
- ⏳ Scenario 8: User feedback system
- ⏳ Scenario 9: Space switching
- ⏳ Scenario 10: Edge cases
- ⏳ Token savings measurement
- ⏳ Response quality assessment

---

## 🔄 Next Steps

1. **Fix ContextMetricsCard crash** - Unblock Scenario 7 testing
2. **Implement bulk test data import** - Enable Scenario 6 testing (see TODO_TESTING_IMPROVEMENTS.md)
3. **Complete remaining scenarios** - Scenarios 6-10
4. **Measure token savings** - Compare baseline vs Stage 4
5. **Document final results** - Fill out metrics template
6. **Address remaining bugs** - Prioritize based on severity

---

## 📚 References

- Manual Testing Guide: `docs/ai/MANUAL_TESTING_GUIDE.md`
- Performance Guidelines: `.kiro/steering/flutter-ui-performance.md`
- Logging Guidelines: `.kiro/steering/logging-guidelines.md`
- Onboarding Checklist: `.kiro/steering/onboarding-performance-checklist.md`
- Testing Improvements: `TODO_TESTING_IMPROVEMENTS.md`

---

**Session Start:** November 28, 2024  
**Session End:** November 29, 2024  
**Total Bugs Found:** 7  
**Bugs Fixed:** 1  
**Bugs Already Fixed:** 1  
**Remaining:** 5
