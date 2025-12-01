# Design Document

## Overview

This design defines Stages 3-4 of LLM integration: introducing Space Context (Stage 3) and implementing Context Optimization (Stage 4). These stages build on the completed HTTP foundation and basic LLM integration (Stages 1-2) to enable the AI to reference the user's actual records while managing token budgets efficiently.

**Current State (After Stage 2):** AI generates responses with conversation history but no awareness of user's personal information.

**Target State (After Stage 4):** AI references user's actual records with intelligent filtering, relevance scoring, and token budget optimization.

**Architecture Philosophy:**
- Incremental delivery: Stage 3 adds basic context, Stage 4 optimizes it
- Privacy-first: All filtering happens client-side before transmission
- Token-conscious: Strategic allocation and truncation
- Quality-focused: Track improvements in response relevance

## Architecture

### Current System (After Stage 2)

```
User → SendChatMessageUseCase
  → Load last 3 messages
  → Build ChatRequest (message + history)
  → HttpAiChatService → Backend
  → LLM (system prompt + history + message)
  → Response
```

### Stage 3: Basic Space Context

```
User → SendChatMessageUseCase
  → Load last 3 messages
  → Load active Space
  → Load last 10 records from Space
  → Build SpaceContext (Space + records)
  → Build ChatRequest (message + history + context)
  → HttpAiChatService → Backend
  → LLM (system prompt + Space context + history + message)
  → Response
```

### Stage 4: Context Optimization

```
User → SendChatMessageUseCase
  → Load last 3 messages
  → Load active Space
  → Load ALL records from Space
  → Apply date range filter (default 14 days)
  → Score records by relevance (recency + access frequency)
  → Sort by relevance descending
  → Allocate token budget (system/context/history/response)
  → Select top N records that fit budget (max 20)
  → Build optimized SpaceContext
  → Build ChatRequest
  → HttpAiChatService → Backend
  → LLM (optimized prompt)
  → Response
```

## Components and Interfaces

### Stage 3 Components

#### 1. SpaceContextBuilder (Flutter)

**Purpose:** Build Space context with recent records.

**Responsibilities:**
- Load active Space metadata
- Load last 10 records from Space
- Format record summaries
- Estimate token usage
- Build SpaceContext object

**Key Methods:**
```dart
class SpaceContextBuilder {
  final RecordsRepository recordsRepository;
  final SpaceManager spaceManager;
  
  Future<SpaceContext> buildContext(String spaceId) async {
    // Load Space metadata
    final space = await spaceManager.getSpace(spaceId);
    
    // Load last 10 records
    final records = await recordsRepository.getRecent(
      spaceId: spaceId,
      limit: 10,
      excludeDeleted: true,
    );
    
    // Format summaries
    final summaries = records.map((r) => RecordSummary(
      title: r.title,
      type: r.type,
      date: r.date,
      tags: r.tags,
      summary: r.notes?.substring(0, min(100, r.notes!.length)),
    )).toList();
    
    return SpaceContext(
      spaceId: space.id,
      spaceName: space.name,
      description: space.description,
      categories: space.categories,
      recentRecords: summaries,
    );
  }
}
```


#### 2. RecordSummaryFormatter (Flutter)

**Purpose:** Format records into compact summaries for context.

**Responsibilities:**
- Extract key fields (title, type, date, tags)
- Truncate notes to 100 characters
- Estimate token count per summary
- Handle missing fields gracefully

**Implementation:**
```dart
class RecordSummaryFormatter {
  RecordSummary format(Record record) {
    return RecordSummary(
      title: record.title,
      type: record.type,
      date: record.date,
      tags: record.tags,
      summary: _truncateNotes(record.notes, maxLength: 100),
    );
  }
  
  String? _truncateNotes(String? notes, {required int maxLength}) {
    if (notes == null || notes.isEmpty) return null;
    if (notes.length <= maxLength) return notes;
    return '${notes.substring(0, maxLength)}...';
  }
  
  int estimateTokens(RecordSummary summary) {
    // Rough estimate: 4 characters per token
    final text = '${summary.title} ${summary.type} ${summary.tags.join(' ')} ${summary.summary ?? ''}';
    return (text.length / 4).ceil();
  }
}
```

#### 3. Enhanced System Prompt (Backend - Stage 3)

**Template:**
```
You are a compassionate AI companion helping users organize their personal information.

Current Space: {space_name}
Space Description: {space_description}
Available Categories: {categories}

Recent Records:
{record_summaries}

Guidelines:
- Reference user's actual records when relevant
- Use space-specific terminology
- Suggest appropriate categories for new information
- Be helpful, empathetic, and respectful

Conversation History:
{history}

User message: {user_message}
```

**Token Budget (Stage 3):**
- System prompt: 500 tokens
- Space context: 1500 tokens (10 records × 150 tokens avg)
- Message history: 1000 tokens
- Response: 1000 tokens
- **Total: 4000 tokens**

### Stage 4 Components

#### 1. ContextFilterEngine (Flutter)

**Purpose:** Filter records by date range and Space.

**Responsibilities:**
- Apply date range filter
- Exclude deleted records
- Exclude records from other Spaces
- Log filtering statistics

**Implementation:**
```dart
class ContextFilterEngine {
  List<Record> filterRecords(
    List<Record> records, {
    required String spaceId,
    required DateRange dateRange,
  }) {
    final filtered = records.where((record) {
      // Must be from active Space
      if (record.spaceId != spaceId) return false;
      
      // Must not be deleted
      if (record.deletedAt != null) return false;
      
      // Must be within date range
      if (record.createdAt.isBefore(dateRange.start)) return false;
      if (record.createdAt.isAfter(dateRange.end)) return false;
      
      return true;
    }).toList();
    
    await AppLogger.info('Records filtered', context: {
      'totalRecords': records.length,
      'filteredRecords': filtered.length,
      'dateRange': '${dateRange.start} to ${dateRange.end}',
    });
    
    return filtered;
  }
}
```

#### 2. RecordRelevanceScorer (Flutter)

**Purpose:** Calculate relevance score for each record.

**Responsibilities:**
- Score by recency (newer = higher)
- Score by access frequency
- Combine scores with weights
- Sort records by score

**Scoring Algorithm:**
```dart
class RecordRelevanceScorer {
  double calculateScore(Record record, {DateTime? now}) {
    now ??= DateTime.now();
    
    // Recency score (0-10): newer records score higher
    final daysOld = now.difference(record.createdAt).inDays;
    final recencyScore = max(0, 10 - (daysOld / 30) * 10);
    
    // Access frequency score (0-10): frequently viewed records score higher
    final accessCount = record.viewCount ?? 0;
    final frequencyScore = min(10, accessCount.toDouble());
    
    // Combined score: recency weighted 70%, frequency 30%
    final totalScore = (recencyScore * 0.7) + (frequencyScore * 0.3);
    
    return totalScore;
  }
  
  List<Record> sortByRelevance(List<Record> records) {
    final scored = records.map((r) => MapEntry(r, calculateScore(r))).toList();
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }
}
```

#### 3. TokenBudgetAllocator (Flutter)

**Purpose:** Allocate token budget across prompt sections.

**Responsibilities:**
- Define budget allocation strategy
- Reserve minimum tokens for response
- Calculate available tokens for context
- Enforce hard limits

**Budget Strategy:**
```dart
class TokenBudgetAllocator {
  final int totalBudget;
  
  TokenBudgetAllocator({this.totalBudget = 4800});
  
  TokenAllocation allocate() {
    return TokenAllocation(
      system: 800,      // System prompt + Space metadata
      context: 2000,    // Record summaries
      history: 1000,    // Last 3 conversation turns
      response: 1000,   // LLM response
      total: totalBudget,
    );
  }
  
  int getAvailableForContext(TokenAllocation allocation, {
    required int systemUsed,
    required int historyUsed,
  }) {
    final used = systemUsed + historyUsed + allocation.response;
    final available = allocation.total - used;
    return max(0, available);
  }
}
```

#### 4. ContextTruncationStrategy (Flutter)

**Purpose:** Truncate records to fit token budget.

**Responsibilities:**
- Select records that fit budget
- Remove lowest-scoring records first
- Log truncation events
- Provide truncation statistics

**Implementation:**
```dart
class ContextTruncationStrategy {
  final RecordSummaryFormatter formatter;
  
  List<RecordSummary> truncateToFit(
    List<Record> sortedRecords,
    int availableTokens,
  ) {
    final summaries = <RecordSummary>[];
    int tokensUsed = 0;
    int recordsIncluded = 0;
    
    for (final record in sortedRecords) {
      final summary = formatter.format(record);
      final tokens = formatter.estimateTokens(summary);
      
      if (tokensUsed + tokens <= availableTokens) {
        summaries.add(summary);
        tokensUsed += tokens;
        recordsIncluded++;
      } else {
        break; // Budget exhausted
      }
      
      // Hard limit: max 20 records
      if (recordsIncluded >= 20) break;
    }
    
    await AppLogger.info('Context truncated', context: {
      'totalRecords': sortedRecords.length,
      'includedRecords': recordsIncluded,
      'tokensUsed': tokensUsed,
      'availableTokens': availableTokens,
    });
    
    return summaries;
  }
}
```

#### 5. Enhanced System Prompt (Backend - Stage 4)

**Template:**
```
You are a compassionate AI companion helping users organize their personal information.

Active Space: {space_name} ({space_description})

Relevant Records (filtered by date and relevance):
{optimized_record_summaries}

Context Notes:
- Showing {records_included} of {total_records} records
- Date range: {date_range}
- Older records may be excluded

Guidelines:
- Reference user's actual records when relevant
- Acknowledge if information might be incomplete
- Suggest exploring other time periods if needed
- Be helpful, empathetic, and respectful

Conversation History:
{history}

User message: {user_message}
```

**Token Budget (Stage 4):**
- System prompt: 800 tokens
- Optimized context: 2000 tokens (up to 20 records, intelligently selected)
- Message history: 1000 tokens
- Response: 1000 tokens
- **Total: 4800 tokens**

## Data Models

### SpaceContext (Extended for Stage 3)

```dart
class SpaceContext {
  final String spaceId;
  final String spaceName;
  final String description;
  final List<String> categories;
  final List<RecordSummary> recentRecords;
  final int maxContextRecords;
  
  const SpaceContext({
    required this.spaceId,
    required this.spaceName,
    required this.description,
    required this.categories,
    required this.recentRecords,
    this.maxContextRecords = 10,  // Stage 3: 10, Stage 4: 20
  });
  
  Map<String, dynamic> toJson() {
    return {
      'spaceId': spaceId,
      'spaceName': spaceName,
      'description': description,
      'categories': categories,
      'recentRecords': recentRecords.map((r) => r.toJson()).toList(),
    };
  }
}
```

### RecordSummary

```dart
class RecordSummary {
  final String title;
  final String type;
  final DateTime date;
  final List<String> tags;
  final String? summary;  // Truncated notes (max 100 chars)
  
  const RecordSummary({
    required this.title,
    required this.type,
    required this.date,
    required this.tags,
    this.summary,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type,
      'date': date.toIso8601String(),
      'tags': tags,
      'summary': summary,
    };
  }
}
```

### ContextFilters (New for Stage 4)

```dart
class ContextFilters {
  final DateRange dateRange;
  final int maxRecords;
  final String spaceId;
  
  const ContextFilters({
    required this.dateRange,
    this.maxRecords = 20,
    required this.spaceId,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'dateRange': {
        'start': dateRange.start.toIso8601String(),
        'end': dateRange.end.toIso8601String(),
      },
      'maxRecords': maxRecords,
    };
  }
}

class DateRange {
  final DateTime start;
  final DateTime end;
  
  const DateRange({required this.start, required this.end});
  
  factory DateRange.last7Days() {
    final now = DateTime.now();
    return DateRange(
      start: now.subtract(Duration(days: 7)),
      end: now,
    );
  }
  
  factory DateRange.last14Days() {
    final now = DateTime.now();
    return DateRange(
      start: now.subtract(Duration(days: 14)),
      end: now,
    );
  }
  
  factory DateRange.last30Days() {
    final now = DateTime.now();
    return DateRange(
      start: now.subtract(Duration(days: 30)),
      end: now,
    );
  }
}
```

### TokenAllocation (New for Stage 4)

```dart
class TokenAllocation {
  final int system;
  final int context;
  final int history;
  final int response;
  final int total;
  
  const TokenAllocation({
    required this.system,
    required this.context,
    required this.history,
    required this.response,
    required this.total,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'system': system,
      'context': context,
      'history': history,
      'response': response,
      'total': total,
    };
  }
}
```

### ContextStats (New for Stage 4)

```dart
class ContextStats {
  final int recordsFiltered;
  final int recordsIncluded;
  final int tokensEstimated;
  final int tokensAvailable;
  final double compressionRatio;
  final Duration assemblyTime;
  
  const ContextStats({
    required this.recordsFiltered,
    required this.recordsIncluded,
    required this.tokensEstimated,
    required this.tokensAvailable,
    required this.compressionRatio,
    required this.assemblyTime,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'recordsFiltered': recordsFiltered,
      'recordsIncluded': recordsIncluded,
      'tokensEstimated': tokensEstimated,
      'tokensAvailable': tokensAvailable,
      'compressionRatio': compressionRatio,
      'assemblyTimeMs': assemblyTime.inMilliseconds,
    };
  }
}
```


## Data Flow Diagrams

### Stage 3: Basic Space Context Flow

```
1. User sends message in ChatComposer
   ↓
2. SendChatMessageUseCase.execute()
   - Load last 3 messages from thread
   - Get active Space ID
   ↓
3. SpaceContextBuilder.buildContext()
   - Load Space metadata (name, description, categories)
   - Load last 10 records from Space
   - Format record summaries (truncate notes to 100 chars)
   - Estimate token usage (~1500 tokens)
   ↓
4. Build ChatRequest
   - Include message
   - Include history (last 3 turns)
   - Include SpaceContext
   ↓
5. HttpAiChatService → Backend
   - POST /api/v1/chat/message
   - Payload includes Space context
   ↓
6. Backend constructs prompt
   - System prompt (500 tokens)
   - Space name, description, categories
   - 10 record summaries
   - Conversation history
   - User message
   - Total: ~4000 tokens
   ↓
7. LLM generates response
   - References user's records
   - Uses Space-specific terminology
   ↓
8. Response → Flutter → UI
   - Display AI message with record references
```

### Stage 4: Context Optimization Flow

```
1. User sends message in ChatComposer
   ↓
2. SendChatMessageUseCase.execute()
   - Load last 3 messages from thread
   - Get active Space ID
   - Start context assembly timer
   ↓
3. Load ALL records from Space
   - Query RecordsRepository
   - May return 50-100+ records
   ↓
4. ContextFilterEngine.filterRecords()
   - Apply date range filter (default: last 14 days)
   - Exclude deleted records
   - Exclude records from other Spaces
   - Log: filtered 50 → 25 records
   ↓
5. RecordRelevanceScorer.sortByRelevance()
   - Calculate score for each record:
     * Recency score (0-10)
     * Access frequency score (0-10)
     * Combined: (recency × 0.7) + (frequency × 0.3)
   - Sort descending by score
   - Log relevance scores
   ↓
6. TokenBudgetAllocator.allocate()
   - Total budget: 4800 tokens
   - System: 800 tokens
   - Context: 2000 tokens
   - History: 1000 tokens
   - Response: 1000 tokens
   ↓
7. ContextTruncationStrategy.truncateToFit()
   - Iterate through sorted records
   - Format each as RecordSummary
   - Estimate tokens per summary
   - Add to context while tokens available
   - Stop at 20 records or budget exhausted
   - Log: included 12 of 25 records, used 1850 tokens
   ↓
8. Build optimized SpaceContext
   - Space metadata
   - 12 optimized record summaries
   - Context stats (filtered, included, tokens)
   ↓
9. Build ChatRequest
   - Message + history + optimized context
   - Include ContextFilters metadata
   - Include TokenAllocation
   ↓
10. HttpAiChatService → Backend
   - POST /api/v1/chat/message
   - Enhanced payload with optimization metadata
   ↓
11. Backend constructs optimized prompt
   - System prompt with context notes
   - "Showing 12 of 25 records"
   - "Date range: last 14 days"
   - Optimized record summaries
   - History + message
   - Total: ~4600 tokens
   ↓
12. LLM generates response
   - References relevant records
   - Acknowledges time window
   ↓
13. Response → Flutter → UI
   - Display AI message
   - Show context stats in metadata
```

## Backend API Updates

### Stage 3: Enhanced Request Payload

```json
{
  "threadId": "thread_123",
  "message": "What were my recent health appointments?",
  "timestamp": "2025-11-24T10:00:00Z",
  "userId": "user_456",
  "history": [...],
  "context": {
    "activeSpace": {
      "id": "health",
      "name": "Health",
      "description": "Medical records and wellness tracking",
      "categories": ["Appointment", "Lab", "Medication"]
    },
    "records": [
      {
        "title": "Cardiology Visit",
        "type": "Appointment",
        "date": "2025-11-20",
        "tags": ["cardiology", "bp"],
        "summary": "Follow-up appointment for blood pressure monitoring. Dr. Smith reviewed readings..."
      }
      // ... 9 more records
    ]
  }
}
```

### Stage 4: Optimized Request Payload

```json
{
  "threadId": "thread_123",
  "message": "What were my recent health appointments?",
  "timestamp": "2025-11-24T10:00:00Z",
  "userId": "user_456",
  "history": [...],
  "context": {
    "activeSpace": {
      "id": "health",
      "name": "Health",
      "description": "Medical records and wellness tracking",
      "categories": ["Appointment", "Lab", "Medication"]
    },
    "records": [
      // 12 optimized records, sorted by relevance
    ],
    "filters": {
      "dateRange": {
        "start": "2025-11-10",
        "end": "2025-11-24"
      },
      "maxRecords": 20
    },
    "stats": {
      "recordsFiltered": 25,
      "recordsIncluded": 12,
      "tokensEstimated": 1850,
      "tokensAvailable": 2000,
      "compressionRatio": 0.48
    }
  },
  "tokenBudget": {
    "system": 800,
    "context": 2000,
    "history": 1000,
    "response": 1000,
    "total": 4800
  }
}
```

## Risks and Mitigations

### Risk 1: Token Budget Overruns

**Risk:** Context exceeds allocated token budget, causing LLM errors or truncated responses.

**Impact:** Poor response quality, wasted API calls, user frustration.

**Mitigation:**
- Enforce strict token counting before sending
- Truncate context proactively
- Reserve minimum 1000 tokens for response
- Log budget violations
- Alert on consistent overruns

**Monitoring:**
- Track actual vs estimated token usage
- Alert if budget exceeded > 5% of requests

### Risk 2: Irrelevant Records Included

**Risk:** Relevance scoring selects wrong records, reducing response quality.

**Impact:** AI references irrelevant information, confusing users.

**Mitigation:**
- Tune relevance scoring weights (recency vs frequency)
- A/B test different scoring strategies
- Collect user feedback on response quality
- Allow manual date range adjustment
- Log relevance scores for analysis

**Monitoring:**
- Track user feedback scores
- Compare before/after Stage 4
- Review low-rated responses

### Risk 3: Context Assembly Performance

**Risk:** Loading and filtering records takes too long, increasing latency.

**Impact:** Slow response times, poor user experience.

**Mitigation:**
- Optimize database queries (indexes on spaceId, createdAt)
- Cache Space metadata
- Limit initial record load (query with LIMIT)
- Implement timeout (max 5s for context assembly)
- Log assembly time

**Monitoring:**
- Track context assembly time (p50, p95, p99)
- Alert if p95 > 1 second

### Risk 4: Privacy Leaks

**Risk:** Records from wrong Space or deleted records included in context.

**Impact:** Privacy violation, user trust loss.

**Mitigation:**
- Strict Space filtering (spaceId match)
- Exclude deleted records (deletedAt != null)
- Never send record IDs
- Audit context assembly
- Unit tests for filtering logic

**Monitoring:**
- Audit logs for Space mismatches
- Regular security reviews

### Risk 5: Inconsistent Response Quality

**Risk:** Adding context doesn't improve responses or makes them worse.

**Impact:** Wasted development effort, user disappointment.

**Mitigation:**
- Track response quality metrics
- Compare before/after each stage
- Collect user feedback (thumbs up/down)
- A/B test context strategies
- Provide fallback to Stage 2 if quality drops

**Monitoring:**
- Track feedback scores per stage
- Alert if quality drops below 80%

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do.*

### Property 1: Space Isolation

*For any* ChatRequest with Space context, all included records should have spaceId matching the active Space.

**Validates: Requirements 1.4**

### Property 2: Deleted Record Exclusion

*For any* ChatRequest with context, no included records should have a non-null deletedAt timestamp.

**Validates: Requirements 2.4**

### Property 3: Record Summary Truncation

*For any* RecordSummary, the summary field should be at most 100 characters long.

**Validates: Requirements 2.3**

### Property 4: Token Budget Enforcement

*For any* ChatRequest, the total estimated tokens should not exceed the allocated budget.

**Validates: Requirements 3.1, 3.2**

### Property 5: Date Range Filtering

*For any* filtered record set, all records should have createdAt within the specified date range.

**Validates: Requirements 4.2**

### Property 6: Record Count Limit

*For any* optimized context, the number of included records should not exceed 20.

**Validates: Requirements 5.1**

### Property 7: Relevance Sorting

*For any* list of scored records, records should be sorted in descending order by relevance score.

**Validates: Requirements 6.4**

### Property 8: Response Token Reservation

*For any* token allocation, at least 1000 tokens should be reserved for the response.

**Validates: Requirements 7.2**

### Property 9: Context Assembly Logging

*For any* context assembly, the system should log records filtered, records included, and token estimate.

**Validates: Requirements 9.1**

### Property 10: Truncation Precedence

*For any* truncation event, records with lower relevance scores should be removed before records with higher scores.

**Validates: Requirements 7.3**


## Testing Strategy

### Unit Tests

**SpaceContextBuilder Tests:**
- Test loading Space metadata
- Test loading last 10 records
- Test record summary formatting
- Test token estimation
- Mock RecordsRepository and SpaceManager

**RecordSummaryFormatter Tests:**
- Test note truncation (100 chars)
- Test handling missing fields
- Test token estimation accuracy
- Test various record types

**ContextFilterEngine Tests:**
- Test date range filtering
- Test Space filtering
- Test deleted record exclusion
- Test filter combinations

**RecordRelevanceScorer Tests:**
- Test recency scoring (0-10 scale)
- Test frequency scoring (0-10 scale)
- Test combined score calculation
- Test sorting by relevance

**TokenBudgetAllocator Tests:**
- Test budget allocation strategy
- Test available token calculation
- Test response reservation enforcement

**ContextTruncationStrategy Tests:**
- Test truncation to fit budget
- Test 20-record limit
- Test lowest-score-first removal
- Test truncation statistics

### Integration Tests

**End-to-End Stage 3 Flow:**
1. Create Space with 15 records
2. Send chat message
3. Verify context includes last 10 records
4. Verify Space metadata included
5. Verify LLM response references records
6. Verify token budget respected

**End-to-End Stage 4 Flow:**
1. Create Space with 50 records (various dates)
2. Send chat message
3. Verify date filtering (last 14 days)
4. Verify relevance scoring applied
5. Verify top records selected
6. Verify token budget optimized
7. Verify context stats logged

**Context Optimization Effectiveness:**
1. Compare Stage 2 vs Stage 3 response quality
2. Compare Stage 3 vs Stage 4 token efficiency
3. Measure response relevance improvement
4. Validate user feedback scores

### Property-Based Tests

**Property 1: Space Isolation**
- Generate random Spaces with records
- Build context for each Space
- Assert all records match Space ID

**Property 4: Token Budget Enforcement**
- Generate random record sets
- Build optimized context
- Assert total tokens ≤ budget

**Property 5: Date Range Filtering**
- Generate records with random dates
- Apply date range filter
- Assert all records within range

**Property 6: Record Count Limit**
- Generate large record sets (50-100)
- Build optimized context
- Assert ≤ 20 records included

**Property 7: Relevance Sorting**
- Generate records with random scores
- Sort by relevance
- Assert descending order

### Manual Testing

**Stage 3 Manual Tests:**
1. **Space Context Inclusion:**
   - Open chat in Health Space
   - Send message "What are my recent records?"
   - Verify response mentions Health-specific records
   - Verify Space categories referenced

2. **Record References:**
   - Create 5 test records in Space
   - Send message asking about them
   - Verify AI references specific records by title
   - Verify dates and tags mentioned

3. **Space Switching:**
   - Start chat in Health Space
   - Switch to Education Space
   - Send message
   - Verify context updated to Education records

**Stage 4 Manual Tests:**
1. **Date Range Filtering:**
   - Create records spanning 60 days
   - Set date range to 14 days
   - Send message
   - Verify only recent records referenced
   - Check logs for filtering stats

2. **Relevance Scoring:**
   - Create mix of old/new records
   - View some records multiple times (increase access count)
   - Send message
   - Verify frequently accessed records prioritized
   - Check logs for relevance scores

3. **Token Budget Optimization:**
   - Create 30 records in Space
   - Send message
   - Verify only top ~15-20 included
   - Check logs for token usage
   - Verify response quality maintained

4. **Context Stats:**
   - Send message with large record set
   - Check response metadata
   - Verify stats show: filtered, included, tokens
   - Verify compression ratio calculated

### Performance Benchmarks

**Stage 3 Targets:**
- Context assembly: < 500ms
- Total request time: < 5s (p95)
- Token usage: ~4000 tokens avg

**Stage 4 Targets:**
- Context assembly: < 1s (includes filtering + scoring)
- Total request time: < 5s (p95)
- Token usage: ~4500 tokens avg
- Token savings: 20-30% vs naive approach

### Acceptance Criteria

**Stage 3 Complete When:**
- ✅ SpaceContextBuilder implemented and tested
- ✅ Space metadata included in prompts
- ✅ Last 10 records included in context
- ✅ Record summaries truncated to 100 chars
- ✅ Token budget ~4000 tokens
- ✅ LLM responses reference user records
- ✅ All unit tests passing
- ✅ Integration tests passing
- ✅ Manual tests documented
- ✅ Response quality improved vs Stage 2

**Stage 4 Complete When:**
- ✅ ContextFilterEngine implemented
- ✅ RecordRelevanceScorer implemented
- ✅ TokenBudgetAllocator implemented
- ✅ ContextTruncationStrategy implemented
- ✅ Date range filtering working (7/14/30 days)
- ✅ Relevance scoring working
- ✅ Token budget optimized (~4800 tokens)
- ✅ Up to 20 records intelligently selected
- ✅ Context stats logged
- ✅ All unit tests passing
- ✅ All integration tests passing
- ✅ Property-based tests passing
- ✅ Manual tests documented
- ✅ Token savings measured (20-30%)
- ✅ Response quality maintained or improved

## Implementation Notes

### Dependency Injection

**Register Services in AppContainer:**
```dart
class AppContainer {
  late final SpaceContextBuilder spaceContextBuilder;
  late final ContextFilterEngine contextFilterEngine;
  late final RecordRelevanceScorer relevanceScorer;
  late final TokenBudgetAllocator tokenBudgetAllocator;
  late final ContextTruncationStrategy truncationStrategy;
  
  Future<void> bootstrap() async {
    // Stage 3 services
    spaceContextBuilder = SpaceContextBuilder(
      recordsRepository: recordsRepository,
      spaceManager: spaceManager,
      formatter: RecordSummaryFormatter(),
    );
    
    // Stage 4 services
    contextFilterEngine = ContextFilterEngine();
    relevanceScorer = RecordRelevanceScorer();
    tokenBudgetAllocator = TokenBudgetAllocator(totalBudget: 4800);
    truncationStrategy = ContextTruncationStrategy(
      formatter: RecordSummaryFormatter(),
    );
  }
}
```

### Configuration Management

**Context Configuration:**
```dart
class ContextConfig {
  final int maxRecordsStage3;
  final int maxRecordsStage4;
  final DateRangePreset defaultDateRange;
  final int totalTokenBudget;
  final TokenAllocation tokenAllocation;
  
  const ContextConfig({
    this.maxRecordsStage3 = 10,
    this.maxRecordsStage4 = 20,
    this.defaultDateRange = DateRangePreset.last14Days,
    this.totalTokenBudget = 4800,
    required this.tokenAllocation,
  });
  
  factory ContextConfig.stage3() {
    return ContextConfig(
      maxRecordsStage3: 10,
      totalTokenBudget: 4000,
      tokenAllocation: TokenAllocation(
        system: 500,
        context: 1500,
        history: 1000,
        response: 1000,
        total: 4000,
      ),
    );
  }
  
  factory ContextConfig.stage4() {
    return ContextConfig(
      maxRecordsStage4: 20,
      totalTokenBudget: 4800,
      tokenAllocation: TokenAllocation(
        system: 800,
        context: 2000,
        history: 1000,
        response: 1000,
        total: 4800,
      ),
    );
  }
}

enum DateRangePreset {
  last7Days,
  last14Days,
  last30Days,
}
```

### Logging Integration

**Per `.kiro/steering/logging-guidelines.md`:**
```dart
// Context assembly start
final startTime = DateTime.now();
await AppLogger.info('Context assembly started', context: {
  'spaceId': spaceId,
  'stage': stage,
});

// Context assembly complete
final duration = DateTime.now().difference(startTime);
await AppLogger.info('Context assembly complete', context: {
  'spaceId': spaceId,
  'stage': stage,
  'recordsFiltered': stats.recordsFiltered,
  'recordsIncluded': stats.recordsIncluded,
  'tokensEstimated': stats.tokensEstimated,
  'tokensAvailable': stats.tokensAvailable,
  'compressionRatio': stats.compressionRatio,
  'assemblyTimeMs': duration.inMilliseconds,
});

// Truncation event
await AppLogger.info('Context truncated', context: {
  'totalRecords': totalRecords,
  'includedRecords': includedRecords,
  'reason': 'token_budget_exceeded',
  'tokensUsed': tokensUsed,
  'tokensAvailable': tokensAvailable,
});
```

### Performance Optimization

**Database Indexes:**
```sql
-- Ensure indexes exist for efficient queries
CREATE INDEX idx_records_space_created ON records(spaceId, createdAt DESC);
CREATE INDEX idx_records_space_deleted ON records(spaceId, deletedAt);
```

**Caching Strategy:**
```dart
// Cache Space metadata (rarely changes)
class SpaceMetadataCache {
  final Map<String, Space> _cache = {};
  final Duration ttl = Duration(hours: 1);
  
  Future<Space> getSpace(String spaceId) async {
    if (_cache.containsKey(spaceId)) {
      return _cache[spaceId]!;
    }
    
    final space = await spaceManager.getSpace(spaceId);
    _cache[spaceId] = space;
    return space;
  }
  
  void invalidate(String spaceId) {
    _cache.remove(spaceId);
  }
}
```

### Settings UI for Date Range

**Add to Settings Screen:**
```dart
class ContextSettingsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final config = ref.watch(contextConfigProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Context Settings', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 8),
        
        ListTile(
          title: Text('Date Range'),
          subtitle: Text('How far back to include records'),
          trailing: DropdownButton<DateRangePreset>(
            value: config.defaultDateRange,
            items: [
              DropdownMenuItem(
                value: DateRangePreset.last7Days,
                child: Text('Last 7 days'),
              ),
              DropdownMenuItem(
                value: DateRangePreset.last14Days,
                child: Text('Last 14 days'),
              ),
              DropdownMenuItem(
                value: DateRangePreset.last30Days,
                child: Text('Last 30 days'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(contextConfigProvider.notifier).setDateRange(value);
              }
            },
          ),
        ),
      ],
    );
  }
}
```

## References

- `.kiro/specs/llm-http-foundation/` - Stages 1-2 (completed)
- `.kiro/specs/ai-chat-companion/` - Existing AI chat spec
- `.kiro/steering/logging-guidelines.md` - Logging requirements
- `.kiro/steering/flutter-ui-performance.md` - Performance guidelines
- `CLEAN_ARCHITECTURE_GUIDE.md` - Architecture patterns
- `AGENTS.md` - Development guidelines
