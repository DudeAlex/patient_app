# Requirements Document

## Introduction

The Universal Life Companion app currently has a fully functional AI Chat Companion interface with complete UI, persistence, and state management. The system operates with a FakeAiChatService that provides deterministic responses for development and testing. This specification defines the first two stages of LLM integration: establishing HTTP connectivity (Stage 1) and connecting to a real LLM provider (Stage 2). These foundational stages enable the transition from mock responses to real AI-generated content.

## Glossary

- **LLM**: Large Language Model - AI system that generates human-like text responses
- **Backend Proxy**: Server-side component that mediates between Flutter client and LLM provider
- **Token**: Unit of text processed by LLM (roughly 4 characters or 0.75 words)
- **System Prompt**: Base instructions that define AI behavior and persona
- **Message History**: Previous conversation turns included as context for continuity
- **Exponential Backoff**: Retry strategy with increasing delays (1s, 2s, 4s, etc.)
- **Correlation ID**: Unique identifier linking request/response pairs for debugging
- **HttpAiChatService**: Flutter implementation that sends requests to backend via HTTP
- **Echo Endpoint**: Backend endpoint that returns the input message for testing connectivity
- **Rate Limiting**: Restricting the number of requests a user can make in a time period

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

**User Story:** As a user, I want the AI to maintain conversation continuity, so that responses are contextually appropriate.

#### Acceptance Criteria

1. WHEN sending a message, THE System SHALL include the last 3 conversation turns in the request
2. WHEN the LLM generates a response, THE System SHALL reference previous messages when relevant
3. WHEN a conversation exceeds 3 turns, THE System SHALL truncate older messages
4. THE System SHALL preserve message order (chronological)
5. THE System SHALL include both user and AI messages in history

### Requirement 4

**User Story:** As a system administrator, I want comprehensive logging, so that I can diagnose issues and monitor system behavior.

#### Acceptance Criteria

1. WHEN a request is received, THE System SHALL log the event with correlation ID, user ID, thread ID, and timestamp
2. WHEN an LLM request is sent, THE System SHALL log provider, model, prompt tokens, and timestamp
3. WHEN an LLM response is received, THE System SHALL log completion tokens, total tokens, finish reason, and latency
4. WHEN an error occurs, THE System SHALL log error code, message, and whether it's retryable
5. THE System SHALL redact message content from logs while preserving metadata

### Requirement 5

**User Story:** As a system administrator, I want to enforce rate limits, so that API costs remain predictable and abuse is prevented.

#### Acceptance Criteria

1. THE System SHALL limit users to 10 requests per minute
2. THE System SHALL limit users to 100 requests per hour
3. THE System SHALL limit users to 500 requests per day
4. WHEN rate limits are exceeded, THE System SHALL return HTTP 429 with retry-after header
5. THE System SHALL log rate limit violations with user ID and timestamp

### Requirement 6

**User Story:** As a developer, I want to switch between Fake and HTTP AI services via configuration, so that I can develop and test without external dependencies.

#### Acceptance Criteria

1. WHEN ai_mode is 'fake', THE System SHALL use FakeAiChatService for all chat operations
2. WHEN ai_mode is 'http', THE System SHALL use HttpAiChatService for all chat operations
3. THE System SHALL allow switching modes via Settings without losing chat history
4. THE System SHALL display the current AI mode in the chat header status pill
5. THE System SHALL handle mode transitions gracefully with appropriate user feedback

### Requirement 7

**User Story:** As a user, I want the system to work offline and queue messages, so that I can continue using the app without connectivity.

#### Acceptance Criteria

1. WHEN network is unavailable, THE System SHALL queue messages locally
2. WHEN connectivity is restored, THE System SHALL automatically retry queued messages
3. THE System SHALL show an offline indicator in the chat header
4. THE System SHALL implement exponential backoff for retry attempts
5. THE System SHALL allow viewing chat history even when offline

### Requirement 8

**User Story:** As a system administrator, I want to enforce privacy and security rules, so that sensitive user data is protected.

#### Acceptance Criteria

1. THE System SHALL never send Information Item IDs or encryption keys off-device
2. THE System SHALL redact sensitive fields (names, addresses, SSNs) from logs
3. THE System SHALL use HTTPS only for all backend communication
4. THE System SHALL validate all input and reject malformed requests
5. THE System SHALL store API keys securely using flutter_secure_storage

### Requirement 9

**User Story:** As a developer, I want clear error messages and recovery strategies, so that users understand what went wrong and how to proceed.

#### Acceptance Criteria

1. WHEN a timeout occurs, THE System SHALL display "Request timed out. Please try again."
2. WHEN network is unavailable, THE System SHALL display "No internet connection. Message will be sent when online."
3. WHEN the server returns an error, THE System SHALL display "Service temporarily unavailable. Please try again later."
4. WHEN rate limits are exceeded, THE System SHALL display "Too many requests. Please wait a moment."
5. THE System SHALL provide a retry button for retryable errors

### Requirement 10

**User Story:** As a developer, I want comprehensive test coverage, so that I can validate correctness and prevent regressions.

#### Acceptance Criteria

1. WHEN Stage 1 is tested, THE System SHALL verify HTTP connectivity, timeouts, retries, and error handling
2. WHEN Stage 2 is tested, THE System SHALL verify LLM integration, token counting, and response parsing
3. THE System SHALL have unit tests for HttpAiChatService with mocked HTTP client
4. THE System SHALL have integration tests for the complete request/response cycle
5. THE System SHALL have manual test scenarios documented in TESTING.md
