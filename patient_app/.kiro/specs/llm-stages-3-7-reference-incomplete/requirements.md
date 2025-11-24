# Requirements Document

## Introduction

The Universal Life Companion app currently has a fully functional AI Chat Companion interface with complete UI, persistence, and state management. The system currently operates with a FakeAiChatService that provides deterministic responses for development and testing. This specification defines the multi-stage evolution to integrate a real Large Language Model (LLM) backend, progressing from basic HTTP connectivity through to a fully intelligent contextual AI system with token optimization, intent-driven retrieval, and robust error handling.

## Glossary

- **LLM**: Large Language Model - AI system that generates human-like text responses
- **Backend Proxy**: Server-side component that mediates between Flutter client and LLM provider
- **Token**: Unit of text processed by LLM (roughly 4 characters or 0.75 words)
- **Token Budget**: Maximum number of tokens allocated for a request (system + context + history + response)
- **Context Window**: Time range or record count limit for including user data in LLM prompts
- **System Prompt**: Base instructions that define AI behavior and persona
- **Message History**: Previous conversation turns included as context for continuity
- **Space Context**: User's active Space and recent records provided to LLM for awareness
- **Context Compression**: Technique to reduce token usage by summarizing or deduplicating information
- **Intent Classification**: Analysis of user query to determine purpose (question/command/statement)
- **RAG**: Retrieval-Augmented Generation - selecting relevant data based on query intent
- **Exponential Backoff**: Retry strategy with increasing delays (1s, 2s, 4s, etc.)
- **Correlation ID**: Unique identifier linking request/response pairs for debugging
- **Telemetry**: Automated collection of usage metrics and performance data
- **AI Persona**: Tone and behavior the AI adopts based on Space (empathetic for Health, study-focused for Education)

## Requirements

### Requirement 1

**User Story:** As a developer, I want to establish HTTP connectivity between Flutter and backend, so that I can verify the communication pipeline before integrating LLM.

#### Acceptance Criteria

1. WHEN Flutter sends a ChatRequest to the backend echo endpoint, THE System SHALL return a ChatResponse with echoed message
2. WHEN a request times out after 30 seconds, THE System SHALL throw TimeoutException
3. WHEN a request fails, THE System SHALL retry up to 3 times with exponential backoff (1s, 2s, 4s)
4. WHEN network is unavailable, THE System SHALL throw NetworkException
5. THE System SHALL log every request with correlation ID, timestamp, and duration

### Requirement 2

**User Story:** As a developer, I want the backend to connect to a real LLM provider, so that users can receive intelligent AI-generated responses.

#### Acceptance Criteria

1. WHEN the backend receives a ChatRequest, THE System SHALL construct a prompt with system instructions and user message
2. WHEN the backend calls the LLM API, THE System SHALL include the last 3 conversation turns for context
3. WHEN the LLM responds, THE System SHALL return a valid ChatResponse with message content
4. THE System SHALL log token usage (prompt tokens, completion tokens, total) for every LLM call
5. WHEN the LLM API returns an error, THE System SHALL classify the error and determine if it's retryable

### Requirement 3

**User Story:** As a user, I want the AI to be aware of my Space context and recent records, so that responses are relevant to my personal information.

#### Acceptance Criteria

1. WHEN generating a response, THE System SHALL include the active Space name and description in the prompt
2. WHEN generating a response, THE System SHALL include summaries of the last 10 records from the active Space
3. WHEN including record summaries, THE System SHALL truncate each summary to 100 characters maximum
4. THE System SHALL never include records from Spaces other than the active Space
5. THE System SHALL limit Space context to a maximum of 1500 tokens

### Requirement 4

**User Story:** As a system administrator, I want to control token usage through filtering and budgets, so that API costs remain predictable and manageable.

#### Acceptance Criteria

1. WHEN building context, THE System SHALL filter records by a configurable date range (default 14 days)
2. WHEN building context, THE System SHALL limit the number of records to a maximum of 20
3. WHEN building context, THE System SHALL allocate tokens according to a budget: system (800), context (2000), history (1000), response (1000)
4. WHEN the context exceeds the token budget, THE System SHALL truncate older records first
5. THE System SHALL log the token allocation breakdown for every request

### Requirement 5

**User Story:** As a system administrator, I want to compress context through summarization and deduplication, so that more information fits within the token budget.

#### Acceptance Criteria

1. WHEN a record is less than 7 days old, THE System SHALL include full detail (100 tokens)
2. WHEN a record is 7-30 days old, THE System SHALL include a moderate summary (50 tokens)
3. WHEN a record is more than 30 days old, THE System SHALL include a minimal summary (25 tokens)
4. WHEN multiple records contain duplicate information, THE System SHALL deduplicate and include only once
5. THE System SHALL cache generated summaries for 7 days to avoid reprocessing

### Requirement 6

**User Story:** As a user, I want the AI to retrieve only relevant records based on my query, so that responses are focused and token-efficient.

#### Acceptance Criteria

1. WHEN analyzing a user query, THE System SHALL extract keywords and classify intent (question/command/statement)
2. WHEN retrieving records, THE System SHALL match records against query keywords using case-insensitive stemmed matching
3. WHEN retrieving records, THE System SHALL score relevance and include only the top 15 matches
4. WHEN a query explicitly mentions another Space, THE System SHALL allow cross-space retrieval
5. THE System SHALL enforce privacy filters and exclude records marked "private"

### Requirement 7

**User Story:** As a user, I want the AI system to handle errors gracefully and recover automatically, so that temporary failures don't disrupt my experience.

#### Acceptance Criteria

1. WHEN an LLM request fails, THE System SHALL attempt up to 2 recovery strategies before giving up
2. WHEN the LLM provider is rate-limited, THE System SHALL wait and retry after the specified delay
3. WHEN the LLM returns an incomplete response, THE System SHALL request continuation or return partial result
4. WHEN the backend is unavailable, THE System SHALL fall back to FakeAiChatService with a notification
5. THE System SHALL log all error recovery attempts with correlation IDs for debugging

### Requirement 8

**User Story:** As a user, I want to interact with different AI personas based on my Space, so that the tone and guidance match the domain.

#### Acceptance Criteria

1. WHEN the active Space is Health, THE System SHALL use an empathetic, cautious persona with safety disclaimers
2. WHEN the active Space is Education, THE System SHALL use a study-focused, constructive persona
3. WHEN the active Space is Finance, THE System SHALL use a practical, budget-conscious persona
4. WHEN the active Space is Travel, THE System SHALL use an exploratory, planning-focused persona
5. THE System SHALL allow switching personas mid-conversation when the user changes Space context

### Requirement 9

**User Story:** As a system administrator, I want comprehensive telemetry and analytics, so that I can monitor system health and optimize performance.

#### Acceptance Criteria

1. THE System SHALL track request rate per minute, hour, and day
2. THE System SHALL track average response latency and token usage
3. THE System SHALL track error rate by type (network, timeout, server, validation)
4. THE System SHALL track context assembly time and cache hit rate
5. THE System SHALL provide a dashboard showing all metrics in real-time

### Requirement 10

**User Story:** As a developer, I want to extend the AI system with tool hooks, so that future features like web search or calculations can be integrated.

#### Acceptance Criteria

1. THE System SHALL provide a tool registry where new capabilities can be registered
2. WHEN the LLM response indicates a tool should be invoked, THE System SHALL call the appropriate tool
3. WHEN a tool completes, THE System SHALL include the tool result in the next LLM request
4. THE System SHALL log all tool invocations with parameters and results
5. THE System SHALL handle tool failures gracefully without breaking the conversation

### Requirement 11

**User Story:** As a user, I want to provide feedback on AI responses, so that the system can learn and improve over time.

#### Acceptance Criteria

1. WHEN an AI response is displayed, THE System SHALL show thumbs up/down feedback buttons
2. WHEN a user provides feedback, THE System SHALL store the feedback with the message ID
3. THE System SHALL track conversation quality metrics (percentage of positive feedback)
4. WHEN quality drops below 80%, THE System SHALL alert administrators
5. THE System SHALL never associate feedback with personally identifiable information

### Requirement 12

**User Story:** As a developer, I want clear stage boundaries and acceptance criteria, so that I can deliver incremental value and validate each stage independently.

#### Acceptance Criteria

1. WHEN Stage 1 is complete, THE System SHALL successfully echo messages via HTTP with retry logic
2. WHEN Stage 2 is complete, THE System SHALL generate LLM responses with basic history context
3. WHEN Stage 3 is complete, THE System SHALL include Space context and recent records in prompts
4. WHEN Stage 4 is complete, THE System SHALL filter and budget context within token limits
5. WHEN Stage 5 is complete, THE System SHALL compress context through summarization and caching
6. WHEN Stage 6 is complete, THE System SHALL retrieve records based on query intent
7. WHEN Stage 7 is complete, THE System SHALL provide production-ready AI with personas, telemetry, and tools

### Requirement 13

**User Story:** As a system administrator, I want to enforce privacy and security rules, so that sensitive user data is protected.

#### Acceptance Criteria

1. THE System SHALL never send Information Item IDs or encryption keys off-device
2. THE System SHALL redact sensitive fields (names, addresses, SSNs) from logs
3. THE System SHALL enforce rate limits: 10 requests/minute, 100 requests/hour, 500 requests/day per user
4. THE System SHALL validate all input and reject malformed requests
5. THE System SHALL use HTTPS only for all backend communication

### Requirement 14

**User Story:** As a developer, I want to switch between Fake and HTTP AI services via configuration, so that I can develop and test without external dependencies.

#### Acceptance Criteria

1. WHEN ai_mode is 'fake', THE System SHALL use FakeAiChatService for all chat operations
2. WHEN ai_mode is 'http', THE System SHALL use HttpAiChatService for all chat operations
3. THE System SHALL allow switching modes via Settings without losing chat history
4. THE System SHALL display the current AI mode in the chat header status pill
5. THE System SHALL handle mode transitions gracefully with appropriate user feedback

### Requirement 15

**User Story:** As a user, I want the system to work offline and queue messages, so that I can continue using the app without connectivity.

#### Acceptance Criteria

1. WHEN network is unavailable, THE System SHALL queue messages locally
2. WHEN connectivity is restored, THE System SHALL automatically retry queued messages
3. THE System SHALL show an offline indicator in the chat header
4. THE System SHALL implement exponential backoff for retry attempts
5. THE System SHALL allow viewing chat history even when offline

### Requirement 16

**User Story:** As a developer, I want detailed logging at every stage, so that I can diagnose issues and monitor system behavior.

#### Acceptance Criteria

1. WHEN a request is received, THE System SHALL log the event with correlation ID, user ID, thread ID, and stage
2. WHEN context is assembled, THE System SHALL log records filtered, records included, token estimate, and assembly time
3. WHEN an LLM request is sent, THE System SHALL log provider, model, prompt tokens, and timestamp
4. WHEN an LLM response is received, THE System SHALL log completion tokens, total tokens, finish reason, and latency
5. WHEN an error occurs, THE System SHALL log error code, message, stage, and whether it's retryable

### Requirement 17

**User Story:** As a system administrator, I want to monitor and control costs, so that LLM usage remains within budget.

#### Acceptance Criteria

1. THE System SHALL track token usage per user per day
2. THE System SHALL implement soft limits (warn at 80% of daily budget)
3. THE System SHALL implement hard limits (block at 100% of daily budget)
4. THE System SHALL provide a usage dashboard showing per-user and aggregate consumption
5. THE System SHALL alert administrators on unusual usage patterns (10x normal)

### Requirement 18

**User Story:** As a developer, I want comprehensive test coverage at each stage, so that I can validate correctness and prevent regressions.

#### Acceptance Criteria

1. WHEN Stage 1 is tested, THE System SHALL verify HTTP connectivity, timeouts, retries, and error handling
2. WHEN Stage 2 is tested, THE System SHALL verify LLM integration, token counting, and response parsing
3. WHEN Stage 3 is tested, THE System SHALL verify Space context inclusion and record filtering
4. WHEN Stage 4 is tested, THE System SHALL verify token budgets, date filtering, and truncation
5. WHEN Stage 5 is tested, THE System SHALL verify compression, deduplication, and caching
6. WHEN Stage 6 is tested, THE System SHALL verify intent classification, relevance scoring, and privacy filters
7. WHEN Stage 7 is tested, THE System SHALL verify personas, error recovery, telemetry, and tool invocation

### Requirement 19

**User Story:** As a user, I want consistent response quality across all stages, so that the AI remains helpful as the system evolves.

#### Acceptance Criteria

1. WHEN comparing Stage 2 and Stage 7 responses, THE System SHALL maintain or improve response relevance
2. WHEN context is compressed (Stage 5), THE System SHALL not lose critical information
3. WHEN intent-driven retrieval is used (Stage 6), THE System SHALL include all relevant records
4. WHEN personas are applied (Stage 7), THE System SHALL maintain appropriate tone for the Space
5. THE System SHALL track response quality metrics at each stage for comparison

### Requirement 20

**User Story:** As a developer, I want clear documentation and verification steps for each stage, so that I can validate deliverables and hand off to QA.

#### Acceptance Criteria

1. WHEN a stage is complete, THE System SHALL have updated documentation describing the implementation
2. WHEN a stage is complete, THE System SHALL have a manual test plan with expected outcomes
3. WHEN a stage is complete, THE System SHALL have automated tests covering all acceptance criteria
4. WHEN a stage is complete, THE System SHALL have performance benchmarks (latency, token usage, error rate)
5. WHEN a stage is complete, THE System SHALL have a sign-off checklist for stakeholder approval
