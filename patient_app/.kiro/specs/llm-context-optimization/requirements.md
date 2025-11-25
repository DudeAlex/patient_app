# Requirements Document

## Introduction

The Universal Life Companion app now has a working HTTP foundation and basic LLM integration (Stages 1-2 complete). The AI can generate responses with conversation history, but it lacks awareness of the user's personal information. This specification defines Stages 3-4: introducing Space Context (Stage 3) and implementing Context Optimization (Stage 4). These stages enable the AI to reference the user's actual records while managing token budgets efficiently.

## Glossary

- **Space Context**: User's active Space and recent records provided to LLM for awareness
- **Record Summary**: Condensed version of a record (title, type, date, tags, brief notes)
- **Token Budget**: Maximum number of tokens allocated for a request (system + context + history + response)
- **Context Window**: Time range or record count limit for including user data in LLM prompts
- **Token Allocation**: Distribution of token budget across different prompt sections
- **Context Truncation**: Removing records to fit within token budget
- **Relevance Score**: Numeric value indicating how important a record is for the current conversation
- **Date Range Filter**: Limiting records by creation date (e.g., last 14 days)
- **Space Filtering**: Including only records from the active Space

## Requirements

### Requirement 1

**User Story:** As a user, I want the AI to be aware of my active Space, so that responses use appropriate terminology and context.

#### Acceptance Criteria

1. WHEN generating a response, THE System SHALL include the active Space name in the prompt
2. WHEN generating a response, THE System SHALL include the Space description in the prompt
3. WHEN generating a response, THE System SHALL include the Space categories in the prompt
4. THE System SHALL never include information from Spaces other than the active Space
5. THE System SHALL update Space context when the user switches Spaces

### Requirement 2

**User Story:** As a user, I want the AI to reference my recent records, so that responses are relevant to my personal information.

#### Acceptance Criteria

1. WHEN generating a response, THE System SHALL include summaries of recent records from the active Space
2. WHEN including record summaries, THE System SHALL include title, type, date, and tags
3. WHEN including record summaries, THE System SHALL truncate notes to 100 characters maximum
4. THE System SHALL exclude deleted records from context
5. THE System SHALL limit initial context to the last 10 records

### Requirement 3

**User Story:** As a system administrator, I want to control token usage, so that API costs remain predictable.

#### Acceptance Criteria

1. THE System SHALL enforce a total token budget of 4000 tokens per request (Stage 3)
2. THE System SHALL allocate tokens as: system (500), context (1500), history (1000), response (1000)
3. WHEN context exceeds budget, THE System SHALL truncate to fit
4. THE System SHALL log token allocation breakdown for every request
5. THE System SHALL alert when token budget is consistently exceeded

### Requirement 4

**User Story:** As a developer, I want to filter records by date range, so that only relevant recent information is included.

#### Acceptance Criteria

1. THE System SHALL provide configurable date range filter (default 14 days)
2. WHEN filtering records, THE System SHALL include only records created within the date range
3. THE System SHALL support date range options: 7 days, 14 days, 30 days
4. THE System SHALL log the date range used for each request
5. THE System SHALL allow users to adjust date range via Settings

### Requirement 5

**User Story:** As a developer, I want to limit the number of records in context, so that token usage is controlled.

#### Acceptance Criteria

1. THE System SHALL limit context to a maximum of 20 records after filtering
2. WHEN more than 20 records match filters, THE System SHALL select the most relevant
3. THE System SHALL prioritize recent records over older records
4. THE System SHALL log the number of records filtered vs included
5. THE System SHALL provide configuration for maximum record count

### Requirement 6

**User Story:** As a developer, I want to score record relevance, so that the most important records are included.

#### Acceptance Criteria

1. THE System SHALL calculate relevance score for each record
2. WHEN scoring relevance, THE System SHALL weight recency higher (newer = higher score)
3. WHEN scoring relevance, THE System SHALL weight access frequency (frequently viewed = higher score)
4. THE System SHALL sort records by relevance score descending
5. THE System SHALL log relevance scores for debugging

### Requirement 7

**User Story:** As a developer, I want to allocate token budget strategically, so that the most important information fits.

#### Acceptance Criteria

1. THE System SHALL allocate token budget across: system, context, history, response
2. THE System SHALL reserve minimum 1000 tokens for response
3. WHEN context exceeds allocated budget, THE System SHALL truncate lowest-scoring records first
4. THE System SHALL never truncate system prompt or response reservation
5. THE System SHALL log actual vs allocated token usage

### Requirement 8

**User Story:** As a user, I want the AI to acknowledge when information might be incomplete, so that I understand context limitations.

#### Acceptance Criteria

1. WHEN records are truncated due to token budget, THE System SHALL include a note in the prompt
2. WHEN date range excludes older records, THE System SHALL mention the time window in the prompt
3. WHEN the AI responds, THE System SHALL acknowledge if information might be incomplete
4. THE System SHALL suggest exploring other time periods if relevant
5. THE System SHALL never fabricate information to fill gaps

### Requirement 9

**User Story:** As a developer, I want comprehensive logging of context assembly, so that I can diagnose issues and optimize performance.

#### Acceptance Criteria

1. WHEN context is assembled, THE System SHALL log records filtered, records included, and token estimate
2. WHEN context is assembled, THE System SHALL log assembly time in milliseconds
3. WHEN context is assembled, THE System SHALL log date range and relevance scores
4. THE System SHALL log truncation events with reason
5. THE System SHALL provide context assembly metrics in response metadata

### Requirement 10

**User Story:** As a developer, I want to test context optimization, so that I can validate correctness and performance.

#### Acceptance Criteria

1. THE System SHALL have unit tests for date range filtering
2. THE System SHALL have unit tests for relevance scoring
3. THE System SHALL have unit tests for token budget allocation
4. THE System SHALL have integration tests for complete context assembly
5. THE System SHALL have property-based tests for token budget enforcement

### Requirement 11

**User Story:** As a user, I want consistent AI behavior when Space context is added, so that the transition is smooth.

#### Acceptance Criteria

1. WHEN Space context is added (Stage 3), THE System SHALL maintain conversation continuity
2. WHEN Space context is added, THE System SHALL not break existing functionality
3. WHEN Space context is added, THE System SHALL improve response relevance
4. THE System SHALL track response quality before and after Stage 3
5. THE System SHALL maintain response latency within acceptable limits (< 5s p95)

### Requirement 12

**User Story:** As a developer, I want clear documentation of context structure, so that I can debug and extend the system.

#### Acceptance Criteria

1. THE System SHALL document the context payload structure
2. THE System SHALL document token allocation strategy
3. THE System SHALL document relevance scoring algorithm
4. THE System SHALL provide examples of context assembly
5. THE System SHALL document performance benchmarks

### Requirement 13

**User Story:** As a system administrator, I want to monitor context optimization effectiveness, so that I can tune parameters.

#### Acceptance Criteria

1. THE System SHALL track average records included per request
2. THE System SHALL track average token usage per request
3. THE System SHALL track context assembly time
4. THE System SHALL track truncation frequency
5. THE System SHALL provide dashboard showing context metrics

### Requirement 14

**User Story:** As a user, I want the AI to reference my actual records in responses, so that I know it understands my information.

#### Acceptance Criteria

1. WHEN the AI responds, THE System SHALL reference specific records by title when relevant
2. WHEN the AI responds, THE System SHALL mention dates and categories from records
3. WHEN the AI responds, THE System SHALL provide actionable suggestions based on records
4. THE System SHALL never reference records that weren't in the context
5. THE System SHALL track how often AI responses reference user records

### Requirement 15

**User Story:** As a developer, I want to validate that context optimization improves response quality, so that I can justify the complexity.

#### Acceptance Criteria

1. THE System SHALL collect user feedback on response quality (thumbs up/down)
2. THE System SHALL compare feedback scores before and after Stage 4
3. THE System SHALL track response relevance improvement
4. THE System SHALL measure token savings from optimization
5. THE System SHALL provide A/B testing capability for optimization strategies
