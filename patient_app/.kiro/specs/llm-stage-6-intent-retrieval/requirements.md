# Requirements Document

## Introduction

The Universal Life Companion app currently includes LLM Context Optimization (Stages 3-4) which filters records by date range and includes up to 20 records in the AI context. While this approach successfully reduces token usage by 51%, it still includes many records that may not be relevant to the user's specific question. Stage 6 introduces Intent-Driven Retrieval, which analyzes the user's query to understand what they're asking about and retrieves only the most relevant records, further improving response quality and token efficiency.

## Glossary

- **Intent Classification**: Analysis of user query to determine purpose (question, command, statement, greeting)
- **Query Analysis**: Process of extracting keywords, entities, and semantic meaning from user input
- **Keyword Extraction**: Identifying important words and phrases from the query
- **Relevance Scoring**: Calculating how well a record matches the user's query
- **Semantic Matching**: Matching based on meaning, not just exact word matches
- **Stemming**: Reducing words to their root form (e.g., "running" → "run")
- **Stop Words**: Common words to ignore (e.g., "the", "is", "at")
- **Entity Recognition**: Identifying specific things mentioned (dates, measurements, categories)
- **Cross-Space Retrieval**: Retrieving records from Spaces other than the active one when explicitly mentioned
- **Privacy Filter**: Excluding records marked as private or sensitive
- **Fallback Strategy**: What to do when no relevant records are found
- **Query Context**: Additional context from conversation history that helps understand the query

## Requirements

### Requirement 1

**User Story:** As a user, I want the AI to understand what I'm asking about, so that it retrieves only relevant information.

#### Acceptance Criteria

1. WHEN a user sends a query, THE System SHALL extract keywords from the query text
2. WHEN extracting keywords, THE System SHALL split on whitespace and punctuation
3. WHEN extracting keywords, THE System SHALL convert to lowercase for case-insensitive matching
4. WHEN extracting keywords, THE System SHALL work for any language (Russian, Uzbek, English, etc.)
5. THE System SHALL log extracted keywords for debugging

### Requirement 2

**User Story:** As a user, I want the AI to classify my intent, so that it can respond appropriately to different types of queries.

#### Acceptance Criteria

1. WHEN analyzing a query, THE System SHALL classify intent as question, command, statement, or greeting
2. WHEN the intent is a question, THE System SHALL prioritize information retrieval
3. WHEN the intent is a command, THE System SHALL prioritize action-oriented responses
4. WHEN the intent is a greeting, THE System SHALL use minimal context
5. THE System SHALL log the classified intent with confidence score

### Requirement 3

**User Story:** As a user, I want the AI to find records that match my question, so that responses are focused and relevant.

#### Acceptance Criteria

1. WHEN matching records, THE System SHALL score each record based on keyword overlap
2. WHEN matching records, THE System SHALL consider record title, category, and notes
3. WHEN matching records, THE System SHALL use case-insensitive matching
4. WHEN matching records, THE System SHALL work for any language without language-specific rules
5. THE System SHALL include only records with relevance score above threshold (0.3)

### Requirement 4

**User Story:** As a user, I want the AI to prioritize the most relevant records, so that the best information is included first.

#### Acceptance Criteria

1. WHEN scoring relevance, THE System SHALL combine keyword match score (60%) and recency score (40%)
2. WHEN multiple records match equally, THE System SHALL prioritize more recent records
3. WHEN records have the same date, THE System SHALL prioritize records with higher view counts
4. THE System SHALL limit results to top 15 most relevant records
5. THE System SHALL log relevance scores for all matched records

### Requirement 5

**User Story:** As a user, I want to ask about information in other Spaces, so that I can get comprehensive answers.

#### Acceptance Criteria

1. WHEN a query explicitly mentions another Space name, THE System SHALL allow cross-space retrieval
2. WHEN retrieving from another Space, THE System SHALL still apply relevance filtering
3. WHEN no Space is mentioned, THE System SHALL only search the active Space
4. WHEN multiple Spaces are mentioned, THE System SHALL search all mentioned Spaces
5. THE System SHALL log which Spaces were searched for each query

### Requirement 6

**User Story:** As a user, I want my private records to remain private, so that sensitive information is never shared with the AI.

#### Acceptance Criteria

1. WHEN retrieving records, THE System SHALL exclude records marked as private
2. WHEN retrieving records, THE System SHALL exclude deleted records
3. WHEN retrieving records, THE System SHALL respect Space permissions
4. THE System SHALL never log private record content
5. THE System SHALL apply privacy filters before relevance scoring

### Requirement 7

**User Story:** As a user, I want helpful responses even when no records match, so that the AI can still assist me.

#### Acceptance Criteria

1. WHEN no records match the query, THE System SHALL inform the user clearly
2. WHEN no records match, THE System SHALL suggest broadening the search
3. WHEN no records match, THE System SHALL offer to search other Spaces
4. WHEN no records match, THE System SHALL still provide general assistance
5. THE System SHALL log when fallback strategies are used

### Requirement 8

**User Story:** As a user, I want the AI to understand context from our conversation, so that follow-up questions work naturally.

#### Acceptance Criteria

1. WHEN analyzing a query, THE System SHALL consider the previous message for context
2. WHEN a query uses pronouns (it, that, them), THE System SHALL resolve references from history
3. WHEN a query is a follow-up, THE System SHALL combine current and previous keywords
4. WHEN conversation context is used, THE System SHALL log the context source
5. THE System SHALL limit context lookback to the last 2 messages

### Requirement 9

**User Story:** As a developer, I want comprehensive logging of retrieval decisions, so that I can debug and optimize the system.

#### Acceptance Criteria

1. WHEN a query is analyzed, THE System SHALL log extracted keywords, entities, and intent
2. WHEN records are scored, THE System SHALL log top 10 scores with record IDs
3. WHEN records are filtered, THE System SHALL log how many were excluded and why
4. WHEN retrieval completes, THE System SHALL log total records considered, matched, and included
5. THE System SHALL log retrieval time and token savings vs Stage 4

### Requirement 10

**User Story:** As a system administrator, I want to measure the impact of intent-driven retrieval, so that I can validate the improvement.

#### Acceptance Criteria

1. THE System SHALL track average records included per query (target: < 10)
2. THE System SHALL track token usage per query (target: 30% less than Stage 4)
3. THE System SHALL track retrieval time (target: < 100ms)
4. THE System SHALL track percentage of queries with zero matches (target: < 5%)
5. THE System SHALL provide a comparison dashboard showing Stage 4 vs Stage 6 metrics

### Requirement 11

**User Story:** As a user, I want the system to handle edge cases gracefully, so that unusual queries don't cause errors.

#### Acceptance Criteria

1. WHEN a query is very short (< 3 words), THE System SHALL fall back to Stage 4 behavior
2. WHEN a query contains only stop words, THE System SHALL use date-based filtering only
3. WHEN a query is very long (> 100 words), THE System SHALL extract top 10 keywords
4. WHEN keyword extraction fails, THE System SHALL fall back to Stage 4 behavior
5. THE System SHALL never crash or throw exceptions during retrieval

### Requirement 12

**User Story:** As a developer, I want to test intent-driven retrieval thoroughly, so that I can ensure correctness.

#### Acceptance Criteria

1. THE System SHALL have unit tests for keyword extraction with various inputs
2. THE System SHALL have unit tests for intent classification with labeled examples
3. THE System SHALL have unit tests for relevance scoring with known matches
4. THE System SHALL have integration tests comparing Stage 4 vs Stage 6 results
5. THE System SHALL have property-based tests for retrieval correctness properties

### Requirement 13

**User Story:** As a user, I want the system to work with the existing date range filter, so that I get both time-based and relevance-based filtering.

#### Acceptance Criteria

1. WHEN intent-driven retrieval is enabled, THE System SHALL first apply date range filtering
2. WHEN date filtering is applied, THE System SHALL then apply relevance filtering
3. WHEN both filters are applied, THE System SHALL log the impact of each filter
4. THE System SHALL allow disabling intent-driven retrieval via configuration
5. THE System SHALL fall back to Stage 4 behavior when intent retrieval is disabled

### Requirement 14

**User Story:** As a developer, I want clear performance targets, so that I can validate the system meets requirements.

#### Acceptance Criteria

1. THE System SHALL complete keyword extraction in < 50ms
2. THE System SHALL complete intent classification in < 30ms
3. THE System SHALL complete relevance scoring in < 100ms for 100 records
4. THE System SHALL complete end-to-end retrieval in < 200ms
5. THE System SHALL achieve 30% token reduction vs Stage 4 on average

### Requirement 15

**User Story:** As a user, I want to provide feedback on retrieval quality, so that the system can improve over time.

#### Acceptance Criteria

1. WHEN an AI response is displayed, THE System SHALL show feedback buttons (already implemented)
2. WHEN feedback is negative, THE System SHALL log which records were included
3. WHEN feedback is negative, THE System SHALL log the query and relevance scores
4. THE System SHALL track retrieval quality metrics (percentage of positive feedback)
5. THE System SHALL alert when retrieval quality drops below 75%

---

## Stage 6 Success Criteria

Stage 6 is considered complete when:

1. ✅ All 15 requirements are implemented and tested
2. ✅ Keyword extraction works for various query types
3. ✅ Intent classification achieves > 80% accuracy on test set
4. ✅ Relevance scoring includes only pertinent records
5. ✅ Token usage is reduced by 30% vs Stage 4
6. ✅ Average records included is < 10 per query
7. ✅ Retrieval time is < 200ms
8. ✅ All automated tests pass
9. ✅ Manual testing validates improved response quality
10. ✅ Documentation is complete

---

**Created:** November 30, 2025  
**Status:** Draft - Ready for review  
**Next Step:** Design document with correctness properties
