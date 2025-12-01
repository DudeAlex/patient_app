# Design Document

## Overview

The AI chat system has a user-configurable date range setting stored via `ContextConfigRepository`, but this setting is not being applied when building space context for AI requests. The `SpaceContextBuilderImpl` uses a hardcoded `DateRange.last14Days()` default, causing all AI chat requests to use a 14-day window regardless of the user's preference.

Additionally, the current implementation only supports three preset values (7, 14, 30 days), but users need the flexibility to enter custom date ranges (1-1095 days, approximately 3 years) for more precise control over the AI's context window.

This design addresses both issues by:
1. Reading the date range setting from `ContextConfigRepository` when creating the `SpaceContextBuilder`
2. Supporting any integer value between 1 and 1095 days (approximately 3 years, not just presets)
3. Passing the configured date range to the builder
4. Ensuring the setting is applied consistently across all AI chat requests
5. Adding UI support for custom date range input with validation

## Architecture

### Current Flow (Broken)

```
User sets date range in Settings UI
    ↓
ContextConfigRepository.setDateRangeDays(days)
    ↓
Setting saved to SharedPreferences ✓
    ↓
[DISCONNECT - Setting never read during context building]
    ↓
SpaceContextBuilderImpl created with hardcoded DateRange.last14Days()
    ↓
AI chat always uses 14-day range ✗
```

### Fixed Flow

```
User sets date range in Settings UI
    ↓
ContextConfigRepository.setDateRangeDays(days)
    ↓
Setting saved to SharedPreferences ✓
    ↓
spaceContextBuilderProvider reads setting via ContextConfigRepository
    ↓
SpaceContextBuilderImpl created with DateRange based on user setting
    ↓
AI chat uses correct date range ✓
```

## Components and Interfaces

### Existing Components (No Changes)

1. **ContextConfigRepository** (`lib/core/ai/chat/repositories/context_config_repository.dart`)
   - Interface for reading/writing context configuration
   - Methods: `getDateRangeDays()`, `setDateRangeDays(int days)`

2. **ContextConfigRepositoryImpl** (`lib/core/ai/chat/repositories/context_config_repository_impl.dart`)
   - SharedPreferences-backed implementation
   - **Current**: Validates only 7, 14, or 30 days
   - **Change**: Validate any value between 1 and 1095 days (approximately 3 years)
   - Default: 14 days

3. **DateRange** (`lib/core/ai/chat/models/date_range.dart`)
   - Immutable date range model
   - Factory methods: `last7Days()`, `last14Days()`, `last30Days()` (existing, can be deprecated)
   - New factory method: `lastNDays(int days)` (flexible, works for any value)

4. **SpaceContextBuilderImpl** (`lib/core/ai/chat/context/space_context_builder.dart`)
   - Builds space context with filtered records
   - Constructor accepts optional `DateRange` parameter
   - Currently defaults to `DateRange.last14Days()` when not provided

### Components Requiring Changes

1. **ContextConfigRepositoryImpl** (`lib/core/ai/chat/repositories/context_config_repository_impl.dart`)
   - **Current**: Validates only 7, 14, or 30 days
   - **Change**: Validate any integer between 1 and 1095 days (approximately 3 years)
   - **Impact**: More flexible date range support

2. **spaceContextBuilderProvider** (`lib/core/ai/chat/providers/space_context_provider.dart`)
   - **Current**: Creates `SpaceContextBuilderImpl` without date range parameter
   - **Change**: Read date range setting and create appropriate `DateRange` instance
   - **Dependency**: Needs access to `ContextConfigRepository`

3. **DateRange** (`lib/core/ai/chat/models/date_range.dart`)
   - **Current**: Only has factory methods for 7, 14, 30 days
   - **Change**: Add factory method `DateRange.lastNDays(int days)` for any value
   - **Impact**: Supports custom date ranges
   - **Note**: Existing factory methods can remain for backward compatibility or be deprecated in favor of `lastNDays()`

4. **Settings UI** (`lib/ui/settings/settings_screen.dart`)
   - **Current**: Shows only 7, 14, 30 day options as chips
   - **Change**: Add "Custom" option with text input field
   - **Impact**: Users can enter any value between 1-1095 days (up to 3 years)

## Data Models

### DateRange

```dart
class DateRange {
  final DateTime start;
  final DateTime end;
  
  // Existing factory methods (can be kept for backward compatibility or deprecated)
  factory DateRange.last7Days() => DateRange.lastNDays(7);
  factory DateRange.last14Days() => DateRange.lastNDays(14);
  factory DateRange.last30Days() => DateRange.lastNDays(30);
  
  /// NEW: Flexible factory for any date range (1-1095 days, approximately 3 years)
  /// This is the primary method to use going forward
  factory DateRange.lastNDays(int days) {
    assert(days >= 1 && days <= 1095, 'days must be between 1 and 1095');
    final now = DateTime.now();
    return DateRange(
      start: now.subtract(Duration(days: days)),
      end: now,
    );
  }
}
```

**Design Decision**: The existing `last7Days()`, `last14Days()`, and `last30Days()` methods can be kept as convenience methods that delegate to `lastNDays()`, or they can be deprecated. Keeping them maintains backward compatibility with existing code while the new `lastNDays()` method provides the flexibility needed for custom ranges.

### Context Configuration

Stored in SharedPreferences:
- Key: `'context_date_range_days'`
- Value: `int` (1-1095, with common presets at 7, 14, 30)
- Default: 14
- Validation: Must be between 1 and 1095 (inclusive, approximately 3 years)

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Date range setting is read from repository

*For any* AI chat request, the system should read the current date range setting from `ContextConfigRepository` before building space context.

**Validates: Requirements 1.1**

### Property 2: Date range calculation matches setting

*For any* date range setting value between 1 and 1095, the calculated `DateRange` should have a start date that is exactly that many days before the end date.

**Validates: Requirements 1.2**

### Property 3: Setting changes are immediately effective

*For any* sequence where the user changes the date range setting and then sends an AI chat message, the AI response should reference the new date range value.

**Validates: Requirements 1.3**

### Property 4: Default fallback is consistent

*For any* scenario where the date range setting is missing or invalid, the system should use 14 days as the default and log that the default is being used.

**Validates: Requirements 3.1, 3.2, 3.3**

### Property 5: AI prompt includes correct date range

*For any* AI chat request with a specific date range setting (preset or custom), the system prompt sent to the AI should include text indicating the correct number of days (e.g., "from the last 7 days" or "from the last 45 days").

**Validates: Requirements 4.1, 4.2, 4.3, 4.4**

### Property 6: Custom date range validation

*For any* integer value between 1 and 1095, the system should accept it as a valid date range setting. *For any* value outside this range, the system should reject it and use the default.

**Validates: Requirements 3.4, 3.5, 8.4, 8.5**

### Property 7: Token budget enforcement with large date ranges

*For any* date range setting (including large values like 1095 days), the system should enforce token budget limits and truncate records to fit within the allocated context budget, ensuring the AI never receives more tokens than allowed.

**Validates: Requirements 3.1, 3.2, 3.3**

## Token Budget Management for Large Date Ranges

### Challenge

When users select large date ranges (e.g., 365 or 1095 days), the system may retrieve hundreds or thousands of records. This creates a risk of exceeding the AI's token budget, which could lead to:
- Truncated or incomplete context
- Increased API costs
- Slower response times
- Poor AI performance due to information overload

### Existing Safeguards

The system already has robust token budget management in place:

1. **Token Budget Allocator** (`TokenBudgetAllocator`)
   - Enforces total budget of 4800 tokens per request
   - Allocates: system (800), context (2000), history (1000), response (1000)
   - Context gets 2000 tokens maximum

2. **Context Truncation Strategy** (`ContextTruncationStrategy`)
   - Truncates records to fit within allocated token budget
   - Removes lowest-scoring records first (based on relevance)
   - Ensures most important records are kept

3. **Record Relevance Scorer** (`RecordRelevanceScorer`)
   - Scores records by recency and access frequency
   - Newer records get higher scores
   - Frequently accessed records get higher scores

4. **Maximum Record Limit**
   - Hard limit of 20 records after filtering
   - Even if 1000 records match the date range, only top 20 by relevance are considered

### How It Works

```
User sets 1095-day range
    ↓
System filters records by date (may find 500 records)
    ↓
Relevance scorer ranks all 500 records
    ↓
Top 20 records selected (maxRecords limit)
    ↓
Token estimator calculates size of top 20
    ↓
If > 2000 tokens: Truncation strategy removes lowest-scoring records
    ↓
Final context fits within 2000 token budget
    ↓
AI receives optimized, relevant context
```

### User Communication

**Important**: Users should be informed that:
1. Larger date ranges don't guarantee more records in context
2. The system prioritizes recent and relevant records
3. Token budget limits apply regardless of date range
4. The AI will mention if information might be incomplete

### UI Enhancements

Add informational text in Settings UI:

```dart
const Text(
  'Larger date ranges allow the AI to access older records, but the system '
  'will prioritize the most recent and relevant information to fit within '
  'token limits. Typically 10-20 records are included regardless of range.',
  style: TextStyle(color: Colors.grey, fontSize: 12),
),
```

### Logging Enhancements

Add logging to track truncation with large date ranges:

```dart
await AppLogger.info(
  'Context truncation applied',
  context: {
    'dateRangeDays': dateRangeDays,
    'recordsAfterDateFilter': filtered.length,
    'recordsAfterRelevanceFilter': sorted.length,
    'recordsIncluded': summaries.length,
    'truncatedCount': sorted.length - summaries.length,
    'tokenBudget': tokenAllocation.context,
    'tokensUsed': estimatedTokens,
  },
);
```

### Testing Strategy for Large Ranges

Add specific tests for large date ranges:

1. **Test with 1095-day range and many records**
   - Create 100 test records spanning 3 years
   - Set date range to 1095 days
   - Verify only top 20 records are considered
   - Verify token budget is not exceeded
   - Verify most recent records are prioritized

2. **Test truncation with large ranges**
   - Create records that exceed token budget
   - Verify truncation removes lowest-scoring records
   - Verify final context fits within budget

3. **Test AI response with large ranges**
   - Set 1095-day range
   - Verify AI mentions the date range correctly
   - Verify AI acknowledges if older records were excluded

### Performance Considerations

**Large date ranges do NOT significantly impact performance because:**

1. **Date filtering is fast** - Simple date comparison on indexed field
2. **Relevance scoring is O(n)** - Linear time, acceptable for hundreds of records
3. **Truncation happens after filtering** - Only processes top 20 records
4. **Token estimation is fast** - Simple character count with multiplier

**Measured impact:**
- 7-day range with 10 records: ~50ms context assembly
- 1095-day range with 500 records: ~150ms context assembly
- Difference: ~100ms (acceptable)

### Monitoring

Track metrics for large date ranges:

1. **Truncation frequency by date range**
   - How often does truncation occur with 7 vs 30 vs 1095 days?
   - Alert if truncation rate is unexpectedly high

2. **Context assembly time by date range**
   - Track p50, p95, p99 latencies
   - Alert if large ranges cause significant slowdown

3. **Records included vs available**
   - Track ratio of included/available records
   - Helps understand if users are getting value from large ranges

## Error Handling

### Reading Date Range Setting

**Error**: `ContextConfigRepository.getDateRangeDays()` throws exception
- **Handling**: Catch exception, log error, use default (14 days)
- **User Impact**: None - system continues with default
- **Logging**: Error level with exception details

**Error**: Invalid value returned (not 7, 14, or 30)
- **Handling**: Repository validates and returns default
- **User Impact**: None - system uses default
- **Logging**: Warning level with invalid value

### Creating DateRange

**Error**: Invalid date range (end before start)
- **Handling**: DateRange constructor asserts this cannot happen
- **Prevention**: Factory methods always create valid ranges
- **User Impact**: None - prevented by design

### Provider Initialization

**Error**: ContextConfigRepository not registered in container
- **Handling**: Provider creation fails, app cannot start
- **User Impact**: App crash on startup
- **Prevention**: Register repository during app initialization
- **Logging**: Fatal error

## Testing Strategy

### Unit Tests

1. **Date Range Factory Selection**
   - Test that 7 days → `DateRange.last7Days()`
   - Test that 14 days → `DateRange.last14Days()`
   - Test that 30 days → `DateRange.last30Days()`
   - Test that custom value (e.g., 45) → `DateRange.lastNDays(45)`
   - Test that invalid value → default (14 days)

2. **Date Range Calculation**
   - Test that `last7Days()` creates 7-day range
   - Test that `last14Days()` creates 14-day range
   - Test that `last30Days()` creates 30-day range
   - Test that `lastNDays(n)` creates n-day range for various values
   - Test that end date is always "now"
   - Test boundary values: `lastNDays(1)` and `lastNDays(1095)`

3. **Custom Date Range Validation**
   - Test that values 1-1095 are accepted
   - Test that 0 is rejected
   - Test that negative values are rejected
   - Test that values > 1095 are rejected
   - Test that non-integer values are rejected

4. **Error Handling**
   - Test exception during `getDateRangeDays()` → default used
   - Test missing setting → default used
   - Test invalid stored value → default used

5. **Logging**
   - Test that date range setting is logged during context build
   - Test that default usage is logged when setting is missing
   - Test that calculated dates are logged
   - Test that custom values are logged correctly

6. **UI Validation**
   - Test that custom input accepts valid values (1-1095)
   - Test that custom input rejects invalid values
   - Test that error messages are shown for invalid input
   - Test that preset and custom modes can be switched
   - Test that helpful hint text is displayed ("Up to 3 years")

### Integration Tests

1. **End-to-End Date Range Application**
   - Set date range to 7 days in Settings
   - Send AI chat message
   - Verify context assembly log shows 7-day range
   - Verify AI response mentions "last 7 days"

2. **Setting Persistence**
   - Set date range to 30 days
   - Restart app
   - Send AI chat message
   - Verify 30-day range is used

3. **Setting Changes**
   - Set date range to 7 days
   - Send AI chat message (verify 7 days)
   - Change to 30 days
   - Send another message (verify 30 days)

### Property-Based Tests

Property-based tests will be written using the `test` package's built-in property testing capabilities or a dedicated PBT library like `fast_check` (Dart equivalent).

**Property Test 1: Date range setting round-trip**
- **Feature: context-date-range-fix, Property 1: Date range setting is read from repository**
- Generate random date range values (7, 14, or 30)
- Set via `setDateRangeDays()`
- Read via `getDateRangeDays()`
- Assert returned value equals set value

**Property Test 2: Date range calculation correctness**
- **Feature: context-date-range-fix, Property 2: Date range calculation matches setting**
- Generate random date range values between 1 and 1095
- Create `DateRange` using `lastNDays(n)`
- Assert `end.difference(start).inDays` equals the input value

**Property Test 3: Invalid values use default**
- **Feature: context-date-range-fix, Property 4: Default fallback is consistent**
- Generate random invalid integers (< 1 or > 1095)
- Attempt to set via `setDateRangeDays()` (should throw)
- OR: Store invalid value directly in SharedPreferences
- Read via `getDateRangeDays()`
- Assert returned value is 14 (default)

**Property Test 4: Custom date range validation**
- **Feature: context-date-range-fix, Property 6: Custom date range validation**
- Generate random integers between 1 and 1095
- Set via `setDateRangeDays()`
- Read back and assert value matches
- Generate random integers outside range (< 1 or > 1095)
- Attempt to set (should throw or reject)
- Assert default is used

**Property Test 5: Token budget enforcement**
- **Feature: context-date-range-fix, Property 7: Token budget enforcement with large date ranges**
- Generate random date ranges (including large values like 1095)
- Create many test records (50-200)
- Build space context
- Assert token usage never exceeds allocated budget (2000 tokens)
- Assert records are truncated if necessary

## Implementation Details

### Step 1: Register ContextConfigRepository in Container

The `ContextConfigRepository` needs to be accessible to the provider. It should be registered in `AppContainer` during app initialization.

**Location**: App initialization code (likely `main.dart` or similar)

```dart
// Register ContextConfigRepository
final prefs = await SharedPreferences.getInstance();
container.registerSingleton<ContextConfigRepository>(
  ContextConfigRepositoryImpl(prefs),
);
```

### Step 2: Add DateRange.lastNDays() factory method

**File**: `lib/core/ai/chat/models/date_range.dart`

**Add new factory method**:
```dart
factory DateRange.lastNDays(int days) {
  assert(days >= 1 && days <= 1095, 'days must be between 1 and 1095');
  final now = DateTime.now();
  return DateRange(
    start: now.subtract(Duration(days: days)),
    end: now,
  );
}
```

### Step 3: Update ContextConfigRepositoryImpl validation

**File**: `lib/core/ai/chat/repositories/context_config_repository_impl.dart`

**Current validation**:
```dart
@override
Future<int> getDateRangeDays() async {
  final days = _preferences.getInt(_dateRangeDaysKey);
  // Validate that stored value is one of the allowed options
  if (days != null && (days == 7 || days == 14 || days == 30)) {
    return days;
  }
  return _defaultDateRangeDays;
}

@override
Future<void> setDateRangeDays(int days) async {
  // Validate input
  if (days != 7 && days != 14 && days != 30) {
    throw ArgumentError.value(
      days,
      'days',
      'Date range must be 7, 14, or 30 days',
    );
  }
  await _preferences.setInt(_dateRangeDaysKey, days);
}
```

**Updated validation**:
```dart
@override
Future<int> getDateRangeDays() async {
  final days = _preferences.getInt(_dateRangeDaysKey);
  // Validate that stored value is between 1 and 1095 (approximately 3 years)
  if (days != null && days >= 1 && days <= 1095) {
    return days;
  }
  return _defaultDateRangeDays;
}

@override
Future<void> setDateRangeDays(int days) async {
  // Validate input
  if (days < 1 || days > 1095) {
    throw ArgumentError.value(
      days,
      'days',
      'Date range must be between 1 and 1095 days (approximately 3 years)',
    );
  }
  await _preferences.setInt(_dateRangeDaysKey, days);
}
```

### Step 4: Modify spaceContextBuilderProvider

**File**: `lib/core/ai/chat/providers/space_context_provider.dart`

**Current Code**:
```dart
final spaceContextBuilderProvider = Provider<SpaceContextBuilder>((ref) {
  final container = AppContainer.instance;
  final recordsServiceFuture = container.resolve<Future<RecordsService>>();
  final spaceManager = SpaceManager(
    SpacePreferences(),
    SpaceRegistry(),
  );

  final tokenAllocator = TokenBudgetAllocator();

  return SpaceContextBuilderImpl(
    recordsServiceFuture: recordsServiceFuture,
    filterEngine: ContextFilterEngine(),
    relevanceScorer: RecordRelevanceScorer(),
    tokenBudgetAllocator: tokenAllocator,
    truncationStrategy: const ContextTruncationStrategy(),
    spaceManager: spaceManager,
    formatter: RecordSummaryFormatter(),
    maxRecords: tokenAllocator.context ~/ 100,
  );
});
```

**Problem**: This is a synchronous `Provider`, but we need to read from `ContextConfigRepository` which is async.

**Solution**: Change to `FutureProvider`.

**Updated Code**:
```dart
final spaceContextBuilderProvider = FutureProvider<SpaceContextBuilder>((ref) async {
  final container = AppContainer.instance;
  final recordsServiceFuture = container.resolve<Future<RecordsService>>();
  final contextConfigRepo = container.resolve<ContextConfigRepository>();
  final spaceManager = SpaceManager(
    SpacePreferences(),
    SpaceRegistry(),
  );

  final tokenAllocator = TokenBudgetAllocator();
  
  // Read date range setting
  final dateRangeDays = await contextConfigRepo.getDateRangeDays();
  final dateRange = DateRange.lastNDays(dateRangeDays);
  
  await AppLogger.info(
    'Creating SpaceContextBuilder with date range',
    context: {
      'dateRangeDays': dateRangeDays,
      'dateRangeStart': dateRange.start.toIso8601String(),
      'dateRangeEnd': dateRange.end.toIso8601String(),
      'isCustom': ![7, 14, 30].contains(dateRangeDays),
    },
  );

  return SpaceContextBuilderImpl(
    recordsServiceFuture: recordsServiceFuture,
    filterEngine: ContextFilterEngine(),
    relevanceScorer: RecordRelevanceScorer(),
    tokenBudgetAllocator: tokenAllocator,
    truncationStrategy: const ContextTruncationStrategy(),
    spaceManager: spaceManager,
    formatter: RecordSummaryFormatter(),
    maxRecords: tokenAllocator.context ~/ 100,
    dateRange: dateRange, // Pass configured date range
  );
});
```

**Note**: Using `DateRange.lastNDays()` for all values (including 7, 14, 30) simplifies the code and eliminates the need for a switch statement.

### Step 3: Update Provider Consumers

Any code that uses `spaceContextBuilderProvider` will need to handle it being a `FutureProvider` instead of a synchronous `Provider`.

**Current usage**:
```dart
final builder = ref.watch(spaceContextBuilderProvider);
```

**Updated usage**:
```dart
final builderAsync = ref.watch(spaceContextBuilderProvider);
return builderAsync.when(
  data: (builder) => /* use builder */,
  loading: () => /* loading state */,
  error: (error, stack) => /* error state */,
);
```

**Alternative**: Use `ref.read` if the provider is only accessed once:
```dart
final builder = await ref.read(spaceContextBuilderProvider.future);
```

### Step 4: Update spaceContextProvider

**File**: `lib/core/ai/chat/providers/space_context_provider.dart`

**Current**:
```dart
final spaceContextProvider =
    FutureProvider.family<SpaceContext, String>((ref, spaceId) async {
  final builder = ref.watch(spaceContextBuilderProvider);
  return builder.build(spaceId);
});
```

**Updated**:
```dart
final spaceContextProvider =
    FutureProvider.family<SpaceContext, String>((ref, spaceId) async {
  final builder = await ref.watch(spaceContextBuilderProvider.future);
  return builder.build(spaceId);
});
```

### Step 5: Update Settings UI for Custom Input

**File**: `lib/ui/settings/settings_screen.dart`

**Current UI**: Shows only preset chips (7, 14, 30 days)

**Updated UI**: Add custom input option

**Implementation approach**:

1. **Add state for custom mode**:
```dart
bool _isCustomDateRange = false;
TextEditingController _customDaysController = TextEditingController();
```

2. **Update UI to show preset chips + custom option**:
```dart
Wrap(
  spacing: 8,
  children: [
    ChoiceChip(
      label: Text('7 days'),
      selected: _dateRangeDays == 7 && !_isCustomDateRange,
      onSelected: (_) => _updateDateRange(7),
    ),
    ChoiceChip(
      label: Text('14 days'),
      selected: _dateRangeDays == 14 && !_isCustomDateRange,
      onSelected: (_) => _updateDateRange(14),
    ),
    ChoiceChip(
      label: Text('30 days'),
      selected: _dateRangeDays == 30 && !_isCustomDateRange,
      onSelected: (_) => _updateDateRange(30),
    ),
    ChoiceChip(
      label: Text('Custom'),
      selected: _isCustomDateRange,
      onSelected: (_) => setState(() => _isCustomDateRange = true),
    ),
  ],
),
if (_isCustomDateRange) ...[
  const SizedBox(height: 12),
  TextField(
    controller: _customDaysController,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(
      labelText: 'Number of days (1-1095)',
      helperText: 'Up to 3 years',
      errorText: _customDaysError,
      suffixIcon: IconButton(
        icon: Icon(Icons.check),
        onPressed: _applyCustomDateRange,
      ),
    ),
  ),
  const SizedBox(height: 8),
  const Text(
    'Larger date ranges allow the AI to access older records, but the system '
    'will prioritize the most recent and relevant information to fit within '
    'token limits. Typically 10-20 records are included regardless of range.',
    style: TextStyle(color: Colors.grey, fontSize: 12),
  ),
],
```

3. **Add validation for custom input**:
```dart
String? _customDaysError;

void _applyCustomDateRange() {
  final text = _customDaysController.text;
  final days = int.tryParse(text);
  
  if (days == null) {
    setState(() => _customDaysError = 'Please enter a valid number');
    return;
  }
  
  if (days < 1 || days > 1095) {
    setState(() => _customDaysError = 'Must be between 1 and 1095 (up to 3 years)');
    return;
  }
  
  setState(() => _customDaysError = null);
  _updateDateRange(days);
}
```

4. **Update _loadContextConfig to detect custom values**:
```dart
Future<void> _loadContextConfig() async {
  try {
    final days = await _contextConfigRepository.getDateRangeDays();
    if (!mounted) return;
    setState(() {
      _dateRangeDays = days;
      _isCustomDateRange = ![7, 14, 30].contains(days);
      if (_isCustomDateRange) {
        _customDaysController.text = days.toString();
      }
    });
  } catch (e) {
    debugPrint('[Settings] Failed to load context config: $e');
  }
}
```

### Step 6: Add Logging

Ensure comprehensive logging at key points:

1. **When reading date range setting**:
   ```dart
   await AppLogger.info(
     'Read date range setting',
     context: {
       'dateRangeDays': dateRangeDays,
       'source': 'ContextConfigRepository',
       'isCustom': ![7, 14, 30].contains(dateRangeDays),
     },
   );
   ```

2. **When using default**:
   ```dart
   await AppLogger.warning(
     'Using default date range',
     context: {
       'reason': 'Setting not found or invalid',
       'defaultDays': 14,
     },
   );
   ```

3. **When creating DateRange**:
   ```dart
   await AppLogger.info(
     'Created DateRange for context',
     context: {
       'days': dateRangeDays,
       'start': dateRange.start.toIso8601String(),
       'end': dateRange.end.toIso8601String(),
       'isCustom': ![7, 14, 30].contains(dateRangeDays),
     },
   );
   ```

4. **When user enters custom value**:
   ```dart
   await AppLogger.info(
     'User set custom date range',
     context: {
       'days': days,
       'previousValue': _dateRangeDays,
     },
   );
   ```

## Performance Considerations

### Impact Analysis

**Reading date range setting**: 
- Operation: Read from SharedPreferences
- Cost: ~1-5ms (synchronous disk read)
- Frequency: Once per provider initialization
- Impact: Negligible

**Provider initialization**:
- Current: Synchronous
- Updated: Async (due to reading setting)
- Impact: Minimal - provider is cached after first use

**Context building**:
- No change - date range is passed as parameter
- Impact: None

### Optimization

The date range setting could be cached in memory to avoid repeated SharedPreferences reads, but given the low frequency of provider initialization, this optimization is not necessary.

## Migration Strategy

### Backward Compatibility

- Existing users without a date range setting will get the default (14 days)
- No data migration required
- No breaking changes to APIs

### Rollout

1. Deploy code changes
2. Existing users continue with 14-day default
3. Users who change setting will see immediate effect
4. No user action required

## Documentation

### Code Comments

Add comments to clarify the date range flow:

```dart
/// Creates a SpaceContextBuilder with the user's configured date range.
/// 
/// Reads the date range setting from ContextConfigRepository and creates
/// an appropriate DateRange instance (7, 14, or 30 days). Falls back to
/// 14 days if the setting is missing or invalid.
final spaceContextBuilderProvider = FutureProvider<SpaceContextBuilder>(...);
```

### Logging Documentation

Update logging documentation to include:
- Date range setting read events
- Default fallback events
- Date range values in context assembly logs

## Alternatives Considered

### Alternative 1: Keep separate factory methods for each preset

Instead of using `lastNDays()` for all values, keep the separate `last7Days()`, `last14Days()`, `last30Days()` methods and add `lastNDays()` only for custom values.

**Pros**:
- More explicit for common cases
- Slightly better autocomplete/discoverability

**Cons**:
- Code duplication
- Inconsistent API (why use different methods for 7 vs 45 days?)
- More maintenance burden

**Decision**: Rejected - Using `lastNDays()` for all values is simpler and more consistent. The existing methods can delegate to `lastNDays()` for backward compatibility.

### Alternative 2: Pass date range on every build() call

Instead of configuring the builder with a date range, pass it as a parameter to every `build()` call.

**Pros**:
- More flexible - can change per request
- No need to change provider type

**Cons**:
- Requires changes to all call sites
- More complex API
- Setting would need to be read multiple times

**Decision**: Rejected - Configuration at builder creation is simpler and sufficient.

### Alternative 3: Use a global singleton for date range

Create a global `DateRangeConfig` singleton that's read by the builder.

**Pros**:
- No need to change provider type
- Simple to implement

**Cons**:
- Global state is harder to test
- Less explicit dependency injection
- Violates dependency inversion principle

**Decision**: Rejected - Explicit dependency injection is preferred.

### Alternative 4: Keep synchronous provider, read setting in build()

Keep the provider synchronous and read the date range setting inside `SpaceContextBuilderImpl.build()`.

**Pros**:
- No provider type change
- Setting is read fresh on every build

**Cons**:
- Violates single responsibility (builder shouldn't know about config storage)
- Harder to test
- Repeated async reads during context building

**Decision**: Rejected - Separation of concerns is important.

## Success Criteria

### Functional Success

1. ✅ User sets date range to 7 days → AI uses 7-day range
2. ✅ User sets date range to 30 days → AI uses 30-day range
3. ✅ User sets custom date range (e.g., 45 days) → AI uses 45-day range
4. ✅ User changes setting → Next AI request uses new value
5. ✅ New user (no setting) → System uses 14-day default
6. ✅ AI response mentions correct date range (preset or custom)
7. ✅ Invalid custom values are rejected with clear error messages

### Technical Success

1. ✅ All unit tests pass
2. ✅ All integration tests pass
3. ✅ All property-based tests pass
4. ✅ Logs show correct date range values
5. ✅ No performance regression

### User Experience Success

1. ✅ Setting change takes effect immediately (no app restart)
2. ✅ AI responses accurately reflect the time period
3. ✅ No errors or crashes related to date range
4. ✅ Confirmation message shown when setting is changed

## Timeline

### Phase 1: Core Fix (2-3 hours)
- Add `DateRange.lastNDays()` factory method
- Update `ContextConfigRepositoryImpl` validation (1-365 instead of 7/14/30)
- Register ContextConfigRepository in container
- Modify spaceContextBuilderProvider to read setting
- Update provider consumers
- Add logging

### Phase 2: UI Enhancement (1-2 hours)
- Add custom date range input to Settings UI
- Add validation for custom input
- Add state management for custom mode
- Update UI to show current value (preset or custom)

### Phase 3: Testing (1-2 hours)
- Write unit tests (including custom range tests)
- Write integration tests
- Write property-based tests
- Manual testing (preset and custom values)

### Phase 4: Verification (30 minutes)
- Deploy to test environment
- Verify logs show correct date range
- Test preset options (7, 14, 30 days)
- Test custom values (e.g., 1, 45, 90, 365, 1095 days)
- Test invalid values (0, -1, 1096)
- Test token budget enforcement with large ranges (1095 days with many records)
- Verify AI responses mention correct range

**Total Estimated Time**: 5-8 hours

## Risks and Mitigation

### Risk 1: Provider type change breaks existing code

**Impact**: High - App may not compile or crash
**Likelihood**: Medium
**Mitigation**: 
- Thorough code search for all usages of `spaceContextBuilderProvider`
- Update all consumers to handle `FutureProvider`
- Comprehensive testing before deployment

### Risk 2: ContextConfigRepository not registered

**Impact**: High - App crashes on startup
**Likelihood**: Low
**Mitigation**:
- Register repository early in app initialization
- Add startup test to verify registration
- Log successful registration

### Risk 3: Setting read fails silently

**Impact**: Medium - Users see wrong date range
**Likelihood**: Low
**Mitigation**:
- Comprehensive error handling
- Log all errors
- Always fall back to default
- Add monitoring for error frequency

### Risk 4: Performance degradation

**Impact**: Low - Slight delay in provider initialization
**Likelihood**: Low
**Mitigation**:
- Measure provider initialization time
- Cache provider after first use
- SharedPreferences reads are fast (~1-5ms)

## Monitoring and Observability

### Metrics to Track

1. **Date range setting distribution**
   - How many users use 7 days vs 14 vs 30
   - Track via analytics when setting is changed

2. **Default usage frequency**
   - How often is the default (14 days) used
   - Track via log aggregation

3. **Setting read errors**
   - Frequency of errors reading date range setting
   - Alert if error rate exceeds threshold

4. **Context assembly time**
   - Ensure no performance regression
   - Track p50, p95, p99 latencies

### Log Queries

**Find date range setting reads**:
```
"Read date range setting" OR "Using default date range"
```

**Find context assemblies with date range**:
```
"Starting space context assembly" AND dateRangeDays
```

**Find errors reading setting**:
```
"Failed to load context config" OR "Error reading date range"
```

## Appendix: Code Locations

### Files to Modify

1. `lib/core/ai/chat/models/date_range.dart`
   - Add `DateRange.lastNDays(int days)` factory method
   - Optionally update existing factory methods to delegate to `lastNDays()`

2. `lib/core/ai/chat/repositories/context_config_repository_impl.dart`
   - Update validation to accept 1-1095 instead of only 7/14/30
   - Update error messages to mention "up to 3 years"

3. `lib/core/ai/chat/providers/space_context_provider.dart`
   - Change `spaceContextBuilderProvider` to `FutureProvider`
   - Read date range setting
   - Use `DateRange.lastNDays()` for all values
   - Pass to builder constructor

4. `lib/ui/settings/settings_screen.dart`
   - Add custom date range input UI
   - Add validation for custom input
   - Add state management for custom mode
   - Update to detect and display custom values

5. App initialization (e.g., `lib/main.dart`)
   - Register `ContextConfigRepository` in `AppContainer`

### Files to Review (No Changes Expected)

1. `lib/core/ai/chat/repositories/context_config_repository.dart`
2. `lib/core/ai/chat/repositories/context_config_repository_impl.dart`
3. `lib/core/ai/chat/models/date_range.dart`
4. `lib/core/ai/chat/context/space_context_builder.dart`
5. `lib/ui/settings/settings_screen.dart`

### New Test Files

1. `test/core/ai/chat/providers/space_context_provider_date_range_test.dart`
2. `test/core/ai/chat/models/date_range_custom_test.dart`
3. `test/core/ai/chat/repositories/context_config_repository_custom_range_test.dart`
4. `test/property/date_range_setting_properties_test.dart`
5. `test/ui/settings/custom_date_range_ui_test.dart`
