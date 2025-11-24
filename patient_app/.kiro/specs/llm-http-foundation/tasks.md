# Implementation Plan

## Stage 1: HTTP Foundation Layer

- [x] 1. Create HttpAiChatService implementation



  - Create `lib/core/ai/chat/http_ai_chat_service.dart`
  - Implement AiChatService interface
  - Add HTTP client dependency injection
  - Implement correlation ID generation
  - Implement network connectivity check
  - Add timeout configuration (30 seconds)
  - _Requirements: 1.1, 1.2, 1.5_

- [x] 2. Implement retry logic with exponential backoff
  - Create retry policy in HttpAiChatService
  - Implement exponential backoff calculation (1s, 2s, 4s)
  - Add jitter (±20%) to backoff delays
  - Limit max retries to 3 attempts
  - Classify errors as retryable vs non-retryable
  - _Requirements: 1.3_

- [x] 3. Implement error classification and exceptions
  - Create `lib/core/ai/chat/exceptions/chat_exceptions.dart`
  - Define ChatTimeoutException
  - Define NetworkException
  - Define ServerException
  - Define RateLimitException
  - Define UnauthorizedException
  - Define ValidationException
  - Add isRetryable property to each exception
  - _Requirements: 1.2, 1.4, 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 4. Implement logging integration
  - Add AppLogger calls for request sent
  - Add AppLogger calls for response received
  - Add AppLogger calls for errors
  - Include correlation ID in all logs
  - Include latency measurements
  - Redact message content from logs
  - _Requirements: 1.5, 4.1, 4.5_

- [ ] 5. Create backend echo endpoint
  - Set up backend project structure (Node.js/Python/Go)
  - Create POST /api/v1/chat/echo endpoint
  - Implement request validation
  - Implement echo response generation
  - Add correlation ID handling
  - Add request/response logging
  - Deploy to development environment
  - _Requirements: 1.1_

- [x] 6. Implement MessageQueueService for offline support
  - Create `lib/core/ai/chat/services/message_queue_service.dart`
  - Implement queueMessage() method
  - Implement processQueue() method
  - Use SharedPreferences for persistence
  - Add queue size limits (max 100 messages)
  - Add queue expiration (7 days)
  - _Requirements: 7.1, 7.2_

- [x] 7. Implement ConnectivityMonitor
  - Create `lib/core/ai/chat/services/connectivity_monitor.dart`
  - Listen to connectivity changes
  - Trigger queue processing on connectivity restored
  - Add start() and stop() lifecycle methods
  - _Requirements: 7.2, 7.3_

- [ ] 8. Create offline indicator UI
  - Update ChatHeader widget to show offline status
  - Add offline pill to status indicator
  - Disable send button when offline
  - Show "Offline - cannot send" hint in composer
  - _Requirements: 7.3, 7.4_

- [ ] 9. Implement service switching (Fake/HTTP)
  - Update AppContainer to support service selection
  - Add ai_mode configuration (fake/http)
  - Create service factory method
  - Update Settings UI with mode selector
  - Update ChatHeader status pill to show mode
  - Handle mode transitions gracefully
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 10. Create error message UI components
  - Create ErrorMessageBubble widget
  - Implement user-friendly error messages
  - Add retry button for retryable errors
  - Style error bubbles distinctly (red border/background)
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_


- [ ] 11. Write unit tests for HttpAiChatService
  - Test request construction with correlation ID
  - Test timeout handling (30s)
  - Test retry logic with exponential backoff
  - Test error classification
  - Test response parsing
  - Mock HTTP client for isolation
  - _Requirements: 10.1_

- [ ] 12. Write unit tests for MessageQueueService
  - Test message queuing when offline
  - Test queue persistence
  - Test queue processing when online
  - Test queue processing stops on first failure
  - Mock network connectivity
  - _Requirements: 10.1_

- [ ] 13. Write unit tests for retry policy
  - Test exponential backoff calculation
  - Test jitter application (±20%)
  - Test max retries enforcement
  - Test retry on transient errors only
  - _Requirements: 10.1_

- [ ] 14. Write integration test for echo flow
  - Start with empty chat thread
  - Send message via HttpAiChatService
  - Verify backend receives request
  - Verify backend returns echoed message
  - Verify message saved to Isar
  - Verify UI displays message
  - _Requirements: 10.1_

- [ ] 15. Write integration test for offline/online flow
  - Disable network
  - Send message
  - Verify message queued locally
  - Verify offline indicator shown
  - Enable network
  - Verify message auto-retried
  - Verify message sent successfully
  - _Requirements: 10.1_

- [ ] 16. Write property-based test for HTTP round trip
  - **Property 1: HTTP Connectivity Round Trip**
  - **Validates: Requirements 1.1**
  - Generate random messages
  - Send to echo endpoint
  - Assert response contains "Echo: " + original message

- [ ] 17. Write property-based test for retry backoff
  - **Property 2: Retry Exponential Backoff**
  - **Validates: Requirements 1.3**
  - Simulate multiple failures
  - Track retry delays
  - Assert delays follow 1s, 2s, 4s pattern (±20%)

- [ ] 18. Write property-based test for offline queuing
  - **Property 12: Offline Message Queuing**
  - **Validates: Requirements 7.1, 7.2**
  - Simulate offline state
  - Send multiple messages
  - Assert all messages queued
  - Simulate online state
  - Assert all messages retried

- [ ] 19. Manual testing and documentation
  - Test echo success scenario
  - Test timeout handling
  - Test offline handling
  - Test service switching
  - Document all scenarios in TESTING.md
  - Verify performance benchmarks met
  - _Requirements: 10.5_

- [ ] 20. Stage 1 checkpoint - Ensure all tests pass
  - Run all unit tests
  - Run all integration tests
  - Run all property-based tests
  - Run manual QA checklist
  - Verify no regressions in existing features
  - Verify performance targets met
  - Ask user if questions arise

## Stage 2: Basic LLM Integration

- [ ] 21. Set up LLM provider integration (Backend)
  - Choose LLM provider (Together AI recommended)
  - Create provider account and get API key
  - Store API key securely (environment variable)
  - Create LLM client wrapper
  - Implement timeout handling (60s)
  - Implement error classification
  - _Requirements: 2.1, 2.5_

- [ ] 22. Create system prompt template (Backend)
  - Create prompt template file
  - Define base system instructions
  - Add guidelines for AI behavior
  - Add placeholder for history
  - Add placeholder for user message
  - Version the template (v1.0)
  - _Requirements: 2.1_

- [ ] 23. Implement message history manager (Backend)
  - Create history formatting function
  - Limit to last 3 conversation turns
  - Format as alternating user/assistant messages
  - Preserve chronological order
  - Handle empty history gracefully
  - _Requirements: 2.2, 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 24. Implement token counter (Backend)
  - Integrate provider's tokenizer (tiktoken or custom)
  - Count tokens in system prompt
  - Count tokens in history
  - Count tokens in user message
  - Estimate total prompt tokens
  - Log token usage
  - _Requirements: 2.4, 4.2, 4.3_

- [ ] 25. Create LLM chat endpoint (Backend)
  - Create POST /api/v1/chat/message endpoint
  - Validate request format
  - Extract message and history
  - Construct prompt using template
  - Call LLM API
  - Parse LLM response
  - Build ChatResponse
  - Add error handling
  - _Requirements: 2.1, 2.2, 2.3_

- [ ] 26. Implement rate limiting (Backend)
  - Set up Redis or in-memory cache
  - Implement sliding window algorithm
  - Enforce 10 requests/minute per user
  - Enforce 100 requests/hour per user
  - Enforce 500 requests/day per user
  - Return HTTP 429 with Retry-After header
  - Log rate limit violations
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [ ] 27. Add LLM-specific logging (Backend)
  - Log LLM request sent (provider, model, prompt tokens)
  - Log LLM response received (completion tokens, latency)
  - Log token usage per request
  - Log finish reason
  - Redact message content
  - _Requirements: 2.4, 4.2, 4.3, 4.4_

- [ ] 28. Update HttpAiChatService for Stage 2
  - Update endpoint to /api/v1/chat/message
  - Include message history in request
  - Increase timeout to 60 seconds
  - Parse token usage from response
  - Log token usage
  - _Requirements: 2.3, 2.4_

- [ ] 29. Update ChatRequest model
  - Add messageHistory field
  - Add maxHistoryMessages field (default 3)
  - Update toJson() to include history
  - Format history as role/content pairs
  - _Requirements: 3.1, 3.3_

- [ ] 30. Update ChatResponse model
  - Add tokenUsage field to AiMetadata
  - Add llmProvider field to AiMetadata
  - Add modelVersion field to AiMetadata
  - Add finishReason field to AiMetadata
  - Update fromJson() to parse new fields
  - _Requirements: 2.3, 2.4_

- [ ] 31. Update SendChatMessageUseCase
  - Load last 3 messages from thread
  - Include history in ChatRequest
  - Log token usage from response
  - _Requirements: 3.1, 3.2_

- [ ] 32. Write unit tests for LLM integration (Backend)
  - Test prompt construction with history
  - Test token counting
  - Test LLM API call
  - Test response parsing
  - Test error handling
  - Mock LLM API for isolation
  - _Requirements: 10.2_

- [ ] 33. Write unit tests for rate limiting (Backend)
  - Test 10 requests/minute limit
  - Test 100 requests/hour limit
  - Test 500 requests/day limit
  - Test HTTP 429 response
  - Test Retry-After header
  - _Requirements: 10.2_

- [ ] 34. Write integration test for LLM flow
  - Start with chat thread containing 2 messages
  - Send new message via HttpAiChatService
  - Verify backend receives request with history
  - Verify backend calls LLM API
  - Verify LLM response parsed correctly
  - Verify token usage logged
  - Verify message saved to Isar
  - Verify UI displays message
  - _Requirements: 10.2_

- [ ] 35. Write property-based test for LLM response validity
  - **Property 5: LLM Response Validity**
  - **Validates: Requirements 2.3**
  - Generate random messages
  - Send to LLM endpoint
  - Assert response contains non-empty message
  - Assert response contains valid token usage

- [ ] 36. Write property-based test for history limit
  - **Property 7: History Limit Enforcement**
  - **Validates: Requirements 3.3**
  - Generate chat threads with varying message counts (0-10)
  - Build ChatRequest
  - Assert history contains at most 3 messages

- [ ] 37. Write property-based test for rate limiting
  - **Property 10: Rate Limit Enforcement**
  - **Validates: Requirements 5.1**
  - Send 11 requests in rapid succession
  - Assert 11th request returns HTTP 429

- [ ] 38. Manual testing and documentation
  - Test LLM response generation
  - Test conversation continuity
  - Test history truncation
  - Test token usage logging
  - Test rate limiting
  - Document all scenarios in TESTING.md
  - Verify performance benchmarks met
  - _Requirements: 10.5_

- [ ] 39. Stage 2 checkpoint - Ensure all tests pass
  - Run all unit tests
  - Run all integration tests
  - Run all property-based tests
  - Run manual QA checklist
  - Verify no regressions in existing features
  - Verify performance targets met
  - Verify user feedback positive (>80%)
  - Ask user if questions arise

- [ ] 40. Update documentation
  - Update README.md with LLM integration details
  - Update ARCHITECTURE.md with HTTP/LLM layers
  - Update SPEC.md with Stage 1 and 2 requirements
  - Create user-facing documentation for AI chat
  - Document backend deployment process
  - Document LLM provider configuration
  - _Requirements: All_

- [ ] 41. Final checkpoint - Production readiness
  - All tests passing
  - Performance benchmarks met
  - Security review complete
  - Privacy audit complete
  - Documentation complete
  - Deployment guide ready
  - Monitoring and alerts configured
  - User feedback collection ready
