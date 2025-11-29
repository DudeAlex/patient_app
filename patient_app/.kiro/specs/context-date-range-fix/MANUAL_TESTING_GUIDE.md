# Manual Testing Guide: Context Date Range Fix

## Overview

This guide provides step-by-step instructions for manually testing the context date range feature. All automated tests have passed, and this manual verification ensures the feature works correctly in real-world usage.

## Prerequisites

- Flutter app running on emulator or device
- Access to Settings screen
- AI features enabled (for testing AI chat integration)
- Test records in the database (for testing with data)

## Test Environment Setup

### 1. Prepare Test Data

Before starting, ensure you have test records:

```bash
# Run the seed script to create test records
dart tool/seed_records.dart
```

This will create records spanning different time periods for testing date range filtering.

### 2. Enable Logging

Ensure logging is enabled to verify correct behavior:

1. Check `assets/config/logging_config.json`
2. Ensure `minLevel` is set to `"info"` or `"debug"`
3. Ensure `consoleEnabled` is `true`

### 3. Clear Previous Settings (Optional)

To start fresh:

```bash
# Clear app data (Android)
flutter run
# Then: Settings > Apps > Patient App > Clear Data

# Or reinstall the app
flutter clean
flutter run
```

---

## Test Suite

### Test 1: Preset Date Range Options (7, 14, 30 days)

**Objective**: Verify preset options work correctly

**Steps**:

1. Open the app
2. Navigate to Settings screen
3. Scroll to "Context Settings" card
4. Observe the current selection (should default to 14 days)

**Test 1.1: Select 7 days**

1. Tap the "7 days" chip
2. **Expected**: 
   - Chip becomes selected (highlighted)
   - Snackbar appears: "Context date range set to 7 days"
   - No error messages
3. Check logs for:
   ```
   User updated date range (preset)
   dateRangeDays: 7
   isCustom: false
   ```

**Test 1.2: Select 14 days**

1. Tap the "14 days" chip
2. **Expected**:
   - Chip becomes selected
   - Snackbar appears: "Context date range set to 14 days"
3. Check logs for confirmation

**Test 1.3: Select 30 days**

1. Tap the "30 days" chip
2. **Expected**:
   - Chip becomes selected
   - Snackbar appears: "Context date range set to 30 days"
3. Check logs for confirmation

**Test 1.4: Switch between presets**

1. Tap 7 days → 14 days → 30 days → 7 days
2. **Expected**:
   - Each selection works smoothly
   - Snackbar appears for each change
   - No lag or errors

✅ **Pass Criteria**: All preset options work, snackbars appear, logs show correct values

---

### Test 2: Custom Date Range - Valid Values

**Objective**: Verify custom input accepts valid values

**Test 2.1: Enter custom value 45**

1. Tap the "Custom" chip
2. **Expected**:
   - Custom chip becomes selected
   - Text input field appears
   - Helper text shows: "Up to 3 years"
   - Informational text about token limits appears
3. Enter "45" in the text field
4. Tap the checkmark button (or press Enter)
5. **Expected**:
   - Snackbar appears: "Context date range set to 45 days (custom)"
   - No error message
   - Text field remains visible with "45"
6. Check logs for:
   ```
   User set custom date range
   dateRangeDays: 45
   isCustom: true
   ```

**Test 2.2: Enter custom value 1 (minimum)**

1. Clear the text field
2. Enter "1"
3. Tap checkmark
4. **Expected**:
   - Snackbar: "Context date range set to 1 days (custom)"
   - No error

**Test 2.3: Enter custom value 1095 (maximum)**

1. Clear the text field
2. Enter "1095"
3. Tap checkmark
4. **Expected**:
   - Snackbar: "Context date range set to 1095 days (custom)"
   - No error

**Test 2.4: Enter custom value 90**

1. Clear the text field
2. Enter "90"
3. Tap checkmark
4. **Expected**: Success

**Test 2.5: Enter custom value 365**

1. Clear the text field
2. Enter "365"
3. Tap checkmark
4. **Expected**: Success

✅ **Pass Criteria**: All valid values (1, 45, 90, 365, 1095) are accepted without errors

---

### Test 3: Custom Date Range - Invalid Values

**Objective**: Verify custom input rejects invalid values with clear error messages

**Test 3.1: Enter 0**

1. Tap "Custom" chip
2. Enter "0"
3. Tap checkmark
4. **Expected**:
   - Error message appears: "Must be between 1 and 1095 (up to 3 years)"
   - Value is NOT saved
   - No snackbar appears
   - Text field shows error state (red)

**Test 3.2: Enter -1 (negative)**

1. Clear field
2. Enter "-1"
3. Tap checkmark
4. **Expected**:
   - Error message: "Must be between 1 and 1095 (up to 3 years)"
   - Value is NOT saved

**Test 3.3: Enter 1096 (over maximum)**

1. Clear field
2. Enter "1096"
3. Tap checkmark
4. **Expected**:
   - Error message: "Must be between 1 and 1095 (up to 3 years)"
   - Value is NOT saved

**Test 3.4: Enter "abc" (non-numeric)**

1. Clear field
2. Enter "abc"
3. Tap checkmark
4. **Expected**:
   - Error message: "Please enter a valid number"
   - Value is NOT saved

**Test 3.5: Enter empty string**

1. Clear field completely
2. Tap checkmark
3. **Expected**:
   - Error message: "Please enter a number"
   - Value is NOT saved

**Test 3.6: Error message clears on valid input**

1. Enter "0" (invalid)
2. Tap checkmark (error appears)
3. Clear field and enter "30" (valid)
4. **Expected**:
   - Error message disappears as you type
   - Checkmark becomes enabled
5. Tap checkmark
6. **Expected**: Success, no error

✅ **Pass Criteria**: All invalid values are rejected with clear, helpful error messages

---

### Test 4: Switching Between Preset and Custom

**Objective**: Verify users can switch between preset and custom modes

**Test 4.1: Preset → Custom**

1. Select "14 days" preset
2. Tap "Custom" chip
3. **Expected**:
   - Custom mode activates
   - Text field appears with "14" pre-filled
4. Change to "60" and apply
5. **Expected**: Success

**Test 4.2: Custom → Preset**

1. With custom value "60" active
2. Tap "7 days" preset chip
3. **Expected**:
   - Custom mode deactivates
   - Text field disappears
   - 7 days becomes selected
   - Snackbar: "Context date range set to 7 days"

**Test 4.3: Custom → Custom (different value)**

1. Tap "Custom" chip
2. Enter "45"
3. Apply
4. Enter "90"
5. Apply
6. **Expected**: Both values work correctly

✅ **Pass Criteria**: Smooth transitions between preset and custom modes

---

### Test 5: Setting Persistence

**Objective**: Verify settings persist across app restarts

**Test 5.1: Preset persistence**

1. Set date range to 30 days
2. Close the app completely (swipe away from recent apps)
3. Reopen the app
4. Navigate to Settings
5. **Expected**:
   - "30 days" chip is selected
   - Custom mode is NOT active

**Test 5.2: Custom persistence**

1. Set custom value to 90 days
2. Close the app completely
3. Reopen the app
4. Navigate to Settings
5. **Expected**:
   - "Custom" chip is selected
   - Text field shows "90"
   - Custom mode is active

✅ **Pass Criteria**: Settings persist correctly across app restarts

---

### Test 6: AI Chat Integration - Date Range Application

**Objective**: Verify AI chat uses the correct date range

**Prerequisites**: 
- AI features enabled
- AI consent granted
- Test records in database

**Test 6.1: 7-day range**

1. Set date range to 7 days in Settings
2. Navigate to AI Chat (or a screen with AI features)
3. Send a message: "What records do I have?"
4. **Expected**:
   - AI response mentions "last 7 days" or similar
5. Check logs for:
   ```
   Creating SpaceContextBuilder with date range
   dateRangeDays: 7
   isCustom: false
   ```

**Test 6.2: 30-day range**

1. Return to Settings
2. Change to 30 days
3. Return to AI Chat
4. Send another message: "Summarize my recent records"
5. **Expected**:
   - AI response mentions "last 30 days"
6. Check logs for:
   ```
   dateRangeDays: 30
   ```

**Test 6.3: Custom 45-day range**

1. Return to Settings
2. Set custom value: 45 days
3. Return to AI Chat
4. Send message: "What's in my history?"
5. **Expected**:
   - AI response mentions "last 45 days"
6. Check logs for:
   ```
   dateRangeDays: 45
   isCustom: true
   ```

**Test 6.4: Verify date range in logs**

Check logs for context assembly:
```
Building space context
dateRangeDays: <value>
dateRangeStart: <ISO date>
dateRangeEnd: <ISO date>
```

Verify:
- Start date is exactly N days before end date
- End date is approximately "now"

✅ **Pass Criteria**: AI responses mention correct date ranges, logs show correct values

---

### Test 7: Large Date Range with Many Records

**Objective**: Verify performance and token budget enforcement with large ranges

**Prerequisites**: 
- 100+ test records in database spanning 3 years
- Run seed script if needed

**Test 7.1: Set 1095-day range**

1. Navigate to Settings
2. Set custom value: 1095 days
3. Apply
4. **Expected**: Success, no lag

**Test 7.2: Build context with large range**

1. Navigate to AI Chat
2. Send a message
3. **Expected**:
   - Response arrives within reasonable time (< 5 seconds)
   - No app crash or freeze
4. Check logs for:
   ```
   Context truncation applied
   dateRangeDays: 1095
   recordsAfterDateFilter: <large number>
   recordsIncluded: <smaller number, typically 10-20>
   tokenBudget: 2000
   tokensUsed: <less than 2000>
   ```

**Test 7.3: Verify token budget enforcement**

1. Check logs for token usage
2. **Expected**:
   - `tokensUsed` never exceeds 2000
   - Records are truncated if necessary
   - Most recent records are prioritized

**Test 7.4: Verify performance**

1. Check logs for context assembly time
2. **Expected**:
   - Context assembly completes in < 200ms
   - No significant lag in UI

✅ **Pass Criteria**: Large date ranges work without performance issues, token budget is enforced

---

### Test 8: Confirmation Messages

**Objective**: Verify confirmation messages appear for all changes

**Test 8.1: Preset changes**

1. Change from 7 → 14 → 30 days
2. **Expected**: Snackbar appears for each change with correct value

**Test 8.2: Custom changes**

1. Set custom value 45
2. **Expected**: Snackbar: "Context date range set to 45 days (custom)"
3. Change to 90
4. **Expected**: Snackbar: "Context date range set to 90 days (custom)"

**Test 8.3: Preset vs Custom distinction**

1. Set preset 14 days
2. **Expected**: Snackbar does NOT say "(custom)"
3. Set custom 14 days
4. **Expected**: Snackbar DOES say "(custom)"

✅ **Pass Criteria**: All changes show appropriate confirmation messages

---

### Test 9: UI/UX Quality

**Objective**: Verify UI is polished and user-friendly

**Test 9.1: Visual feedback**

1. Tap chips and observe selection state
2. **Expected**:
   - Selected chip is clearly highlighted
   - Unselected chips are clearly distinguishable
   - Transitions are smooth

**Test 9.2: Helper text**

1. Activate custom mode
2. **Expected**:
   - Helper text "Up to 3 years" is visible
   - Informational text about token limits is visible and readable
   - Text is not cut off or overlapping

**Test 9.3: Error state**

1. Enter invalid value
2. **Expected**:
   - Error message is clearly visible
   - Text field shows error state (red border/text)
   - Error message is helpful and actionable

**Test 9.4: Loading state**

1. Change date range
2. Observe briefly during save
3. **Expected**:
   - Loading indicator appears (if visible)
   - UI doesn't freeze
   - User can't trigger multiple saves

**Test 9.5: Accessibility**

1. Test with screen reader (if available)
2. Test with large text size
3. **Expected**:
   - All elements are accessible
   - Text is readable at different sizes

✅ **Pass Criteria**: UI is polished, accessible, and user-friendly

---

### Test 10: Edge Cases

**Objective**: Test unusual scenarios

**Test 10.1: Rapid changes**

1. Quickly tap: 7 → 14 → 30 → Custom → 7 → 14
2. **Expected**:
   - No crashes
   - Final selection is correct
   - No duplicate snackbars

**Test 10.2: Custom mode without applying**

1. Tap "Custom"
2. Enter "60"
3. DON'T tap checkmark
4. Tap "14 days" preset
5. **Expected**:
   - Custom value is NOT saved
   - 14 days is selected

**Test 10.3: Network interruption (if applicable)**

1. Disable network
2. Change date range
3. **Expected**:
   - Setting still saves (local only)
   - No network error

**Test 10.4: Low memory scenario**

1. Open many apps
2. Return to Patient App
3. Check Settings
4. **Expected**:
   - Date range setting is still correct
   - No data loss

✅ **Pass Criteria**: Edge cases are handled gracefully

---

## Log Verification Checklist

Throughout testing, verify these log entries appear:

### When reading date range:
```
Read date range setting from repository
dateRangeDays: <value>
isCustom: <true/false>
source: SharedPreferences
```

### When using default:
```
Using default date range
reason: <reason>
defaultDays: 14
```

### When creating DateRange:
```
Creating SpaceContextBuilder with date range
dateRangeDays: <value>
dateRangeStart: <ISO date>
dateRangeEnd: <ISO date>
isCustom: <true/false>
```

### When user changes setting:
```
User updated date range (preset)
dateRangeDays: <value>
previousValue: <old value>
isCustom: false
```

OR

```
User set custom date range
dateRangeDays: <value>
previousValue: <old value>
isCustom: true
```

### When building context:
```
Building space context
dateRangeDays: <value>
recordsAfterDateFilter: <count>
recordsIncluded: <count>
```

### When truncating (large ranges):
```
Context truncation applied
dateRangeDays: <value>
recordsAfterDateFilter: <count>
recordsIncluded: <count>
truncatedCount: <count>
tokenBudget: 2000
tokensUsed: <value>
```

---

## Performance Benchmarks

### Target Metrics

| Operation | Target | Acceptable | Unacceptable |
|-----------|--------|------------|--------------|
| Setting change | < 50ms | < 100ms | > 100ms |
| Context assembly (7 days) | < 50ms | < 100ms | > 200ms |
| Context assembly (1095 days) | < 150ms | < 200ms | > 300ms |
| UI responsiveness | Immediate | < 16ms | > 32ms |

### How to Measure

1. Check logs for operation durations
2. Use Flutter DevTools Performance tab
3. Observe UI smoothness visually

---

## Test Results Template

Use this template to record your test results:

```markdown
## Test Session: [Date/Time]

**Environment**:
- Device: [Emulator/Physical device]
- OS: [Android/iOS version]
- Flutter version: [version]

### Test 1: Preset Options
- [ ] 7 days: PASS / FAIL - Notes:
- [ ] 14 days: PASS / FAIL - Notes:
- [ ] 30 days: PASS / FAIL - Notes:
- [ ] Switching: PASS / FAIL - Notes:

### Test 2: Custom Valid Values
- [ ] 1 day: PASS / FAIL - Notes:
- [ ] 45 days: PASS / FAIL - Notes:
- [ ] 90 days: PASS / FAIL - Notes:
- [ ] 365 days: PASS / FAIL - Notes:
- [ ] 1095 days: PASS / FAIL - Notes:

### Test 3: Custom Invalid Values
- [ ] 0: PASS / FAIL - Notes:
- [ ] -1: PASS / FAIL - Notes:
- [ ] 1096: PASS / FAIL - Notes:
- [ ] "abc": PASS / FAIL - Notes:
- [ ] Empty: PASS / FAIL - Notes:
- [ ] Error clears: PASS / FAIL - Notes:

### Test 4: Mode Switching
- [ ] Preset → Custom: PASS / FAIL - Notes:
- [ ] Custom → Preset: PASS / FAIL - Notes:
- [ ] Custom → Custom: PASS / FAIL - Notes:

### Test 5: Persistence
- [ ] Preset persistence: PASS / FAIL - Notes:
- [ ] Custom persistence: PASS / FAIL - Notes:

### Test 6: AI Integration
- [ ] 7-day range: PASS / FAIL - Notes:
- [ ] 30-day range: PASS / FAIL - Notes:
- [ ] Custom 45-day range: PASS / FAIL - Notes:
- [ ] Logs correct: PASS / FAIL - Notes:

### Test 7: Large Range Performance
- [ ] 1095-day setting: PASS / FAIL - Notes:
- [ ] Context building: PASS / FAIL - Notes:
- [ ] Token budget: PASS / FAIL - Notes:
- [ ] Performance: PASS / FAIL - Notes:

### Test 8: Confirmation Messages
- [ ] Preset messages: PASS / FAIL - Notes:
- [ ] Custom messages: PASS / FAIL - Notes:
- [ ] Distinction: PASS / FAIL - Notes:

### Test 9: UI/UX Quality
- [ ] Visual feedback: PASS / FAIL - Notes:
- [ ] Helper text: PASS / FAIL - Notes:
- [ ] Error state: PASS / FAIL - Notes:
- [ ] Loading state: PASS / FAIL - Notes:
- [ ] Accessibility: PASS / FAIL - Notes:

### Test 10: Edge Cases
- [ ] Rapid changes: PASS / FAIL - Notes:
- [ ] Custom without applying: PASS / FAIL - Notes:
- [ ] Network interruption: PASS / FAIL - Notes:
- [ ] Low memory: PASS / FAIL - Notes:

### Overall Result
- [ ] ALL TESTS PASSED
- [ ] SOME TESTS FAILED (see notes)

**Issues Found**: [List any issues]

**Recommendations**: [Any suggestions]
```

---

## Troubleshooting

### Issue: Setting doesn't persist
**Solution**: Check SharedPreferences is working, verify logs show "Date range setting saved"

### Issue: AI doesn't use correct range
**Solution**: Check logs for "Creating SpaceContextBuilder", verify dateRangeDays matches setting

### Issue: Custom input doesn't work
**Solution**: Check for validation errors in logs, verify input is numeric

### Issue: Performance is slow
**Solution**: Check number of records, verify token budget enforcement, check device resources

### Issue: Logs don't appear
**Solution**: Check logging_config.json, ensure minLevel is "info" or "debug"

---

## Sign-off

After completing all tests:

- [ ] All preset options work correctly
- [ ] All valid custom values are accepted
- [ ] All invalid values are rejected with clear errors
- [ ] Settings persist across app restarts
- [ ] AI chat uses correct date ranges
- [ ] Large date ranges perform acceptably
- [ ] Token budget is enforced
- [ ] Confirmation messages appear correctly
- [ ] UI/UX is polished and user-friendly
- [ ] Logs show correct values throughout

**Tested by**: _______________
**Date**: _______________
**Signature**: _______________

---

## Next Steps

After manual testing is complete:

1. Document any issues found
2. Create bug tickets for failures
3. Update requirements if needed
4. Mark task as complete in tasks.md
5. Proceed to final checkpoint (Task 23)
