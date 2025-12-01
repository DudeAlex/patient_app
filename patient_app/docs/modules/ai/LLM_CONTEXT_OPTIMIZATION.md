# LLM Context Optimization

**Status:** ✅ IMPLEMENTED  
**Version:** Stage 4  
**Last Updated:** November 27, 2025

## Overview

The LLM Context Optimization feature intelligently manages the context provided to AI chat requests, ensuring relevant information is included while staying within token budgets. The system progresses through multiple stages, each adding more sophisticated context management.

## Architecture

### Stage 3: Basic Space Context

Stage 3 provides foundational context by including Space metadata and recent records.

**Components:**
- `RecordSummaryFormatter` - Formats records into concise summaries (≤100 chars)
- `SpaceContextBuilder` - Assembles Space metadata and recent records
- `RecordSummary` - Model for formatted record summaries
- `SpaceContext` - Model containing Space info and record summaries

**Features:**
- Includes Space name, description, and categories
- Includes last 10 records from the Space
- Truncates record notes to 100 characters
- Estimates token usage
- Token budget: ~4000 tokens

### Stage 4: Context Optimization

Stage 4 adds intelligent filtering, scoring, and truncation to optimize context quality and token usage.

**Components:**
- `ContextFilterEngine` - Filters records by date range, Space, and deletion status
- `RecordRelevanceScorer` - Scores records by recency and access frequency
- `TokenBudgetAllocator` - Allocates tokens across prompt sections
- `ContextTruncationStrategy` - Truncates records to fit budget
- `ContextConfig` - Configuration for context assembly
- `DateRange` - Model for date range filtering
- `ContextFilters` - Model for filter parameters
- `TokenAllocation` - Model for token budget allocation
- `ContextStats` - Model for context assembly metrics

**Features:**
- **Date Range Filtering:** Configurable 7/14/30 day windows
- **Relevance Scoring:** Recency (70%) + Frequency (30%)
- **Smart Truncation:** Up to 20 records, highest scores first
- **Token Budget:** 4800 total (system 800, context 2000, history 1000, response 1000)
- **Comprehensive Logging:** All metrics tracked via AppLogger
- **User Feedback:** Thumbs up/down on AI responses
- **Metrics Dashboard:** Context performance tracking

## Configuration

### Date Range Settings

Users can configure the date range for context filtering in Settings:

**Options:**
- 7 days (recent focus)
- 14 days (default, balanced)
- 30 days (broader context)

**Location:** Settings → Context Settings → Date Range

**Persistence:** Saved in SharedPreferences

### Token Budget

**Total Budget:** 4800 tokens

**Allocation:**
- System Prompt: 800 tokens
- Context (Space + Records): ≤2000 tokens
- Conversation History: 1000 tokens
- Response: ≥1000 tokens (minimum reservation)

**Enforcement:**
- Response always gets minimum 1000 tokens
- Context is reduced if needed to maintain response budget
- Truncation removes lowest-scoring records first

### Record Limits

**Maximum Records:** 20 per request

**Rationale:**
- Prevents context overload
- Ensures response quality
- Maintains reasonable token usage
- Focuses on most relevant information

## Relevance Scoring Algorithm

### Formula

```
relevance_score = (recency_score × 0.7) + (frequency_score × 0.3)
```

### Recency Score (0-10)

Measures how recent a record is:

```
days_old = now - record.date
recency_score = max(0, 10 - (days_old / 30) × 10)
```

**Examples:**
- Today: 10.0
- 15 days ago: 5.0
- 30+ days ago: 0.0

### Frequency Score (0-10)

Measures how often a record is accessed:

```
frequency_score = min(10.0, record.viewCount)
```

**Examples:**
- Never viewed: 0.0
- Viewed 5 times: 5.0
- Viewed 10+ times: 10.0

### Combined Score

**Weighting Rationale:**
- Recency (70%): Recent information is usually more relevant
- Frequency (30%): Frequently accessed records are important

**Score Range:** 0.0 to 10.0

**Sorting:** Records sorted in descending order (highest score first)

## Context Assembly Process

### Step-by-Step Flow

1. **Load Records**
   - Fetch all records from active Space
   - Include metadata (title, type, date, tags, notes)

2. **Apply Filters**
   - Filter by date range (7/14/30 days)
   - Exclude deleted records
   - Exclude records from other Spaces

3. **Score Records**
   - Calculate recency score for each record
   - Calculate frequency score using viewCount
   - Combine scores with 70/30 weighting

4. **Sort by Relevance**
   - Sort records by combined score (descending)
   - Highest-scoring records first

5. **Allocate Token Budget**
   - Reserve tokens for system, history, response
   - Calculate available tokens for context

6. **Truncate to Fit**
   - Iterate through sorted records
   - Add records while tokens available
   - Stop at 20 records or budget exhausted
   - Remove lowest-scoring records if needed

7. **Build Context**
   - Format included records as summaries
   - Assemble SpaceContext with metadata
   - Generate ContextStats for logging

8. **Log Metrics**
   - Log filtering statistics
   - Log relevance scores
   - Log token allocation
   - Log truncation events
   - Log assembly time

### Performance Targets

- **Assembly Time:** < 500ms
- **Token Utilization:** 80-95% of available context budget
- **Records Included:** 10-20 (depending on content)
- **Compression Ratio:** 0.2-0.4 (20-40% of filtered records)

## Token Budget Strategy

### Design Principles

1. **Response Priority:** Always reserve minimum 1000 tokens for response
2. **Context Optimization:** Use available tokens efficiently for context
3. **History Preservation:** Maintain conversation continuity
4. **System Clarity:** Ensure clear system instructions

### Budget Allocation

**Fixed Allocations:**
- System: 800 tokens (instructions, guidelines)
- History: 1000 tokens (conversation context)
- Response: 1000 tokens minimum (LLM output)

**Variable Allocation:**
- Context: Up to 2000 tokens (Space + Records)

**Total:** 4800 tokens

### Adaptive Behavior

**When Context Exceeds Budget:**
1. Truncate lowest-scoring records
2. Reduce context to fit available tokens
3. Maintain response reservation

**When Context Under Budget:**
1. Include all high-scoring records
2. Unused tokens remain available
3. No artificial padding

### Token Estimation

**Record Summary:**
- ~4 tokens per word (English)
- Title: ~10-20 tokens
- Type: ~5 tokens
- Date: ~10 tokens
- Tags: ~5-15 tokens
- Summary (100 chars): ~25-30 tokens
- **Total per record:** ~60-100 tokens

**Space Metadata:**
- Name: ~10-20 tokens
- Description: ~20-50 tokens
- Categories: ~10-30 tokens
- **Total:** ~40-100 tokens

## User Feedback System

### Features

**Feedback Options:**
- 👍 Thumbs Up (positive)
- 👎 Thumbs Down (negative)

**Persistence:**
- Stored in database with message ID
- Includes feedback timestamp
- Tracked per Stage (2/3/4) for comparison

**UI Location:**
- Appears on AI message bubbles
- Only shown for sent messages
- Highlights when selected

**Purpose:**
- Track user satisfaction
- Compare Stage performance
- Identify quality issues
- Guide future improvements

## Context Metrics Dashboard

### Location

Settings → Context Metrics card

### Tracked Metrics

**Per-Request Metrics:**
- Records filtered (after date range)
- Records included (in context)
- Tokens estimated (for context)
- Tokens available (budget)
- Compression ratio (included/filtered)
- Assembly time (milliseconds)

**Aggregated Metrics:**
- Average records per request
- Average token usage
- Average assembly time
- Truncation frequency

### Accessing Detailed Metrics

**Via Logs:**
1. Run `.\get_crash_logs.ps1`
2. Search for context-related log entries
3. Analyze metrics over time

**Log Keys:**
- `Context truncation complete`
- `Token budget allocated`
- `Scored records by relevance`
- `Context filtering complete`

## Testing

### Automated Tests

**Unit Tests:**
- RecordSummaryFormatter
- SpaceContextBuilder
- ContextFilterEngine
- RecordRelevanceScorer
- TokenBudgetAllocator
- ContextTruncationStrategy

**Integration Tests:**
- Stage 3 end-to-end flow
- Stage 4 end-to-end flow
- Offline queue handling

**Property-Based Tests:**
- Space isolation (Property 1)
- Deleted record exclusion (Property 2)
- Summary truncation (Property 3)
- Token budget enforcement (Property 4)
- Date range filtering (Property 5)
- Record count limit (Property 6)
- Relevance sorting (Property 7)
- Response token reservation (Property 8)
- Truncation precedence (Property 10)

### Manual Testing

See `docs/core/TESTING.md` for:
- Manual testing scenarios
- Token savings measurement
- Performance verification
- User feedback collection

## Performance

### Token Savings

**Target:** 20-30% reduction vs Stage 3

**Mechanisms:**
- Date filtering removes old records
- Relevance scoring prioritizes important records
- Smart truncation fits within budget

**Measurement:** See `docs/core/TESTING.md` for methodology

### Response Quality

**Goal:** Maintain or improve quality despite fewer tokens

**Strategies:**
- Include most relevant records
- Preserve recent information
- Maintain conversation context
- Ensure sufficient response budget

## Troubleshooting

### High Assembly Time (>500ms)

**Causes:**
- Large number of records to filter
- Slow database queries
- Complex relevance calculations

**Solutions:**
- Optimize database indexes
- Cache frequently accessed data
- Profile and optimize hot paths

### Low Token Utilization (<50%)

**Causes:**
- Too few records in date range
- Very short record summaries
- Aggressive truncation

**Solutions:**
- Increase date range
- Verify record content
- Review truncation logic

### Frequent Truncation

**Expected:** When >20 records in date range

**Causes:**
- Many recent records
- Long record summaries
- Tight token budget

**Solutions:**
- Normal behavior, no action needed
- Consider if 20-record limit is appropriate
- Review summary length

### Poor Relevance Scores

**Causes:**
- Records not being viewed
- All records same age
- Scoring weights not optimal

**Solutions:**
- Encourage record viewing
- Verify viewCount tracking
- Consider adjusting weights

## Future Enhancements

**Potential Improvements:**
- Semantic similarity scoring
- User-specific relevance weights
- Dynamic token budget adjustment
- Multi-space context aggregation
- Real-time metric visualization
- A/B testing framework
- Machine learning-based scoring

## References

- **Spec:** `.kiro/specs/llm-context-optimization/`
- **Testing:** `docs/core/TESTING.md`
- **Checkpoint:** `docs/STAGE4_CHECKPOINT.md`
- **Code:** `lib/core/ai/chat/context/`

---

**Maintained by:** Development Team  
**Questions:** See project documentation or contact team
