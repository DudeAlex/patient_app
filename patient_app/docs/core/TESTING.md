Status: ACTIVE

# TESTING

## Principles
- Prefer deterministic, targeted tests; small increments.
- Log every manual/automated run here; include scenario, env, result.
- Use AppLogger; avoid sensitive data in logs.

## What to Run
- Analyzer: `dart analyze`.
- Codegen when models change: `dart run build_runner build --delete-conflicting-outputs`.
- Targeted suites: unit/use-case/adapter/widget as relevant to touched modules.
- Manual checks for UX/backups/auth; record outcomes.

## Recording Results
- Append entries with: date, scope, commands, result, notes.
- Include device/emulator, OS, branch, relevant flags (dart-define).

## Logging Expectations
- Use structured AppLogger messages with context.
- Capture failures with error + stack trace; note follow-ups.

## Manual Scenario Templates
- Sign-in/out; backup/restore success/failure; auto-sync cadence; capture flows; AI consent/offline queue; performance hotspots; accessibility checks.

## Current Log
- (Add entries below)


---

## Pending Manual Testing

### Stage 4: Context Optimization (LLM Context Optimization Feature)
**Status:** PENDING - Awaiting manual testing
**Date Added:** November 27, 2025
**Branch:** llm-context-optimization

#### Test Scenarios Required:

1. **Date Range Filtering**
   - Navigate to Settings → Context Settings
   - Test each date range option (7/14/30 days)
   - Send chat messages with each setting
   - Verify context only includes records within selected date range
   - Check AppLogger output for filtering statistics

2. **Relevance Scoring**
   - Create test records with varying dates:
     - Recent records (1-7 days old)
     - Medium age records (14-30 days old)
     - Old records (60+ days old)
   - View some records multiple times to increase viewCount
   - Send chat message
   - Verify in logs that:
     - Recent records score higher (recency weight: 70%)
     - Frequently accessed records score higher (frequency weight: 30%)
     - Records are sorted by descending relevance score

3. **Token Budget Optimization**
   - Create Space with 50+ records
   - Send chat message
   - Verify in AppLogger output:
     - Token allocation breakdown shows: system (800), context (≤2000), history (1000), response (≥1000)
     - Total tokens ≤ 4800
     - Context stays within allocated budget
     - Response always gets minimum 1000 tokens

4. **Context Stats Display**
   - Send chat message
   - Check AppLogger for context stats:
     - `recordsFiltered`: Total records after date filtering
     - `recordsIncluded`: Records actually included in context (≤20)
     - `tokensEstimated`: Estimated tokens for included records
     - `tokensAvailable`: Available token budget for context
     - `compressionRatio`: Ratio of included/filtered records
     - `assemblyTime`: Time taken to build context (should be <500ms)

5. **Settings Persistence**
   - Change date range in Settings
   - Close and reopen app
   - Verify date range setting persists
   - Send chat message and verify correct date range applied

#### Expected Outcomes:
- Date filtering correctly limits records by date range
- Relevance scoring prioritizes recent and frequently accessed records
- Token budget never exceeds 4800 total
- Response always gets at least 1000 tokens
- Context stats are logged with each chat message
- Settings persist across app restarts

#### How to Test:
1. Run app: `flutter run`
2. Enable verbose logging if needed
3. Follow test scenarios above
4. Check logs: `.\get_crash_logs.ps1` or view console output
5. Document results below

#### Test Results:
- [ ] Date range filtering tested
- [ ] Relevance scoring tested
- [ ] Token budget optimization tested
- [ ] Context stats display tested
- [ ] Settings persistence tested

**Notes:**
- All automated tests (unit, integration, property-based) pass
- Manual testing required to verify end-to-end user experience
- Focus on verifying log output matches expected behavior


---

## Token Savings Measurement (Stage 3 vs Stage 4)

### Objective
Measure and compare token usage between Stage 3 (basic context) and Stage 4 (optimized context) to verify 20-30% token savings goal.

### Measurement Methodology

#### Stage 3 Baseline (Basic Context)
Stage 3 includes:
- Last 10 records (no filtering)
- No relevance scoring
- No token budget optimization
- Total budget: ~4000 tokens

#### Stage 4 Optimized (Context Optimization)
Stage 4 includes:
- Date range filtering (default 14 days)
- Relevance scoring (recency 70% + frequency 30%)
- Token budget allocation (system 800, context 2000, history 1000, response 1000)
- Smart truncation (up to 20 records, highest scores first)
- Total budget: 4800 tokens

### How to Measure

1. **Prepare Test Data**
   - Create a Space with 50+ records
   - Vary record dates (some recent, some old)
   - Vary record lengths (short and long notes)
   - View some records multiple times

2. **Measure Stage 3 (if available)**
   - Checkout commit before Stage 4 implementation
   - Send 10 test chat messages
   - Record token usage from logs for each message
   - Calculate average tokens per message

3. **Measure Stage 4**
   - Checkout current Stage 4 implementation
   - Use same test Space and messages
   - Send same 10 test chat messages
   - Record token usage from logs for each message
   - Calculate average tokens per message

4. **Extract Token Metrics from Logs**
   Look for these log entries:
   ```
   [INFO] Token budget allocated
   Context: {
     "total": 4800,
     "system": 800,
     "context": 2000,
     "history": 1000,
     "response": 1000,
     "contextAvailable": 2000,
     "contextAllocated": 1847  // <-- Actual context tokens used
   }
   ```

   ```
   [INFO] Context truncation complete
   Context: {
     "recordsConsidered": 50,
     "recordsIncluded": 15,
     "tokensUsed": 1847,  // <-- Context tokens used
     "availableTokens": 2000,
     "utilizationPercent": "92.4"
   }
   ```

5. **Calculate Savings**
   ```
   Savings % = ((Stage3_Avg - Stage4_Avg) / Stage3_Avg) × 100
   
   Example:
   Stage 3 Average: 3800 tokens
   Stage 4 Average: 2900 tokens
   Savings: ((3800 - 2900) / 3800) × 100 = 23.7%
   ```

### Expected Results
- **Target:** 20-30% token savings
- **Context tokens:** Stage 4 should use fewer context tokens due to:
  - Date filtering removes old records
  - Relevance scoring prioritizes important records
  - Smart truncation fits within budget
- **Response quality:** Should be maintained or improved despite fewer tokens

### Data Collection Template

#### Stage 3 Measurements
| Message # | Total Tokens | Context Tokens | Records Included | Notes |
|-----------|--------------|----------------|------------------|-------|
| 1         |              |                |                  |       |
| 2         |              |                |                  |       |
| 3         |              |                |                  |       |
| 4         |              |                |                  |       |
| 5         |              |                |                  |       |
| 6         |              |                |                  |       |
| 7         |              |                |                  |       |
| 8         |              |                |                  |       |
| 9         |              |                |                  |       |
| 10        |              |                |                  |       |
| **Average** |            |                |                  |       |

#### Stage 4 Measurements
| Message # | Total Tokens | Context Tokens | Records Included | Date Range | Notes |
|-----------|--------------|----------------|------------------|------------|-------|
| 1         |              |                |                  | 14 days    |       |
| 2         |              |                |                  | 14 days    |       |
| 3         |              |                |                  | 14 days    |       |
| 4         |              |                |                  | 14 days    |       |
| 5         |              |                |                  | 14 days    |       |
| 6         |              |                |                  | 14 days    |       |
| 7         |              |                |                  | 14 days    |       |
| 8         |              |                |                  | 14 days    |       |
| 9         |              |                |                  | 14 days    |       |
| 10        |              |                |                  | 14 days    |       |
| **Average** |            |                |                  |            |       |

#### Savings Calculation
```
Stage 3 Average Context Tokens: _______
Stage 4 Average Context Tokens: _______
Token Savings: _______ tokens
Savings Percentage: _______% 

✅ Target Met (20-30%): [ ] Yes  [ ] No
```

### Additional Metrics to Track
- **Assembly Time:** Context building should be <500ms
- **Records Filtered:** How many records excluded by date range
- **Truncation Frequency:** How often 20-record limit is hit
- **Relevance Score Distribution:** Range of scores for included records

### Notes
- Use consistent test messages across both stages
- Test with realistic Space data (varied dates, lengths, types)
- Run multiple iterations to account for variability
- Document any anomalies or unexpected behavior

**Status:** PENDING - Awaiting measurement execution


---

## Context Metrics Dashboard

### Overview
Context optimization metrics are tracked automatically via AppLogger for every AI chat request. A Context Metrics card is available in the Settings screen to provide an overview.

### Accessing Metrics

**Via Settings Screen:**
1. Open Settings
2. Scroll to "Context Metrics" card
3. View summary of tracked metrics

**Via Application Logs:**
1. Run `.\get_crash_logs.ps1` to retrieve logs
2. Search for log entries with these keys:
   - `Context truncation complete`
   - `Token budget allocated`
   - `Scored records by relevance`
   - `Context filtering complete`

### Metrics Tracked

#### Per-Request Metrics
Each AI chat request logs the following context metrics:

**Context Stats (ContextStats model):**
- `recordsFiltered`: Total records after date range filtering
- `recordsIncluded`: Number of records actually included in context (≤20)
- `tokensEstimated`: Estimated tokens for included records
- `tokensAvailable`: Available token budget for context
- `compressionRatio`: Ratio of included/filtered records
- `assemblyTime`: Time taken to build context (milliseconds)

**Token Allocation (TokenAllocation model):**
- `total`: Total token budget (4800)
- `system`: Tokens for system prompt (800)
- `context`: Tokens allocated for context (≤2000)
- `history`: Tokens for conversation history (1000)
- `response`: Tokens reserved for response (≥1000)

**Truncation Events:**
- `recordsConsidered`: Total records evaluated
- `droppedForBudget`: Records dropped due to token budget
- `droppedForRecordLimit`: Records dropped due to 20-record limit
- `skippedForExceedingBudget`: Individual records exceeding budget
- `truncationReasons`: List of reasons for truncation
- `utilizationPercent`: Percentage of available tokens used

**Relevance Scoring:**
- `inputCount`: Number of records scored
- `topScore`: Highest relevance score
- `bottomScore`: Lowest relevance score
- `avgScore`: Average relevance score
- `medianScore`: Median relevance score
- `top5Scores`: Details of top 5 scoring records

### Analyzing Metrics

#### Average Records per Request
```bash
# Search logs for "recordsIncluded"
grep "recordsIncluded" retrieved_logs/*.log | grep -oP '"recordsIncluded":\s*\K\d+' | awk '{sum+=$1; count++} END {print "Average:", sum/count}'
```

#### Average Token Usage
```bash
# Search logs for "tokensUsed"
grep "tokensUsed" retrieved_logs/*.log | grep -oP '"tokensUsed":\s*\K\d+' | awk '{sum+=$1; count++} END {print "Average:", sum/count}'
```

#### Assembly Time Distribution
```bash
# Search logs for "assemblyTime"
grep "assemblyTime" retrieved_logs/*.log | grep -oP '"assemblyTime":\s*\K\d+' | sort -n
```

#### Truncation Frequency
```bash
# Count truncation events
grep "truncationReasons" retrieved_logs/*.log | wc -l
```

### Performance Targets

**Stage 4 Optimization Goals:**
- Assembly time: < 500ms
- Token utilization: 80-95% of available context budget
- Records included: 10-20 (depending on content)
- Truncation: Only when necessary (>20 records or budget exceeded)
- Compression ratio: 0.2-0.4 (20-40% of filtered records included)

### Troubleshooting

**High Assembly Time (>500ms):**
- Check number of records being filtered
- Verify database query performance
- Review relevance scoring complexity

**Low Token Utilization (<50%):**
- May indicate too few records in date range
- Check if records are very short
- Verify truncation isn't too aggressive

**Frequent Truncation:**
- Expected when >20 records in date range
- Check if token budget is appropriate
- Review record summary lengths

**Low Compression Ratio (<0.1):**
- May indicate date range is too narrow
- Check if most records are being filtered out
- Verify relevance scoring is working

### Example Log Entry

```json
{
  "level": "INFO",
  "message": "Context truncation complete",
  "context": {
    "recordsConsidered": 45,
    "recordsIncluded": 18,
    "droppedForBudget": 2,
    "droppedForRecordLimit": 25,
    "skippedForExceedingBudget": 0,
    "availableTokens": 2000,
    "tokensUsed": 1847,
    "tokensRemaining": 153,
    "maxRecords": 20,
    "truncationReasons": ["Record limit reached (20 records)"],
    "utilizationPercent": "92.4"
  }
}
```

### Dashboard Future Enhancements

Potential improvements for the metrics dashboard:
- Real-time metric aggregation
- Historical trend charts
- Per-space metric breakdown
- Comparison across date ranges
- Export metrics to CSV
- Performance alerts/warnings

**Status:** Basic dashboard implemented, advanced features pending
