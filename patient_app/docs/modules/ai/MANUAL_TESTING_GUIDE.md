# Manual Testing Guide - LLM Context Optimization (Stage 4)

## Purpose

This guide provides step-by-step instructions for manually testing the Stage 4 context optimization features and collecting key metrics, particularly **token savings**.

## Prerequisites

Before starting, ensure:
- [ ] App is built and running (debug or profile mode)
- [ ] You have access to the app's logs (via AppLogger)
- [ ] You have a Space with at least 30-50 health records
- [ ] Records span different dates (some recent, some older)
- [ ] You have the AI Chat feature enabled

## Test Environment Setup

### 1. Prepare Test Data

Create a test Space with diverse records:

```
Space: "Test Health Records"
Records needed: 50 records minimum

Date distribution:
- 10 records from last 7 days
- 15 records from 8-14 days ago
- 15 records from 15-30 days ago
- 10 records older than 30 days

Record types (mix):
- Blood Pressure readings
- Weight measurements
- Medication logs
- Doctor visit notes
- Lab results
```

**How to create test data:**
1. Open the app
2. Create a new Space called "Test Health Records"
3. Add records with varying dates (you can manually adjust dates if needed)
4. Add some notes to records (varying lengths)
5. View some records multiple times to increase viewCount

### 2. Enable Detailed Logging

Ensure logging is set to capture context metrics:

1. Check `assets/config/logging_config.json`:
   ```json
   {
     "minLevel": "info",
     "consoleEnabled": true,
     "fileEnabled": true
   }
   ```

2. Restart the app to apply logging config

---

## Test Scenarios

### Scenario 1: Baseline Token Usage (Stage 3 Behavior)

**Goal:** Establish baseline token usage before Stage 4 optimizations

**Steps:**

1. **Clear any existing chat history**
   - Go to AI Chat screen
   - Start a new conversation

2. **Send a simple query**
   - Message: "What are my recent blood pressure readings?"
   - Wait for response

3. **Capture baseline metrics from logs**
   - Look for log entries with category: `ai_chat` or `context`
   - Record the following:
     ```
     Baseline Metrics (Stage 3):
     - Total records in Space: ___
     - Records included in context: ___
     - Estimated tokens used: ___
     - Context assembly time: ___ ms
     - Response quality: (1-5 rating) ___
     ```

4. **Repeat with different queries** (3-5 queries total)
   - "Summarize my health trends this month"
   - "What medications am I currently taking?"
   - "Show me my weight changes"
   - "Any concerning patterns in my vitals?"

5. **Calculate average baseline**
   ```
   Average records included: ___
   Average tokens used: ___
   Average assembly time: ___ ms
   ```

---

### Scenario 2: Stage 4 Token Optimization (14-day filter)

**Goal:** Measure token savings with Stage 4 date range filtering

**Steps:**

1. **Configure date range to 14 days**
   - Go to Settings
   - Find "Context Settings" section
   - Select "Last 14 days" from dropdown
   - Save settings

2. **Clear chat history and start fresh**

3. **Send the SAME queries from Scenario 1**
   - Use identical queries to ensure fair comparison
   - "What are my recent blood pressure readings?"
   - "Summarize my health trends this month"
   - "What medications am I currently taking?"
   - "Show me my weight changes"
   - "Any concerning patterns in my vitals?"

4. **Capture Stage 4 metrics from logs**
   - Look for context stats in logs
   - Record for each query:
     ```
     Stage 4 Metrics (14-day filter):
     Query 1:
     - Records filtered (total available): ___
     - Records included in context: ___
     - Estimated tokens used: ___
     - Context assembly time: ___ ms
     - Response quality: (1-5 rating) ___
     
     Query 2:
     [repeat for each query]
     ```

5. **Calculate Stage 4 averages**
   ```
   Average records included: ___
   Average tokens used: ___
   Average assembly time: ___ ms
   Average response quality: ___
   ```

6. **Calculate token savings**
   ```
   Token Savings = ((Baseline - Stage4) / Baseline) × 100%
   
   Token Savings: ____%
   Target: 20-30% savings
   ```

---

### Scenario 3: Stage 4 with 7-day filter

**Goal:** Test more aggressive filtering

**Steps:**

1. **Change date range to 7 days**
   - Settings → Context Settings → "Last 7 days"

2. **Send 2-3 test queries**

3. **Record metrics**
   ```
   Stage 4 (7-day filter):
   - Average records included: ___
   - Average tokens used: ___
   - Token savings vs baseline: ____%
   ```

---

### Scenario 4: Stage 4 with 30-day filter

**Goal:** Test with wider date range

**Steps:**

1. **Change date range to 30 days**
   - Settings → Context Settings → "Last 30 days"

2. **Send 2-3 test queries**

3. **Record metrics**
   ```
   Stage 4 (30-day filter):
   - Average records included: ___
   - Average tokens used: ___
   - Token savings vs baseline: ____%
   ```

---

### Scenario 5: Relevance Scoring Validation

**Goal:** Verify that most relevant records are prioritized

**Steps:**

1. **Set date range to 14 days**

2. **View specific records multiple times**
   - Open 3-4 recent blood pressure records
   - View each 3-5 times to increase viewCount

3. **Send query about blood pressure**
   - "What's my blood pressure trend?"

4. **Check logs for relevance scores**
   - Look for `RecordRelevanceScorer` log entries
   - Verify that frequently viewed records have higher scores
   - Verify that recent records have higher scores than older ones

5. **Validate scoring formula**
   ```
   Expected behavior:
   - Recent + frequently viewed = highest scores
   - Recent + rarely viewed = medium-high scores
   - Old + frequently viewed = medium scores
   - Old + rarely viewed = lowest scores
   ```

---

### Scenario 6: Token Budget Enforcement

**Goal:** Verify token budget is respected

**Steps:**

1. **Create a Space with 100+ records** (if possible)

2. **Set date range to 30 days** (to include many records)

3. **Send a broad query**
   - "Give me a complete health summary"

4. **Check logs for token budget**
   - Look for `TokenBudgetAllocator` entries
   - Verify allocation:
     ```
     Expected allocation:
     - System: ~800 tokens
     - Context: ~2000 tokens
     - History: ~1000 tokens
     - Response: ~1000 tokens (minimum)
     - Total: ≤ 4800 tokens
     ```

5. **Verify truncation occurred**
   - Look for `ContextTruncationStrategy` log entries
   - Confirm that records were truncated to fit budget
   - Confirm that lowest-scoring records were removed first

---

### Scenario 7: Context Stats Display

**Goal:** Verify context metrics dashboard

**Steps:**

1. **Send 5-10 chat messages** with varying queries

2. **Go to Settings screen**

3. **Find "Context Metrics" card**

4. **Verify displayed metrics**
   - [ ] Average records included per request
   - [ ] Average token usage per request
   - [ ] Average context assembly time
   - [ ] Truncation frequency (if applicable)

5. **Validate accuracy**
   - Compare dashboard numbers with log entries
   - Ensure metrics are updating correctly

---

### Scenario 8: User Feedback System

**Goal:** Test feedback collection

**Steps:**

1. **Send a chat message**

2. **Provide feedback on response**
   - Look for thumbs up/down buttons on AI response
   - Click thumbs up for good responses
   - Click thumbs down for poor responses

3. **Verify feedback is saved**
   - Check logs for feedback persistence
   - Look for `MessageFeedback` entries in database logs

4. **Send multiple messages and provide varied feedback**
   - Test both positive and negative feedback
   - Verify each feedback is recorded correctly

---

### Scenario 9: Space Switching

**Goal:** Verify context isolation between Spaces

**Steps:**

1. **Create two Spaces with different records**
   - Space A: "Cardio Health" (blood pressure, heart rate)
   - Space B: "Nutrition" (weight, meals, calories)

2. **Switch to Space A**
   - Send query: "What's my blood pressure trend?"
   - Note the records referenced in response

3. **Switch to Space B**
   - Send query: "What's my blood pressure trend?"
   - Verify response says "no blood pressure records" or similar

4. **Check logs**
   - Verify context only includes records from active Space
   - Confirm Space isolation is working

---

### Scenario 10: Edge Cases

**Goal:** Test boundary conditions

**Test cases:**

1. **Empty Space**
   - Create new Space with 0 records
   - Send chat message
   - Verify graceful handling (no crash)

2. **Space with 1 record**
   - Create Space with single record
   - Send query
   - Verify context includes that record

3. **All records outside date range**
   - Set date range to "Last 7 days"
   - Ensure all records are older than 7 days
   - Send query
   - Verify response acknowledges limited context

4. **Very long record notes**
   - Create record with 1000+ character note
   - Verify truncation to 100 chars in summary
   - Check token estimation

---

## Metrics Collection Template

Use this template to record all metrics:

```markdown
# Stage 4 Manual Testing Results

## Test Environment
- Date: ___________
- App Version: ___________
- Device: ___________
- Total Records in Test Space: ___

## Baseline (Stage 3)
| Query | Records Included | Tokens Used | Assembly Time (ms) | Quality (1-5) |
|-------|------------------|-------------|-------------------|---------------|
| 1     |                  |             |                   |               |
| 2     |                  |             |                   |               |
| 3     |                  |             |                   |               |
| 4     |                  |             |                   |               |
| 5     |                  |             |                   |               |
| **Avg** |              |             |                   |               |

## Stage 4 (14-day filter)
| Query | Records Filtered | Records Included | Tokens Used | Assembly Time (ms) | Quality (1-5) |
|-------|------------------|------------------|-------------|-------------------|---------------|
| 1     |                  |                  |             |                   |               |
| 2     |                  |                  |             |                   |               |
| 3     |                  |                  |             |                   |               |
| 4     |                  |                  |             |                   |               |
| 5     |                  |                  |             |                   |               |
| **Avg** |              |                  |             |                   |               |

## Token Savings Calculation
```
Baseline Average Tokens: ___
Stage 4 Average Tokens: ___
Token Savings: ((Baseline - Stage4) / Baseline) × 100% = ____%

✅ Target Met (20-30%): YES / NO
```

## Stage 4 (7-day filter)
| Metric | Value |
|--------|-------|
| Avg Records Included | ___ |
| Avg Tokens Used | ___ |
| Token Savings vs Baseline | ___% |

## Stage 4 (30-day filter)
| Metric | Value |
|--------|-------|
| Avg Records Included | ___ |
| Avg Tokens Used | ___ |
| Token Savings vs Baseline | ___% |

## Relevance Scoring Validation
- [ ] Frequently viewed records scored higher
- [ ] Recent records scored higher than old records
- [ ] Scoring formula working as expected
- Notes: ___________

## Token Budget Enforcement
- [ ] Total tokens ≤ 4800
- [ ] Response reservation ≥ 1000 tokens
- [ ] Truncation occurred when needed
- [ ] Lowest-scoring records removed first
- Notes: ___________

## Context Metrics Dashboard
- [ ] Displays average records included
- [ ] Displays average token usage
- [ ] Displays average assembly time
- [ ] Displays truncation frequency
- [ ] Metrics match log data
- Notes: ___________

## User Feedback System
- [ ] Thumbs up/down buttons visible
- [ ] Feedback saves correctly
- [ ] Feedback appears in logs
- Notes: ___________

## Space Isolation
- [ ] Context only includes active Space records
- [ ] Switching Spaces changes context
- [ ] No cross-Space contamination
- Notes: ___________

## Edge Cases
- [ ] Empty Space handled gracefully
- [ ] Single record Space works
- [ ] All records outside date range handled
- [ ] Long notes truncated correctly
- Notes: ___________

## Overall Assessment

### Token Savings Achievement
- **Target:** 20-30% savings
- **Actual:** ____%
- **Status:** ✅ Met / ❌ Not Met

### Response Quality
- **Baseline Quality:** ___ / 5
- **Stage 4 Quality:** ___ / 5
- **Change:** +/- ___

### Performance
- **Baseline Assembly Time:** ___ ms
- **Stage 4 Assembly Time:** ___ ms
- **Change:** +/- ___ ms

### Issues Found
1. ___________
2. ___________
3. ___________

### Recommendations
1. ___________
2. ___________
3. ___________

## Conclusion

Stage 4 context optimization is:
- [ ] Ready for production
- [ ] Needs minor fixes
- [ ] Needs major fixes

Signature: ___________ Date: ___________
```

---

## How to Extract Metrics from Logs

### Finding Token Usage

Look for log entries like:
```
[INFO] Context assembled
  category: ai_chat
  tokensEstimated: 2450
  recordsIncluded: 15
  assemblyTime: 125
```

### Finding Relevance Scores

Look for log entries like:
```
[INFO] Record scored
  category: context
  recordId: abc123
  recencyScore: 8.5
  frequencyScore: 6.2
  totalScore: 7.81
```

### Finding Token Budget

Look for log entries like:
```
[INFO] Token budget allocated
  category: context
  system: 800
  context: 2000
  history: 1000
  response: 1000
  total: 4800
```

### Finding Truncation Events

Look for log entries like:
```
[WARN] Context truncated
  category: context
  originalRecords: 35
  includedRecords: 18
  removedRecords: 17
  reason: token_budget_exceeded
```

---

## Tips for Accurate Testing

1. **Use consistent queries** - Use the same queries for baseline and Stage 4 to ensure fair comparison

2. **Clear chat history** - Start fresh for each scenario to avoid history affecting context

3. **Wait for responses** - Don't send multiple messages rapidly; wait for each response

4. **Check logs immediately** - Review logs right after each query while context is fresh

5. **Take screenshots** - Capture context metrics dashboard and any interesting log entries

6. **Test multiple times** - Run each scenario 2-3 times to ensure consistency

7. **Document anomalies** - Note any unexpected behavior or errors

8. **Compare response quality** - Don't just measure tokens; ensure responses are still helpful

---

## Troubleshooting

### Can't find log entries
- Check `assets/config/logging_config.json` - ensure `fileEnabled: true`
- Check console output if running in debug mode
- Use `.\get_crash_logs.ps1` to retrieve log files

### Metrics don't match expectations
- Verify test data setup (record counts, dates)
- Check that date range setting is applied
- Restart app after changing settings

### Context metrics dashboard not showing
- Ensure you've sent at least one chat message
- Check that Settings screen includes the Context Metrics card
- Verify metrics are being calculated and stored

### Feedback buttons not visible
- Check AI Chat screen UI
- Verify MessageFeedback enum is properly imported
- Check for any UI rendering errors in logs

---

## Next Steps After Testing

1. **Document results** - Fill out the metrics template completely

2. **Update Task 46** - Mark token savings measurement complete with actual percentages

3. **Update Task 49** - Complete Stage 4 checkpoint with test results

4. **Report issues** - If any bugs found, document them clearly

5. **Proceed to Task 50** - Update documentation with findings

---

## Questions or Issues?

If you encounter any problems during testing:
- Check KNOWN_ISSUES_AND_FIXES.md for common issues
- Review logs for error messages
- Document the issue with steps to reproduce
- Ask for help if needed

---

**Last Updated:** November 28, 2024
**Status:** Active - Use for Stage 4 manual testing and metrics collection
