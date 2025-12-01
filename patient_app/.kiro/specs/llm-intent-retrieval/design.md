# Design Document

## Overview

Stage 6 introduces Intent-Driven Retrieval to the LLM Context system. While Stage 4 successfully reduced token usage by 51% through date-based filtering, it still includes up to 20 records regardless of relevance to the user's specific question. Stage 6 analyzes the user's query to understand their intent and retrieves only the most relevant records, further improving response quality and token efficiency.

**Current State (Stage 4):**
- Date-based filtering (7/14/30/90 days)
- Up to 20 most recent records
- 51% token savings vs baseline
- ~400 tokens per query (14-day filter)

**Target State (Stage 6):**
- Intent-driven retrieval
- Only relevant records (target: < 10)
- 30% additional token savings vs Stage 4
- ~280 tokens per query
- Better response quality (more focused)

## Architecture

### High-Level Flow

```
User Query
    ↓
Query Analyzer
    ├→ Keyword Extractor (remove stop words, stem)
    ├→ Entity Recognizer (dates, measurements, categories)
    └→ Intent Classifier (question/command/statement/greeting)
    ↓
Context Builder (Stage 4)
    ├→ Date Range Filter (existing)
    └→ Records Pool (e.g., 30 records)
    ↓
Intent-Driven Retriever (NEW)
    ├→ Relevance Scorer (keyword match + recency)
    ├→ Privacy Filter (exclude private/deleted)
    ├→ Cross-Space Handler (if mentioned)
    └→ Top-K Selector (top 15 matches)
    ↓
Context Truncator (Stage 4)
    └→ Final Context (< 10 records typically)
    ↓
LLM Request
```

### Component Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    SendChatMessageUseCase                │
└────────────────────┬────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
┌────────▼────────┐    ┌────────▼──────────┐
│  QueryAnalyzer  │    │ SpaceContextBuilder│
│   (NEW)         │    │   (Stage 4)        │
└────────┬────────┘    └────────┬───────────┘
         │                      │
    ┌────┴─────┐               │
    │          │               │
┌───▼──┐  ┌───▼──┐            │
│Keyword│  │Intent│            │
│Extract│  │Class │            │
└───────┘  └──────┘            │
                               │
                    ┌──────────▼──────────┐
                    │ IntentDrivenRetriever│
                    │      (NEW)           │
                    └──────────┬───────────┘
                               │
                    ┌──────────┴───────────┐
                    │                      │
            ┌───────▼────────┐   ┌────────▼────────┐
            │RelevanceScorer │   │ PrivacyFilter   │
            │    (NEW)       │   │    (NEW)        │
            └────────────────┘   └─────────────────┘
```

## Components and Interfaces

### 1. QueryAnalyzer

**Purpose:** Analyze user query to extract keywords, entities, and intent.

**Interface:**
```dart
class QueryAnalyzer {
  QueryAnalysis analyze(String query, {List<ChatMessage>? history});
}

class QueryAnalysis {
  final List<String> keywords;
  final List<Entity> entities;
  final QueryIntent intent;
  final double intentConfidence;
}

enum QueryIntent {
  question,    // "What is my blood pressure?"
  command,     // "Show me my records"
  statement,   // "I took my medication"
  greeting,    // "Hello"
}

class Entity {
  final EntityType type;
  final String value;
  final String normalized;
}

enum EntityType {
  date,           // "last week", "yesterday"
  measurement,    // "120/80", "5.5 mmol/L"
  category,       // "blood pressure", "medication"
  spaceName,      // "Health", "Fitness"
}
```

**Responsibilities:**
- Extract keywords (remove stop words, apply stemming)
- Recognize entities (dates, measurements, categories)
- Classify intent with confidence score
- Consider conversation history for context
- Handle edge cases (very short/long queries)

### 2. KeywordExtractor

**Purpose:** Extract keywords from query text (language-agnostic).

**Interface:**
```dart
class KeywordExtractor {
  List<String> extract(String text);
}
```

**Extraction Rules (Language-Agnostic):**
```dart
// 1. Split on whitespace and punctuation
// 2. Convert to lowercase for matching
// 3. Keep all words (no stop word removal)
// 4. No stemming (works for all languages)
// 5. Remove very short words (< 2 characters)

Examples (Health Space):
"What is my blood pressure?" → ["what", "is", "my", "blood", "pressure"]
"Какое у меня давление?" → ["какое", "у", "меня", "давление"]

Examples (Finance Space):
"Show my expenses this month" → ["show", "my", "expenses", "this", "month"]
"Mening xarajatlarim?" → ["mening", "xarajatlarim"]

Examples (Education Space):
"What did I study yesterday?" → ["what", "did", "study", "yesterday"]
"Mes notes de mathématiques?" → ["mes", "notes", "de", "mathématiques"]

Examples (Travel Space):
"Where did I go last week?" → ["where", "did", "go", "last", "week"]
"Куда я ездил?" → ["куда", "я", "ездил"]
```

**Why Language-Agnostic:**
- Works for Russian, Uzbek, English, French, any language
- No language detection needed
- No language-specific dictionaries
- Simpler and more maintainable
- Relevance scoring still effective

### 3. IntentClassifier

**Purpose:** Classify query intent using pattern matching.

**Interface:**
```dart
class IntentClassifier {
  IntentClassification classify(String query, List<String> keywords);
}

class IntentClassification {
  final QueryIntent intent;
  final double confidence;
}
```

**Classification Rules (Language-Agnostic):**
```dart
// Question pattern (universal)
if (query.contains('?')) {
  return QueryIntent.question;
}

// Very short query (1-2 words) = likely greeting
if (keywords.length <= 2) {
  return QueryIntent.greeting;
}

// Default to question (most common, safest for retrieval)
return QueryIntent.question;
```

**Why Simplified:**
- Works for all languages (?, length are universal)
- No language-specific patterns needed
- Defaults to question (best for information retrieval)
- Simpler and more reliable

### 4. IntentDrivenRetriever

**Purpose:** Retrieve only relevant records based on query analysis.

**Interface:**
```dart
class IntentDrivenRetriever {
  Future<RetrievalResult> retrieve({
    required QueryAnalysis query,
    required List<Record> candidateRecords,
    required String activeSpaceId,
    int maxResults = 15,
  });
}

class RetrievalResult {
  final List<ScoredRecord> records;
  final RetrievalStats stats;
}

class ScoredRecord {
  final Record record;
  final double relevanceScore;
  final double keywordMatchScore;
  final double recencyScore;
}

class RetrievalStats {
  final int recordsConsidered;
  final int recordsMatched;
  final int recordsIncluded;
  final int recordsExcludedPrivacy;
  final int recordsExcludedThreshold;
  final Duration retrievalTime;
}
```

### 5. RelevanceScorer

**Purpose:** Score records based on keyword match and recency.

**Interface:**
```dart
class RelevanceScorer {
  double score({
    required Record record,
    required List<String> keywords,
    required DateTime now,
  });
  
  double keywordMatchScore(Record record, List<String> keywords);
  double recencyScore(Record record, DateTime now);
}
```

**Scoring Formula:**
```dart
relevanceScore = (keywordMatchScore * 0.6) + (recencyScore * 0.4)

keywordMatchScore = matchedKeywords / totalKeywords

recencyScore = 1.0 - (daysSinceCreated / 90.0)  // 0-90 days
```

**Keyword Matching:**
```dart
// Search in: title, category, notes
// Case-insensitive, stemmed matching
// Each field weighted equally
```

### 6. PrivacyFilter

**Purpose:** Exclude private and deleted records.

**Interface:**
```dart
class PrivacyFilter {
  List<Record> filter(List<Record> records);
  bool isAllowed(Record record);
}
```

**Filter Rules:**
```dart
// Exclude if:
- record.isDeleted == true
- record.isPrivate == true
- record.spaceId not in allowedSpaces
```

## Data Models

### QueryAnalysis

```dart
class QueryAnalysis {
  final String originalQuery;
  final List<String> keywords;
  final List<Entity> entities;
  final QueryIntent intent;
  final double intentConfidence;
  final QueryContext? context;
  
  const QueryAnalysis({
    required this.originalQuery,
    required this.keywords,
    required this.entities,
    required this.intent,
    required this.intentConfidence,
    this.context,
  });
}
```

### Entity

```dart
class Entity {
  final EntityType type;
  final String value;
  final String normalized;
  
  const Entity({
    required this.type,
    required this.value,
    required this.normalized,
  });
}
```

### RetrievalResult

```dart
class RetrievalResult {
  final List<ScoredRecord> records;
  final RetrievalStats stats;
  
  const RetrievalResult({
    required this.records,
    required this.stats,
  });
}
```

### ScoredRecord

```dart
class ScoredRecord {
  final Record record;
  final double relevanceScore;
  final double keywordMatchScore;
  final double recencyScore;
  
  const ScoredRecord({
    required this.record,
    required this.relevanceScore,
    required this.keywordMatchScore,
    required this.recencyScore,
  });
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Keyword Extraction is Language-Agnostic

*For any* query text in any language (English, Russian, Uzbek, etc.), keywords should be extracted successfully.

**Validates: Requirements 1.4**

### Property 2: Keyword Extraction Preserves All Words

*For any* query text, all words (after splitting and lowercasing) should be included as keywords, regardless of language.

**Validates: Requirements 1.2**

### Property 3: Intent Classification is Deterministic

*For any* query text, classifying intent multiple times should always return the same intent and confidence score.

**Validates: Requirements 2.1**

### Property 4: Relevance Score is Bounded

*For any* record and query, the relevance score should be between 0.0 and 1.0 inclusive.

**Validates: Requirements 3.1, 4.1**

### Property 5: Threshold Filtering Excludes Low Scores

*For any* set of scored records, when filtered by threshold 0.3, all included records should have relevance score >= 0.3.

**Validates: Requirements 3.5**

### Property 6: Case-Insensitive Matching

*For any* query and record, changing the case of text should not affect whether they match.

**Validates: Requirements 3.3**

### Property 7: Language-Agnostic Matching

*For any* query and record in the same language, keyword matching should work correctly regardless of the language.

**Validates: Requirements 3.4**

### Property 8: Top-K Limit is Enforced

*For any* retrieval result, the number of records included should never exceed 15.

**Validates: Requirements 4.4**

### Property 9: Recency Tie-Breaking

*For any* two records with equal keyword match scores, the more recent record should have a higher final relevance score.

**Validates: Requirements 4.2**

### Property 10: View Count Tie-Breaking

*For any* two records with equal relevance scores and same date, the record with higher view count should be ranked higher.

**Validates: Requirements 4.3**

### Property 11: Privacy Filter Excludes Private Records

*For any* set of records including private ones, the filtered result should contain no records where isPrivate == true.

**Validates: Requirements 6.1**

### Property 12: Privacy Filter Excludes Deleted Records

*For any* set of records including deleted ones, the filtered result should contain no records where isDeleted == true.

**Validates: Requirements 6.2**

### Property 13: Privacy Filtering Before Scoring

*For any* retrieval operation, private records should never appear in relevance scoring logs.

**Validates: Requirements 6.5**

### Property 14: Space Isolation by Default

*For any* query without Space mentions, only records from the active Space should be included in results.

**Validates: Requirements 5.3**

### Property 15: Cross-Space Retrieval When Mentioned

*For any* query explicitly mentioning another Space name, records from that Space should be included in results.

**Validates: Requirements 5.1**

### Property 16: Date Filter Applied First

*For any* retrieval operation, records outside the date range should never reach relevance scoring.

**Validates: Requirements 13.1, 13.2**

### Property 17: Fallback to Stage 4 on Short Queries

*For any* query with fewer than 3 words, the system should use Stage 4 behavior (date-based only).

**Validates: Requirements 11.1**

### Property 18: Fallback to Stage 4 on Stop-Word-Only Queries

*For any* query containing only stop words, the system should use Stage 4 behavior.

**Validates: Requirements 11.2**

### Property 19: No Crashes on Any Input

*For any* query text (including empty, very long, special characters), the system should never throw unhandled exceptions.

**Validates: Requirements 11.5**

### Property 20: Context Lookback Limit

*For any* query analysis using conversation history, at most the last 2 messages should be considered.

**Validates: Requirements 8.5**

## Error Handling

### Keyword Extraction Failures

**Scenario:** Query contains only special characters or emojis

**Handling:**
1. Return empty keyword list
2. Fall back to Stage 4 behavior (date-based filtering)
3. Log fallback event
4. Continue processing normally

### Intent Classification Failures

**Scenario:** Unable to classify intent with confidence

**Handling:**
1. Default to QueryIntent.question
2. Set confidence to 0.5
3. Log low-confidence classification
4. Continue with retrieval

### Relevance Scoring Failures

**Scenario:** Record has null or invalid fields

**Handling:**
1. Skip null fields in matching
2. Use default score of 0.0 for invalid records
3. Log warning
4. Continue with other records

### Zero Matches

**Scenario:** No records match the query

**Handling:**
1. Return empty result set
2. Log zero-match event
3. Backend should suggest broadening search
4. Fall back to general assistance

## Testing Strategy

### Unit Tests

**Keyword Extraction:**
- Test stop word removal
- Test stemming rules
- Test empty input
- Test special characters
- Test very long input

**Intent Classification:**
- Test question patterns
- Test command patterns
- Test greeting patterns
- Test statement patterns
- Test ambiguous queries

**Relevance Scoring:**
- Test keyword matching
- Test recency calculation
- Test combined score
- Test edge cases (null fields)

**Privacy Filtering:**
- Test private record exclusion
- Test deleted record exclusion
- Test Space permission enforcement

### Property-Based Tests

**Property 1-20:** Implement each correctness property as a property-based test using the test framework.

**Test Configuration:**
- Minimum 100 iterations per property
- Random query generation
- Random record generation
- Edge case injection

### Integration Tests

**End-to-End Retrieval:**
1. Create test Space with 50 records
2. Send query: "What was my blood pressure last week?"
3. Verify only BP records from last 7 days included
4. Verify < 10 records in result
5. Verify token usage < Stage 4

**Cross-Space Retrieval:**
1. Create two Spaces (Health, Fitness)
2. Send query: "Compare my Health and Fitness records"
3. Verify records from both Spaces included
4. Verify relevance filtering applied to both

**Fallback Scenarios:**
1. Test very short query → Stage 4 behavior
2. Test stop-word-only query → Stage 4 behavior
3. Test keyword extraction failure → Stage 4 behavior

### Performance Tests

**Benchmarks:**
- Keyword extraction: < 50ms
- Intent classification: < 30ms
- Relevance scoring (100 records): < 100ms
- End-to-end retrieval: < 200ms

**Load Tests:**
- 100 concurrent queries
- 1000 records in Space
- Verify performance targets met

## Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| Keyword extraction time | < 50ms | Average over 100 queries |
| Intent classification time | < 30ms | Average over 100 queries |
| Relevance scoring time | < 100ms | For 100 records |
| End-to-end retrieval time | < 200ms | Total time |
| Average records included | < 10 | Per query |
| Token usage reduction | 30% vs Stage 4 | Average over test set |
| Zero-match rate | < 5% | Percentage of queries |
| Retrieval quality | > 75% positive feedback | User feedback |

## Logging Strategy

### Query Analysis Logging

```dart
await AppLogger.info('Query analyzed', context: {
  'category': 'intent_retrieval',
  'event': 'query_analysis',
  'originalQuery': query,
  'keywords': keywords,
  'keywordCount': keywords.length,
  'entities': entities.map((e) => e.toJson()).toList(),
  'intent': intent.name,
  'intentConfidence': intentConfidence,
  'analysisTimeMs': duration.inMilliseconds,
});
```

### Retrieval Logging

```dart
await AppLogger.info('Intent-driven retrieval complete', context: {
  'category': 'intent_retrieval',
  'event': 'retrieval_complete',
  'recordsConsidered': stats.recordsConsidered,
  'recordsMatched': stats.recordsMatched,
  'recordsIncluded': stats.recordsIncluded,
  'recordsExcludedPrivacy': stats.recordsExcludedPrivacy,
  'recordsExcludedThreshold': stats.recordsExcludedThreshold,
  'topScores': topScores,
  'retrievalTimeMs': stats.retrievalTime.inMilliseconds,
  'tokenSavingsVsStage4': tokenSavings,
});
```

### Performance Logging

```dart
await AppLogger.info('Retrieval performance', context: {
  'category': 'intent_retrieval',
  'event': 'performance',
  'keywordExtractionMs': keywordTime,
  'intentClassificationMs': intentTime,
  'relevanceScoringMs': scoringTime,
  'totalRetrievalMs': totalTime,
  'recordsPerSecond': recordsPerSecond,
});
```

## Configuration

### IntentRetrievalConfig

```dart
class IntentRetrievalConfig {
  final bool enabled;
  final double relevanceThreshold;
  final int maxResults;
  final int minQueryWords;
  final int maxKeywords;
  final int contextLookback;
  final bool allowCrossSpace;
  
  const IntentRetrievalConfig({
    this.enabled = true,
    this.relevanceThreshold = 0.3,
    this.maxResults = 15,
    this.minQueryWords = 3,
    this.maxKeywords = 10,
    this.contextLookback = 2,
    this.allowCrossSpace = true,
  });
}
```

## Migration from Stage 4

### Backward Compatibility

- Stage 6 builds on Stage 4, doesn't replace it
- Date range filtering still applied first
- Can disable intent retrieval via config
- Falls back to Stage 4 on errors
- All Stage 4 features preserved

### Gradual Rollout

1. Deploy with `enabled = false` initially
2. Enable for internal testing
3. Enable for beta users
4. Monitor metrics and feedback
5. Enable for all users
6. Optimize based on data

## Success Metrics

### Primary Metrics

1. **Token Reduction:** 30% less than Stage 4 (target: ~280 tokens vs ~400)
2. **Records Included:** < 10 per query on average
3. **Retrieval Time:** < 200ms end-to-end
4. **Zero-Match Rate:** < 5% of queries

### Secondary Metrics

1. **User Feedback:** > 75% positive (thumbs up)
2. **Response Quality:** Maintained or improved vs Stage 4
3. **Fallback Rate:** < 10% of queries fall back to Stage 4
4. **Cross-Space Usage:** Track how often users mention other Spaces

### Monitoring Dashboard

Display real-time metrics:
- Average records per query (Stage 4 vs Stage 6)
- Average tokens per query (Stage 4 vs Stage 6)
- Retrieval time distribution
- Intent classification breakdown
- Zero-match rate trend
- User feedback scores

---

**Created:** November 30, 2025  
**Status:** Complete - Ready for task creation  
**Next Step:** Create implementation task list
