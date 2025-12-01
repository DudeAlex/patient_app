# Quick Manual Test Checklist

## Pre-Test Setup
- [ ] App is running on emulator/device
- [ ] Test records exist in database
- [ ] Logging is enabled (check logging_config.json)
- [ ] AI features are enabled

---

## 1. Preset Options (5 min)
- [ ] Select 7 days → Snackbar appears
- [ ] Select 14 days → Snackbar appears
- [ ] Select 30 days → Snackbar appears
- [ ] Switch between presets smoothly

---

## 2. Custom Valid Values (5 min)
- [ ] Tap "Custom" → Text field appears
- [ ] Enter "1" → Accepts
- [ ] Enter "45" → Accepts
- [ ] Enter "90" → Accepts
- [ ] Enter "365" → Accepts
- [ ] Enter "1095" → Accepts

---

## 3. Custom Invalid Values (5 min)
- [ ] Enter "0" → Error: "Must be between 1 and 1095"
- [ ] Enter "-1" → Error shown
- [ ] Enter "1096" → Error shown
- [ ] Enter "abc" → Error: "Please enter a valid number"
- [ ] Enter empty → Error: "Please enter a number"
- [ ] Error clears when valid input entered

---

## 4. Mode Switching (3 min)
- [ ] Preset → Custom → Text field appears with current value
- [ ] Custom → Preset → Text field disappears
- [ ] Custom → Different Custom → Works smoothly

---

## 5. Persistence (3 min)
- [ ] Set 30 days → Close app → Reopen → Still 30 days
- [ ] Set custom 90 → Close app → Reopen → Still custom 90

---

## 6. AI Integration (10 min)
- [ ] Set 7 days → Send AI message → Response mentions "7 days"
- [ ] Set 30 days → Send AI message → Response mentions "30 days"
- [ ] Set custom 45 → Send AI message → Response mentions "45 days"
- [ ] Check logs: dateRangeDays matches setting

---

## 7. Large Range Performance (5 min)
- [ ] Set 1095 days → No lag
- [ ] Send AI message → Response within 5 seconds
- [ ] Check logs: tokensUsed < 2000
- [ ] Check logs: Context assembly < 200ms

---

## 8. Confirmation Messages (2 min)
- [ ] Preset change → Snackbar: "Context date range set to X days"
- [ ] Custom change → Snackbar: "...X days (custom)"
- [ ] Messages are clear and helpful

---

## 9. UI/UX (5 min)
- [ ] Selected chip is clearly highlighted
- [ ] Helper text "Up to 3 years" is visible
- [ ] Informational text about token limits is readable
- [ ] Error messages are clear and helpful
- [ ] No UI glitches or overlaps

---

## 10. Edge Cases (5 min)
- [ ] Rapid changes (7→14→30→Custom→7) → No crashes
- [ ] Custom mode without applying → Value not saved
- [ ] All interactions feel smooth and responsive

---

## Log Verification
- [ ] "Read date range setting from repository" appears
- [ ] "Creating SpaceContextBuilder with date range" appears
- [ ] "User updated date range" / "User set custom date range" appears
- [ ] dateRangeDays values are correct
- [ ] isCustom flag is correct

---

## Performance Check
- [ ] Setting changes: < 100ms
- [ ] Context assembly (7 days): < 100ms
- [ ] Context assembly (1095 days): < 200ms
- [ ] UI remains responsive throughout

---

## Final Sign-off
- [ ] All tests passed
- [ ] No critical issues found
- [ ] Feature is ready for production

**Total Time**: ~45 minutes

**Tested by**: _______________
**Date**: _______________

---

## Quick Issue Report

If you find issues, note them here:

**Issue 1**:
- Test: [Which test]
- Expected: [What should happen]
- Actual: [What actually happened]
- Severity: [Critical/High/Medium/Low]

**Issue 2**:
[Same format]

---

## Notes

[Any additional observations or comments]
