# Implementation Plan

## Overview

This implementation plan breaks down Stage 7a (AI Personas & Error Recovery) into detailed, actionable tasks. The plan follows an incremental approach: implement personas first, then add error recovery, then testing and documentation.

**Task Breakdown:**
- **Original:** 12 main tasks
- **Expanded:** 30+ subtask groups (6a-6d, 7a-7d, 8a-8f, 9a-9c, 10a-10e, 11a-11e, 12)
- **Total Subtasks:** 100+ individual coding tasks

**Important Notes:**
- Each task builds on previous tasks
- Tasks are broken down to minimize complexity
- Each subtask is focused and manageable (< 100 lines of code typically)
- Test as you go (unit tests after each component)
- Commit after each checkpoint
- Backend changes (personas) are independent of Flutter changes (error recovery)

---

## Agent Instructions

**CRITICAL: After completing EACH task or checkpoint, you MUST:**

1. **Mark the task as complete** by checking the checkbox in this file
2. **Commit your changes** with the exact commit message specified in the checkpoint
3. **Stop and wait** for user confirmation before proceeding to the next task

**Workflow for each task:**
```
1. Read the task requirements
2. Implement the code
3. Test the implementation
4. Mark task checkbox as [x] in tasks.md
5. Git add and commit with specified message
6. STOP - Ask user if you should continue to next task
```

**Example:**
```bash
# After completing task 1.1
git add .
git commit -m "feat(stage7a): Add persona configuration system"
# Then STOP and ask user before continuing
```

**Never skip ahead to the next task without:**
- Marking the current task complete
- Committing the changes
- Getting user approval to continue

**Checkpoint Instructions:**
- Every checkpoint section shows the required commit message
- At each checkpoint, mark ALL tasks in that section as [x]
- Run `git add .` and `git commit -m "<message>"` with the exact message shown
- STOP after each checkpoint and ask user: "Checkpoint complete. Should I continue to the next task?"
- Wait for user confirmation before proceeding

---

## Task 1: Backend - Persona System Foundation

Create the persona configuration system on the backend.

- [x] 1.1 Create persona configuration file
  - File: `server/config/personas.json`
  - Define structure for health, finance, education, travel personas
  - Include default persona
  - _Requirements: 1.1-1.4, 2.1-2.4, 8.1-8.3_

- [x] 1.2 Create PersonaManager class
  - File: `server/src/llm/persona_manager.js`
  - Method: `loadPersonas()` - Load from config file
 - Method: `getPersona(spaceName)` - Get persona by Space
  - Method: `validatePersona(persona)` - Validate configuration
  - _Requirements: 8.1-8.3_

- [x] 1.3 Write unit tests for PersonaManager
  - File: `server/test/persona_manager.test.mjs`
  - Test loading personas from file
  - Test getting persona for each Space
  - Test default persona fallback
 - Test validation
 - _Requirements: 8.1-8.5_

---

## Checkpoint 1: Commit persona foundation

**Actions Required:**
1. Mark tasks 1.1, 1.2, 1.3 as complete [x] in this file
2. Run: `git add .`
3. Run: `git commit -m "feat(stage7a): Add persona configuration system"`
4. STOP and ask user before continuing to Task 2

---

## Task 2: Backend - Persona Integration

Integrate personas into the prompt building system.

- [x] 2.1 Update PromptTemplate to accept persona
  - File: `server/src/llm/prompt_template.js`
  - Add `persona` parameter to `buildPrompt()`
  - Append persona system prompt addition
  - _Requirements: 1.1-1.4, 2.1-2.4_

- [x] 2.2 Update chat endpoint to use personas
  - File: `server/src/index.js` (or chat route file)
  - Extract Space name from request
  - Get persona using PersonaManager
  - Pass persona to prompt builder
  - _Requirements: 1.1-1.4_

- [x] 2.3 Write integration tests for persona prompts
  - File: `server/test/persona_integration.test.mjs`
  - Test Health Space gets health persona
  - Test Finance Space gets finance persona
  - Test prompt includes persona additions
  - _Requirements: 1.1-1.4, 2.1-2.4_

---

## Checkpoint 2: Commit persona integration

**Actions Required:**
1. Mark tasks 2.1, 2.2, 2.3 as complete [x]
2. Commit: `git commit -m "feat(stage7a): Integrate personas into prompt building"`
3. STOP and ask user before continuing

---

## Task 3: Backend - Define All Personas

Create detailed persona configurations for each Space.

- [x] 3.1 Define Health persona
  - Empathetic, cautious tone
  - Medical disclaimers
 - Encourage consulting professionals
  - _Requirements: 2.1_

- [x] 3.2 Define Finance persona
  - Practical, budget-conscious tone
  - Focus on saving and budgeting
  - Clear financial guidance
  - _Requirements: 2.2_

- [x] 3.3 Define Education persona
  - Study-focused, constructive tone
  - Learning encouragement
  - Study tips and guidance
 - _Requirements: 2.3_

- [x] 3.4 Define Travel persona
  - Exploratory, enthusiastic tone
  - Planning-focused
 - Adventure and discovery
  - _Requirements: 2.4_

---

## Checkpoint 3: Commit all personas

**Actions Required:**
1. Mark tasks 3.1-3.4 as complete [x]
2. Commit: `git commit -m "feat(stage7a): Define all Space personas"`
3. STOP and ask user before continuing

---

## Task 4: Flutter - Error Recovery Foundation

Create the error recovery infrastructure.

- [x] 4.1 Create ErrorRecoveryAttempt model
  - File: `lib/core/ai/chat/models/error_recovery_attempt.dart`
  - Fields: attemptNumber, strategyUsed, timestamp, duration, success, errorMessage
  - Add toJson() method
  - _Requirements: 3.4_

- [x] 4.2 Create RecoveryMetrics model
  - File: `lib/core/ai/chat/models/recovery_metrics.dart`
  - Fields: totalAttempts, successfulRecoveries, failedRecoveries, fallbacksUsed
  - Calculate success rate and fallback rate
  - _Requirements: 10.1-10.3_

- [x] 4.3 Create RecoveryConfig
  - File: `lib/core/ai/chat/config/recovery_config.dart`
  - Define max attempts, timeouts, retry delays
  - _Requirements: 9.1-9.5_

---

## Checkpoint 4: Commit recovery models

**Actions Required:**
1. Mark tasks 4.1-4.3 as complete [x]
2. Commit: `git commit -m "feat(stage7a): Add error recovery models and config"`
3. STOP and ask user before continuing

---

## Task 5: Flutter - Error Classification

Implement error classification system.

- [x] 5.1 Create ErrorClassifier class
  - File: `lib/core/ai/chat/services/error_classifier.dart`
  - Method: `classify(AiServiceException)` → ErrorType enum
  - Classify: rate-limit, network, server, validation, timeout, unknown
  - _Requirements: 6.1-6.5_

- [x] 5.2 Write unit tests for ErrorClassifier
  - File: `test/core/ai/chat/services/error_classifier_test.dart`
  - Test each error type classification
  - Test classification consistency
  - _Requirements: 6.1-6.5_

---

## Checkpoint 5: Commit error classification

**Actions Required:**
1. Mark tasks 5.1-5.2 as complete [x]
2. Commit: `git commit -m "feat(stage7a): Add error classification system"`
3. STOP and ask user before continuing

---

## Task 6: Flutter - Recovery Strategies (Part 1: Base Class)

Create the base recovery strategy class.

- [x] 6.1 Create ErrorRecoveryStrategy base class
  - File: `lib/core/ai/chat/services/error_recovery_strategy.dart`
  - Abstract methods: recover(), canRecover(), getRetryDelay()
  - Add documentation for each method
  - _Requirements: 4.1-4.5_

---

## Checkpoint 6a: Commit base strategy

**Actions Required:**
1. Mark task 6.1 as complete [x]
2. Commit: `git commit -m "feat(stage7a): Add error recovery strategy base class"`
3. STOP and ask user before continuing

---

## Task 6b: Flutter - Recovery Strategies (Part 2: Rate Limit Strategy)

Implement rate limit recovery strategy.

- [x] 6b.1 Implement RateLimitRecoveryStrategy
  - File: `lib/core/ai/chat/services/rate_limit_recovery_strategy.dart`
  - Extend ErrorRecoveryStrategy
  - Implement canRecover() - check if error is rate limit
  - Implement getRetryDelay() - return delay from error (max 5s)
  - _Requirements: 4.1, 6.2_

- [x] 6b.2 Implement recover() method
  - Wait for rate limit delay
  - Retry the request
  - Return response if successful
  - _Requirements: 4.1, 6.2_

- [x] 6b.3 Write unit tests for RateLimitRecoveryStrategy
  - File: `test/core/ai/chat/services/rate_limit_recovery_strategy_test.dart`
  - Test canRecover() returns true for rate limit errors
  - Test getRetryDelay() respects max 5s
  - Test recover() waits and retries
  - _Requirements: 4.1, 6.2_

---

## Checkpoint 6b: Commit rate limit strategy

**Actions Required:**
1. Mark tasks 6b.1-6b.3 as complete [x]
2. Commit: `git commit -m "feat(stage7a): Implement rate limit recovery strategy"`
3. STOP and ask user before continuing

---

## Task 6c: Flutter - Recovery Strategies (Part 3: Network Strategy)

Implement network error recovery strategy.

- [x] 6c.1 Implement NetworkRecoveryStrategy
  - File: `lib/core/ai/chat/services/network_recovery_strategy.dart`
  - Extend ErrorRecoveryStrategy
  - Implement canRecover() - check if error is network
  - Implement getRetryDelay() - exponential backoff (1s, 2s)
  - _Requirements: 4.4, 6.3_

- [x] 6c.2 Implement recover() method
  - Track attempt number
  - Use exponential backoff (1s first, 2s second)
  - Max 2 attempts
  - Return response if successful
  - _Requirements: 4.4, 6.3_

- [x] 6c.3 Write unit tests for NetworkRecoveryStrategy
  - File: `test/core/ai/chat/services/network_recovery_strategy_test.dart`
  - Test canRecover() returns true for network errors
  - Test exponential backoff delays (1s, 2s)
  - Test max 2 attempts
  - Test recover() retries with backoff
  - _Requirements: 4.4, 6.3_

---

## Checkpoint 6c: Commit network strategy

**Actions Required:**
1. Mark tasks 6c.1-6c.3 as complete [x]
2. Commit: `git commit -m "feat(stage7a): Implement network recovery strategy"`
3. STOP and ask user before continuing

---

## Task 6d: Flutter - Recovery Strategies (Part 4: Server & Timeout Strategies)

Implement server error and timeout recovery strategies.

- [x] 6d.1 Implement ServerErrorRecoveryStrategy
  - File: `lib/core/ai/chat/services/server_error_recovery_strategy.dart`
  - Extend ErrorRecoveryStrategy
  - Implement canRecover() - always return false (no retry)
  - Immediate fallback (no retry)
  - _Requirements: 4.3, 6.4_

- [x] 6d.2 Implement TimeoutRecoveryStrategy
  - File: `lib/core/ai/chat/services/timeout_recovery_strategy.dart`
  - Extend ErrorRecoveryStrategy
  - Implement canRecover() - check if error is timeout
  - Retry once with shorter timeout
  - _Requirements: 4.2_

- [x] 6d.3 Write unit tests for ServerErrorRecoveryStrategy
  - File: `test/core/ai/chat/services/server_error_recovery_strategy_test.dart`
  - Test canRecover() returns false
  - Test no retry attempts
  - _Requirements: 4.3, 6.4_

- [x] 6d.4 Write unit tests for TimeoutRecoveryStrategy
  - File: `test/core/ai/chat/services/timeout_recovery_strategy_test.dart`
  - Test canRecover() returns true for timeout errors
  - Test retry with shorter timeout
  - Test max 1 retry
  - _Requirements: 4.2_

---

## Checkpoint 6d: Commit server and timeout strategies

**Actions Required:**
1. Mark tasks 6d.1-6d.4 as complete [x]
2. Commit: `git commit -m "feat(stage7a): Implement server and timeout recovery strategies"`
3. STOP and ask user before continuing

---

## Task 7: Flutter - Fallback Service (Part 1: Foundation)

Create the basic fallback service structure.

- [x] 7.1 Create FallbackService class skeleton
  - File: `lib/core/ai/chat/services/fallback_service.dart`
  - Create class with constructor
  - Add empty generateFallbackResponse() method
  - Add error type detection helper
  - _Requirements: 5.1-5.5_

- [x] 7.2 Implement basic fallback response structure
  - Create ChatResponse with fallback flag
  - Set isFallback = true
  - Add timestamp
  - Add basic message structure
  - _Requirements: 5.1, 7.1_

---

## Checkpoint 7a: Commit fallback foundation

**Actions Required:**
1. Mark tasks 7.1-7.2 as complete [x]
2. Commit: `git commit -m "feat(stage7a): Add fallback service foundation"`
3. STOP and ask user before continuing

---

## Task 7b: Flutter - Fallback Service (Part 2: Error-Specific Messages)

Implement error-specific fallback messages.

- [x] 7b.1 Implement network error fallback
  - Detect network errors
  - Generate user-friendly message: "Can't connect right now. Check your internet."
  - No technical jargon
  - _Requirements: 5.2, 7.2_

- [x] 7b.2 Implement rate limit fallback
  - Detect rate limit errors
  - Generate message: "Too many requests. Please wait a moment."
  - _Requirements: 5.2, 7.2_

- [x] 7b.3 Implement timeout fallback
  - Detect timeout errors
  - Generate message: "Request took too long. Please try again."
  - _Requirements: 5.2, 7.2_

- [x] 7b.4 Implement server error fallback
  - Detect server errors
  - Generate message: "Service temporarily unavailable. Try again soon."
  - _Requirements: 5.2, 7.2_

- [x] 7b.5 Implement generic fallback
  - For unknown errors
  - Generate message: "Something went wrong. Please try again."
  - _Requirements: 5.2, 7.2_

---

## Checkpoint 7b: Commit error-specific messages

**Actions Required:**
1. Mark tasks 7b.1-7b.5 as complete [x]
2. Commit: `git commit -m "feat(stage7a): Add error-specific fallback messages"`
3. STOP and ask user before continuing

---

## Task 7c: Flutter - Fallback Service (Part 3: Context Awareness)

Add context-aware fallback messages.

- [x] 7c.1 Add Space context to fallback messages
  - Extract Space name from request
  - Customize message based on Space (Health, Finance, etc.)
  - Example: "Can't access your health records right now."
  - _Requirements: 5.4_

- [x] 7c.2 Add retry suggestions
  - Include actionable suggestions in messages
  - Example: "Check your connection and try again."
  - _Requirements: 5.5, 7.3_

- [x] 7c.3 Add error prevention tips
  - For repeated errors, suggest preventive actions
  - Example: "Make sure you're connected to the internet."
  - _Requirements: 7.5_

---

## Checkpoint 7c: Commit context-aware messages

**Actions Required:**
1. Mark tasks 7c.1-7c.3 as complete [x]
2. Commit: `git commit -m "feat(stage7a): Add context-aware fallback messages"`
3. STOP and ask user before continuing

---

## Task 7d: Flutter - Fallback Service (Part 4: Testing)

Write comprehensive tests for fallback service.

- [x] 7d.1 Write basic fallback tests
  - File: `test/core/ai/chat/services/fallback_service_test.dart`
  - Test never throws exceptions
  - Test always returns valid ChatResponse
  - Test isFallback flag is set
  - _Requirements: 5.1, 7.1_

- [x] 7d.2 Write error-specific message tests
  - Test network error message
  - Test rate limit error message
  - Test timeout error message
  - Test server error message
  - Test generic error message
  - Verify no technical jargon in any message
  - _Requirements: 5.2, 7.2, 7.4_

- [x] 7d.3 Write context-aware tests
  - Test Space-specific messages
  - Test retry suggestions included
  - Test error prevention tips
  - _Requirements: 5.4, 5.5, 7.3, 7.5_

---

## Checkpoint 7d: Commit fallback tests

**Actions Required:**
1. Mark tasks 7d.1-7d.3 as complete [x]
2. Commit: `git commit -m "test(stage7a): Add fallback service tests"`
3. STOP and ask user before continuing

---

## Task 8: Flutter - Resilient Service Wrapper (Part 1: Foundation)

Create the basic structure of the resilient service.

- [x] 8.1 Create ResilientAiChatService class skeleton
  - File: `lib/core/ai/chat/services/resilient_ai_chat_service.dart`
 - Create class with constructor
  - Accept primaryService, errorClassifier, fallbackService as dependencies
  - Add empty sendMessage() method
  - _Requirements: 3.1_

- [x] 8.2 Implement basic sendMessage() flow
  - Try calling primary service
  - Return response if successful
  - Catch exceptions and rethrow for now (we'll add recovery next)
  - _Requirements: 3.1_

- [x] 8.3 Add basic logging
  - Log when request starts
  - Log when request succeeds
  - Log when request fails
  - Use AppLogger with correlation IDs
  - _Requirements: 3.4_

---

## Checkpoint 8a: Commit resilient service foundation

**Actions Required:**
1. Mark tasks 8.1-8.3 as complete [x]
2. Commit: `git commit -m "feat(stage7a): Add resilient service foundation"`
3. STOP and ask user before continuing

---

## Task 8b: Flutter - Resilient Service Wrapper (Part 2: Error Classification)

Add error classification to the resilient service.

- [x] 8b.1 Add error classification on failure
  - When exception caught, classify using ErrorClassifier
  - Log the error type
  - Still rethrow for now
  - _Requirements: 6.1_

- [x] 8b.2 Add strategy selection logic
 - Based on error type, select appropriate recovery strategy
  - Log which strategy was selected
  - Don't execute yet, just select
  - _Requirements: 4.1, 6.2-6.4_

---

## Checkpoint 8b: Commit error classification

**Actions Required:**
1. Mark tasks 8b.1-8b.2 as complete [x]
2. Commit: `git commit -m "feat(stage7a): Add error classification to resilient service"`
3. STOP and ask user before continuing

---

## Task 8c: Flutter - Resilient Service Wrapper (Part 3: Single Recovery)

Implement single recovery attempt.

- [x] 8c.1 Create _attemptRecovery() method
 - Accept request, error, attemptNumber
 - Call selected strategy's recover() method
  - Return response if successful
  - Rethrow if recovery fails
  - _Requirements: 3.1, 4.1_

- [x] 8c.2 Integrate single recovery into sendMessage()
  - On error, attempt recovery once
  - Log recovery attempt
  - Return response if recovery succeeds
  - Rethrow if recovery fails
 - _Requirements: 3.1, 3.2_

- [x] 8c.3 Add recovery attempt logging
  - Log attempt number
  - Log strategy used
  - Log duration
  - Log success/failure
 - _Requirements: 3.4_

---

## Checkpoint 8c: Commit single recovery

**Actions Required:**
1. Mark tasks 8c.1-8c.3 as complete [x]
2. Commit: `git commit -m "feat(stage7a): Implement single recovery attempt"`
3. STOP and ask user before continuing

---

## Task 8d: Flutter - Resilient Service Wrapper (Part 4: Multiple Recoveries)

Add support for multiple recovery attempts.

- [x] 8d.1 Implement recovery loop
  - Try up to 2 recovery attempts
  - Use different strategies if first fails
  - Track all attempts
  - _Requirements: 3.1, 3.2_

- [x] 8d.2 Add recovery metrics tracking
 - Count total attempts
  - Count successes vs failures
 - Track which strategies were used
  - _Requirements: 10.1-10.3_

---

## Checkpoint 8d: Commit multiple recoveries

**Actions Required:**
1. Mark tasks 8d.1-8d.2 as complete [x]
2. Commit: `git commit -m "feat(stage7a): Add multiple recovery attempts"`
3. STOP and ask user before continuing

---

## Task 8e: Flutter - Resilient Service Wrapper (Part 5: Fallback)

Add fallback behavior when all recoveries fail.

- [x] 8e.1 Create _fallback() method
  - Call FallbackService.generateFallbackResponse()
  - Log fallback event
  - Return fallback response
  - _Requirements: 5.1-5.5_

- [x] 8e.2 Integrate fallback into sendMessage()
  - After all recovery attempts fail, call _fallback()
  - Never throw exception (always return response)
  - Log that fallback was used
  - _Requirements: 5.1-5.5_

---

## Checkpoint 8e: Commit fallback integration

**Actions Required:**
1. Mark tasks 8e.1-8e.2 as complete [x]
2. Commit: `git commit -m "feat(stage7a): Add fallback behavior to resilient service"`
3. STOP and ask user before continuing

---

## Task 8f: Flutter - Resilient Service Wrapper (Part 6: Timeouts)

Add timeout enforcement.

- [x] 8f.1 Add total recovery timeout
  - Track total time spent on recovery
  - If > 10s, stop and use fallback
  - Log timeout events
  - _Requirements: 9.1-9.3_

- [x] 8f.2 Add individual attempt timeout
  - Each recovery attempt has 30s timeout
  - Use Future.timeout()
  - Log timeout events
  - _Requirements: 9.4, 9.5_

- [x] 8f.3 Write unit tests for ResilientAiChatService
  - File: `test/core/ai/chat/services/resilient_ai_chat_service_test.dart`
  - Test successful request (no errors)
  - Test single recovery succeeds
 - Test multiple recoveries
  - Test fallback after failures
 - Test timeout enforcement
  - _Requirements: 3.1-3.5, 9.1-9.5_

---

## Checkpoint 8f: Commit timeout enforcement

**Actions Required:**
1. Mark tasks 8f.1-8f.3 as complete [x]
2. Commit: `git commit -m "feat(stage7a): Add timeout enforcement to resilient service"`
3. STOP and ask user before continuing

---

## Task 9: Flutter - Integration and Wiring (Part 1: Dependency Injection)

Set up dependency injection for resilient service.

- [x] 9.1 Register ErrorClassifier in DI
  - File: `lib/core/di/bootstrap.dart`
  - Create singleton ErrorClassifier
 - _Requirements: 3.1_

- [x] 9.2 Register recovery strategies in DI
  - Register RateLimitRecoveryStrategy
  - Register NetworkRecoveryStrategy
  - Register ServerErrorRecoveryStrategy
  - Register TimeoutRecoveryStrategy
  - _Requirements: 3.1_

- [x] 9.3 Register FallbackService in DI
  - Create singleton FallbackService
  - _Requirements: 3.1_

- [x] 9.4 Register ResilientAiChatService in DI
  - Inject all dependencies (classifier, strategies, fallback)
  - Inject HttpAiChatService as primary service
  - _Requirements: 3.1_

---

## Checkpoint 9a: Commit dependency injection

**Actions Required:**
1. Mark tasks 9.1-9.4 as complete [x]
2. Commit: `git commit -m "feat(stage7a): Set up dependency injection for resilient service"`
3. STOP and ask user before continuing

---

## Task 9b: Flutter - Integration and Wiring (Part 2: Controller Update)

Update AiChatController to use resilient service.

- [x] 9b.1 Update AiChatController constructor
 - File: `lib/features/ai_chat/ui/controllers/ai_chat_controller.dart`
  - Replace HttpAiChatService with ResilientAiChatService
  - Update constructor parameters
  - _Requirements: 3.1_

- [x] 9b.2 Verify no breaking changes
  - Check all sendMessage() calls still work
  - Check error handling still works
  - Check UI updates correctly
 - _Requirements: 3.1_

- [x] 9b.3 Add logging for resilient service usage
 - Log when resilient service is used
  - Log recovery attempts
  - Log fallback usage
 - _Requirements: 3.4_

---

## Checkpoint 9b: Commit controller update

**Actions Required:**
1. Mark tasks 9b.1-9b.3 as complete [x]
2. Commit: `git commit -m "feat(stage7a): Update AiChatController to use resilient service"`
3. STOP and ask user before continuing

---

## Task 9c: Flutter - Integration and Wiring (Part 3: Integration Tests)

Write integration tests for the complete system.

- [x] 9c.1 Create integration test file
  - File: `test/integration/resilient_chat_integration_test.dart`
  - Set up test environment
  - Create mock backend
  - _Requirements: 3.1-3.5_

- [x] 9c.2 Write end-to-end recovery test
  - Simulate network error
 - Verify recovery attempts
  - Verify eventual success
  - _Requirements: 3.1-3.5_

- [x] 9c.3 Write end-to-end fallback test
  - Simulate server down
 - Verify fallback response
 - Verify no crash
  - _Requirements: 5.1-5.5_

- [x] 9c.4 Write persona integration test (if backend available)
  - Switch Spaces
  - Send messages
  - Verify persona changes
  - _Requirements: 1.1-1.5_

---

## Checkpoint 9c: Commit integration tests

**Actions Required:**
1. Mark tasks 9c.1-9c.4 as complete [x]
2. Commit: `git commit -m "test(stage7a): Add resilient service integration tests"`
3. STOP and ask user before continuing

---

## Task 10: Property-Based Tests (Part 1: Persona Properties)

Write property tests for persona system.

- [x] 10.1 Create persona properties test file
  - File: `server/test/persona_properties.test.mjs`
  - Set up test framework
  - Import PersonaManager
  - _Property 1, 2_

- [x] 10.2 Property 1: Persona selection consistency
  - Generate random Space names (health, finance, education, travel)
  - Call getPersona() multiple times for same Space
  - Verify returns same persona each time
  - _Property 1_

- [x] 10.3 Property 2: Persona prompt inclusion
  - Generate random Spaces
  - Build prompt with persona
  - Verify prompt includes persona systemPromptAddition
  - _Property 2_

---

## Checkpoint 10a: Commit persona properties

**Actions Required:**
1. Mark tasks 10.1-10.3 as complete [x]
2. Commit: `git commit -m "test(stage7a): Add persona property tests"`
3. STOP and ask user before continuing

---

## Task 10b: Property-Based Tests (Part 2: Error Classification Properties)

Write property tests for error classification.

- [x] 10b.1 Create error classification properties test file
  - File: `test/core/ai/chat/services/error_classification_properties_test.dart`
  - Set up test framework
  - Import ErrorClassifier
  - _Property 3, 4_

- [x] 10b.2 Property 3: Error classification determinism
  - Generate random errors (network, timeout, rate-limit, server)
  - Classify same error multiple times
  - Verify classification is consistent
  - _Property 3_

- [x] 10b.3 Property 4: Recovery strategy selection
  - Generate random error types
  - Select strategy for each error
  - Verify appropriate strategy selected (rate-limit → RateLimitStrategy, etc.)
  - _Property 4_

---

## Checkpoint 10b: Commit error classification properties

**Actions Required:**
1. Mark tasks 10b.1-10b.3 as complete [x]
2. Commit: `git commit -m "test(stage7a): Add error classification property tests"`
3. STOP and ask user before continuing

---

## Task 10c: Property-Based Tests (Part 3: Recovery Properties)

Write property tests for recovery behavior.

- [x] 10c.1 Create recovery properties test file
  - File: `test/core/ai/chat/services/recovery_properties_test.dart`
  - Set up test framework
  - Import ResilientAiChatService
  - _Property 5, 6, 7_

- [x] 10c.2 Property 5: Recovery attempt limit
  - Simulate continuous failures
  - Count recovery attempts
  - Verify max 2 attempts before fallback
  - _Property 5_

- [x] 10c.3 Property 6: Fallback always succeeds
  - Generate random requests
  - Force all recoveries to fail
  - Verify fallback never throws exception
  - Verify always returns valid ChatResponse
  - _Property 6_

- [x] 10c.4 Property 7: Recovery time bounds
  - Simulate recovery attempts
  - Measure total time
  - Verify time < 10 seconds
  - _Property 7_

---

## Checkpoint 10c: Commit recovery properties

**Actions Required:**
1. Mark tasks 10c.1-10c.4 as complete [x]
2. Commit: `git commit -m "test(stage7a): Add recovery property tests"`
3. STOP and ask user before continuing

---

## Task 10d: Property-Based Tests (Part 4: Persona Switching & UX Properties)

Write property tests for persona switching and user experience.

- [x] 10d.1 Property 8: Persona switch consistency
  - Generate sequence of Space switches
  - Send message after each switch
  - Verify persona changes with Space
  - _Property 8_

- [x] 10d.2 Property 9: User message friendliness
  - Generate random errors
  - Get user-facing error messages
  - Verify no technical jargon (no "stack trace", "exception", "null pointer")
  - Verify messages are helpful
  - _Property 9_

---

## Checkpoint 10d: Commit UX properties

**Actions Required:**
1. Mark tasks 10d.1-10d.2 as complete [x]
2. Commit: `git commit -m "test(stage7a): Add persona switching and UX property tests"`
3. STOP and ask user before continuing

---

## Task 10e: Property-Based Tests (Part 5: Metrics Properties)

Write property tests for metrics accuracy.

- [x] 10e.1 Property 10: Metrics accuracy
  - Generate random sequence of recovery attempts
  - Track successes and failures manually
  - Compare with RecoveryMetrics calculations
  - Verify success rate = successes / total
  - Verify fallback rate = fallbacks / total
  - _Property 10_

---

## Checkpoint 10e: Commit metrics properties

**Actions Required:**
1. Mark task 10e.1 as complete [x]
2. Commit: `git commit -m "test(stage7a): Add metrics property tests"`
3. STOP and ask user before continuing

---

## Task 11: Manual Testing (Part 1: Documentation) (Part 1: Documentation)

Create manual test scenarios document.

- [x] 11.1 Create manual test scenarios document
  - File: `docs/modules/ai/STAGE_7A_MANUAL_TEST_SCENARIOS.md`
  - Add document structure
  - Add "How to Test" section
  - Add "Success Criteria" section
  - _Requirements: All_

- [x] 11.2 Document persona test scenarios
  - Add Health persona test scenario
  - Add Finance persona test scenario
  - Add Education persona test scenario
  - Add Travel persona test scenario
  - Add persona switching scenario
  - _Requirements: 1.1-1.5, 2.1-2.4_

- [x] 11.3 Document error recovery test scenarios
  - Add network error recovery scenario
  - Add rate limit recovery scenario
  - Add timeout recovery scenario
  - Add fallback scenario
  - _Requirements: 3.1-3.5, 4.1-4.5, 5.1-5.5_

---

## Checkpoint 11a: Commit test documentation

**Actions Required:**
1. Mark tasks 11.1-11.3 as complete [x]
2. Commit: `git commit -m "docs(stage7a): Create manual test scenarios document"`
3. STOP and ask user before continuing

---

## Task 11b: Manual Testing (Part 2: Persona Testing)

Execute persona tests manually.

- [x] 11b.1 Test Health persona
  - Create 5 health records (blood pressure, medications, etc.)
  - Ask: "What is my blood pressure?"
  - Ask: "Should I be worried about my health?"
  - Verify empathetic tone
  - Verify medical disclaimers present
  - _Requirements: 1.1, 2.1_

- [x] 11b.2 Test Finance persona
  - Create 5 finance records (expenses, income, etc.)
  - Ask: "How much did I spend this month?"
  - Ask: "Should I save more money?"
  - Verify practical, budget-conscious tone
  - Verify focus on saving and budgeting
  - _Requirements: 1.2, 2.2_

- [x] 11b.3 Test Education persona
  - Create 5 education records (study sessions, notes, etc.)
  - Ask: "How are my studies going?"
  - Ask: "What should I study next?"
  - Verify constructive, learning-focused tone
  - Verify study tips and encouragement
  - _Requirements: 1.3, 2.3_

- [x] 11b.4 Test Travel persona
  - Create 5 travel records (trips, plans, etc.)
  - Ask: "Where should I travel next?"
  - Ask: "What did I do on my last trip?"
  - Verify exploratory, enthusiastic tone
  - Verify planning-focused guidance
  - _Requirements: 1.4, 2.4_

---

## Checkpoint 11b: Commit persona testing results

**Actions Required:**
1. Mark tasks 11b.1-11b.4 as complete [x]
2. Commit: `git commit -m "test(stage7a): Complete persona manual testing"`
3. STOP and ask user before continuing

---

## Task 11c: Manual Testing (Part 3: Persona Switching)

Test persona switching behavior.

- [x] 11c.1 Test persona switching
  - Start in Health Space
  - Ask health question, note tone
  - Switch to Finance Space
  - Ask finance question, note tone
  - Verify tone changed appropriately
  - Switch back to Health
  - Verify tone changed back
  - _Requirements: 1.5_

---

## Checkpoint 11c: Commit persona switching test

**Actions Required:**
1. Mark task 11c.1 as complete [x]
2. Commit: `git commit -m "test(stage7a): Complete persona switching testing"`
3. STOP and ask user before continuing

---

## Task 11d: Manual Testing (Part 4: Error Recovery)

Test error recovery behavior.

- [x] 11d.1 Test network error recovery
  - Send a message
  - Disconnect network mid-request (or before)
  - Observe "Retrying..." indicator
  - Reconnect network
  - Verify message eventually succeeds
  - Check logs for retry attempts
  - _Requirements: 3.1-3.5, 4.4_

- [x] 11d.2 Test rate limit recovery (if possible)
  - Send many messages quickly
  - Trigger rate limit (if backend supports)
  - Verify system waits and retries
  - Verify eventual success
  - _Requirements: 4.1, 6.2_

---

## Checkpoint 11d: Commit error recovery testing

**Actions Required:**
1. Mark tasks 11d.1-11d.2 as complete [x]
2. Commit: `git commit -m "test(stage7a): Complete error recovery testing"`
3. STOP and ask user before continuing

---

## Task 11e: Manual Testing (Part 5: Fallback)

Test fallback behavior.

- [x] 11e.1 Test fallback with server down
  - Stop backend server
  - Send a message
  - Verify fallback response appears
  - Verify message is helpful (not technical)
  - Verify no crash or hang
  - _Requirements: 5.1-5.5, 7.1-7.5_

- [x] 11e.2 Test fallback recovery
  - With server still down, note fallback behavior
  - Restart backend server
  - Send another message
  - Verify normal operation resumes
  - _Requirements: 5.3_

---

## Checkpoint 11e: Commit fallback testing

**Actions Required:**
1. Mark tasks 11e.1-11e.2 as complete [x]
2. Commit: `git commit -m "test(stage7a): Complete fallback testing"`
3. STOP and ask user before continuing
---

## Task 12: Documentation

Create comprehensive documentation for Stage 7a.

- [x] 12.1 Create Stage 7a overview document
  - File: `docs/modules/ai/STAGE_7A_PERSONAS_ERROR_RECOVERY.md`
  - Overview of personas and error recovery
  - How to configure personas
 - How error recovery works
  - Examples and use cases
  - _Requirements: All_

- [x] 12.2 Update LLM_STAGES_OVERVIEW.md
  - Mark Stage 7a as complete
  - Add completion date
  - Add key metrics
  - _Requirements: All_

- [x] 12.3 Update README
  - Add Stage 7a to features list
  - Mention persona system
  - Mention error recovery
 - _Requirements: All_

---

## Checkpoint 12: Commit documentation

**Actions Required:**
1. Mark tasks 12.1-12.3 as complete [x]
2. Commit: `git commit -m "docs(stage7a): Complete Stage 7a documentation"`
3. STOP - Stage 7a implementation complete!


---

## Success Criteria

Stage 7a is complete when:

- [ ] All main task groups completed (1-5, 6a-6d, 7a-7d, 8a-8f, 9a-9c, 10a-10e, 11a-11e, 12)
- [ ] All 100+ subtasks completed
- [ ] All unit tests passing
- [ ] All property-based tests passing (10 properties)
- [ ] All integration tests passing
- [ ] Manual testing validates personas work correctly
- [ ] Manual testing validates error recovery works
- [ ] Documentation complete
- [ ] All changes committed to git

---

**Created:** December 1, 2025  
**Updated:** December 2, 2025 (Task breakdown refinement)  
**Status:** Ready for implementation  
**Estimated Time:** 3-4 days for full implementation (increased due to more granular tasks)
