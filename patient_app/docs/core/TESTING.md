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
