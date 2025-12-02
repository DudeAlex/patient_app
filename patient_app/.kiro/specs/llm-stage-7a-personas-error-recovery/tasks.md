# Implementation Plan

## Overview

This implementation plan breaks down Stage 7a (AI Personas & Error Recovery) into detailed, actionable tasks. The plan follows an incremental approach: implement personas first, then add error recovery, then testing and documentation.

**Important Notes:**
- Each task builds on previous tasks
- Test as you go (unit tests after each component)
- Commit after each checkpoint
- Backend changes (personas) are independent of Flutter changes (error recovery)

---

## Task 1: Backend - Persona System Foundation

Create the persona configuration system on the backend.

- [ ] 1.1 Create persona configuration file
  - File: `server/config/personas.json`
  - Define structure for health, finance, education, travel personas
  - Include default persona
  - _Requirements: 1.1-1.4, 2.1-2.4, 8.1-8.3_

- [ ] 1.2 Create PersonaManager class
  - File: `server/src/llm/persona_manager.js`
  - Method: `loadPersonas()` - Load from config file
  - Method: `getPersona(spaceName)` - Get persona by Space
  - Method: `validatePersona(persona)` - Validate configuration
  - _Requirements: 8.1-8.3_

- [ ] 1.3 Write unit tests for PersonaManager
  - File: `server/test/persona_manager.test.mjs`
  - Test loading personas from file
  - Test getting persona for each Space
  - Test default persona fallback
  - Test validation
  - _Requirements: 8.1-8.5_

---

## Checkpoint 1: Commit persona foundation

**Action:** Commit with message: "feat(stage7a): Add persona configuration system"

---

## Task 2: Backend - Persona Integration

Integrate personas into the prompt building system.

- [ ] 2.1 Update PromptTemplate to accept persona
  - File: `server/src/llm/prompt_template.js`
  - Add `persona` parameter to `buildPrompt()`
  - Append persona system prompt addition
  - _Requirements: 1.1-1.4, 2.1-2.4_

- [ ] 2.2 Update chat endpoint to use personas
  - File: `server/src/index.js` (or chat route file)
  - Extract Space name from request
  - Get persona using PersonaManager
  - Pass persona to prompt builder
  - _Requirements: 1.1-1.4_

- [ ] 2.3 Write integration tests for persona prompts
  - File: `server/test/persona_integration.test.mjs`
  - Test Health Space gets health persona
  - Test Finance Space gets finance persona
  - Test prompt includes persona additions
  - _Requirements: 1.1-1.4, 2.1-2.4_

---

## Checkpoint 2: Commit persona integration

**Action:** Commit with message: "feat(stage7a): Integrate personas into prompt building"

---

## Task 3: Backend - Define All Personas

Create detailed persona configurations for each Space.

- [ ] 3.1 Define Health persona
  - Empathetic, cautious tone
  - Medical disclaimers
  - Encourage consulting professionals
  - _Requirements: 2.1_

- [ ] 3.2 Define Finance persona
  - Practical, budget-conscious tone
  - Focus on saving and budgeting
  - Clear financial guidance
  - _Requirements: 2.2_

- [ ] 3.3 Define Education persona
  - Study-focused, constructive tone
  - Learning encouragement
  - Study tips and guidance
  - _Requirements: 2.3_

- [ ] 3.4 Define Travel persona
  - Exploratory, enthusiastic tone
  - Planning-focused
  - Adventure and discovery
  - _Requirements: 2.4_

---

## Checkpoint 3: Commit all personas

**Action:** Commit with message: "feat(stage7a): Define all Space personas"

---

## Task 4: Flutter - Error Recovery Foundation

Create the error recovery infrastructure.

- [ ] 4.1 Create ErrorRecoveryAttempt model
  - File: `lib/core/ai/chat/models/error_recovery_attempt.dart`
  - Fields: attemptNumber, strategyUsed, timestamp, duration, success, errorMessage
  - Add toJson() method
  - _Requirements: 3.4_

- [ ] 4.2 Create RecoveryMetrics model
  - File: `lib/core/ai/chat/models/recovery_metrics.dart`
  - Fields: totalAttempts, successfulRecoveries, failedRecoveries, fallbacksUsed
  - Calculate success rate and fallback rate
  - _Requirements: 10.1-10.3_

- [ ] 4.3 Create RecoveryConfig
  - File: `lib/core/ai/chat/config/recovery_config.dart`
  - Define max attempts, timeouts, retry delays
  - _Requirements: 9.1-9.5_

---

## Checkpoint 4: Commit recovery models

**Action:** Commit with message: "feat(stage7a): Add error recovery models and config"

---

## Task 5: Flutter - Error Classification

Implement error classification system.

- [ ] 5.1 Create ErrorClassifier class
  - File: `lib/core/ai/chat/services/error_classifier.dart`
  - Method: `classify(AiServiceException)` → ErrorType enum
  - Classify: rate-limit, network, server, validation, timeout, unknown
  - _Requirements: 6.1-6.5_

- [ ] 5.2 Write unit tests for ErrorClassifier
  - File: `test/core/ai/chat/services/error_classifier_test.dart`
  - Test each error type classification
  - Test classification consistency
  - _Requirements: 6.1-6.5_

---

## Checkpoint 5: Commit error classification

**Action:** Commit with message: "feat(stage7a): Add error classification system"

---

## Task 6: Flutter - Recovery Strategies

Implement recovery strategy classes.

- [ ] 6.1 Create ErrorRecoveryStrategy base class
  - File: `lib/core/ai/chat/services/error_recovery_strategy.dart`
  - Abstract methods: recover(), canRecover(), getRetryDelay()
  - _Requirements: 4.1-4.5_

- [ ] 6.2 Implement RateLimitRecoveryStrategy
  - Wait for rate limit delay (max 5s)
  - Retry after delay
  - _Requirements: 4.1, 6.2_

- [ ] 6.3 Implement NetworkRecoveryStrategy
  - Exponential backoff (1s, 2s)
  - Max 2 attempts
  - _Requirements: 4.4, 6.3_

- [ ] 6.4 Implement ServerErrorRecoveryStrategy
  - Immediate fallback (no retry)
  - _Requirements: 4.3, 6.4_

- [ ] 6.5 Implement TimeoutRecoveryStrategy
  - Retry once with shorter timeout
  - _Requirements: 4.2_

- [ ] 6.6 Write unit tests for all strategies
  - File: `test/core/ai/chat/services/error_recovery_strategy_test.dart`
  - Test each strategy's behavior
  - Test retry delays
  - Test max attempts
  - _Requirements: 4.1-4.5_

---

## Checkpoint 6: Commit recovery strategies

**Action:** Commit with message: "feat(stage7a): Implement error recovery strategies"

---

## Task 7: Flutter - Fallback Service

Create the fallback service that always succeeds.

- [ ] 7.1 Create FallbackService class
  - File: `lib/core/ai/chat/services/fallback_service.dart`
  - Method: `generateFallbackResponse(ChatRequest, AiServiceException)`
  - Generate helpful, context-aware messages
  - Never throw exceptions
  - _Requirements: 5.1-5.5, 7.1-7.5_

- [ ] 7.2 Write unit tests for FallbackService
  - File: `test/core/ai/chat/services/fallback_service_test.dart`
  - Test fallback for each error type
  - Test never throws
  - Test returns valid ChatResponse
  - Test user-friendly messages (no jargon)
  - _Requirements: 5.1-5.5, 7.4_

---

## Checkpoint 7: Commit fallback service

**Action:** Commit with message: "feat(stage7a): Add fallback service"

---

## Task 8: Flutter - Resilient Service Wrapper (Part 1: Foundation)

Create the basic structure of the resilient service.

- [ ] 8.1 Create ResilientAiChatService class skeleton
  - File: `lib/core/ai/chat/services/resilient_ai_chat_service.dart`
  - Create class with constructor
  - Accept primaryService, errorClassifier, fallbackService as dependencies
  - Add empty sendMessage() method
  - _Requirements: 3.1_

- [ ] 8.2 Implement basic sendMessage() flow
  - Try calling primary service
  - Return response if successful
  - Catch exceptions and rethrow for now (we'll add recovery next)
  - _Requirements: 3.1_

- [ ] 8.3 Add basic logging
  - Log when request starts
  - Log when request succeeds
  - Log when request fails
  - Use AppLogger with correlation IDs
  - _Requirements: 3.4_

---

## Checkpoint 8a: Commit resilient service foundation

**Action:** Commit with message: "feat(stage7a): Add resilient service foundation"

---

## Task 8b: Flutter - Resilient Service Wrapper (Part 2: Error Classification)

Add error classification to the resilient service.

- [ ] 8b.1 Add error classification on failure
  - When exception caught, classify using ErrorClassifier
  - Log the error type
  - Still rethrow for now
  - _Requirements: 6.1_

- [ ] 8b.2 Add strategy selection logic
  - Based on error type, select appropriate recovery strategy
  - Log which strategy was selected
  - Don't execute yet, just select
  - _Requirements: 4.1, 6.2-6.4_

---

## Checkpoint 8b: Commit error classification

**Action:** Commit with message: "feat(stage7a): Add error classification to resilient service"

---

## Task 8c: Flutter - Resilient Service Wrapper (Part 3: Single Recovery)

Implement single recovery attempt.

- [ ] 8c.1 Create _attemptRecovery() method
  - Accept request, error, attemptNumber
  - Call selected strategy's recover() method
  - Return response if successful
  - Rethrow if recovery fails
  - _Requirements: 3.1, 4.1_

- [ ] 8c.2 Integrate single recovery into sendMessage()
  - On error, attempt recovery once
  - Log recovery attempt
  - Return response if recovery succeeds
  - Rethrow if recovery fails
  - _Requirements: 3.1, 3.2_

- [ ] 8c.3 Add recovery attempt logging
  - Log attempt number
  - Log strategy used
  - Log duration
  - Log success/failure
  - _Requirements: 3.4_

---

## Checkpoint 8c: Commit single recovery

**Action:** Commit with message: "feat(stage7a): Implement single recovery attempt"

---

## Task 8d: Flutter - Resilient Service Wrapper (Part 4: Multiple Recoveries)

Add support for multiple recovery attempts.

- [ ] 8d.1 Implement recovery loop
  - Try up to 2 recovery attempts
  - Use different strategies if first fails
  - Track all attempts
  - _Requirements: 3.1, 3.2_

- [ ] 8d.2 Add recovery metrics tracking
  - Count total attempts
  - Count successes vs failures
  - Track which strategies were used
  - _Requirements: 10.1-10.3_

---

## Checkpoint 8d: Commit multiple recoveries

**Action:** Commit with message: "feat(stage7a): Add multiple recovery attempts"

---

## Task 8e: Flutter - Resilient Service Wrapper (Part 5: Fallback)

Add fallback behavior when all recoveries fail.

- [ ] 8e.1 Create _fallback() method
  - Call FallbackService.generateFallbackResponse()
  - Log fallback event
  - Return fallback response
  - _Requirements: 5.1-5.5_

- [ ] 8e.2 Integrate fallback into sendMessage()
  - After all recovery attempts fail, call _fallback()
  - Never throw exception (always return response)
  - Log that fallback was used
  - _Requirements: 5.1-5.5_

---

## Checkpoint 8e: Commit fallback integration

**Action:** Commit with message: "feat(stage7a): Add fallback behavior to resilient service"

---

## Task 8f: Flutter - Resilient Service Wrapper (Part 6: Timeouts)

Add timeout enforcement.

- [ ] 8f.1 Add total recovery timeout
  - Track total time spent on recovery
  - If > 10s, stop and use fallback
  - Log timeout events
  - _Requirements: 9.1-9.3_

- [ ] 8f.2 Add individual attempt timeout
  - Each recovery attempt has 30s timeout
  - Use Future.timeout()
  - Log timeout events
  - _Requirements: 9.4, 9.5_

- [ ] 8f.3 Write unit tests for ResilientAiChatService
  - File: `test/core/ai/chat/services/resilient_ai_chat_service_test.dart`
  - Test successful request (no errors)
  - Test single recovery succeeds
  - Test multiple recoveries
  - Test fallback after failures
  - Test timeout enforcement
  - _Requirements: 3.1-3.5, 9.1-9.5_

---

## Checkpoint 8f: Commit timeout enforcement

**Action:** Commit with message: "feat(stage7a): Add timeout enforcement to resilient service"

---

## Checkpoint 8: Commit resilient service

**Action:** Commit with message: "feat(stage7a): Implement resilient AI chat service"

---

## Task 9: Flutter - Integration and Wiring

Wire up the resilient service in the app.

- [ ] 9.1 Update dependency injection
  - File: `lib/core/di/app_container.dart` (or equivalent)
  - Register ResilientAiChatService
  - Inject ErrorClassifier, strategies, FallbackService
  - _Requirements: 3.1_

- [ ] 9.2 Update AiChatController to use resilient service
  - Replace HttpAiChatService with ResilientAiChatService
  - Ensure no breaking changes
  - _Requirements: 3.1_

- [ ] 9.3 Write integration tests
  - File: `test/integration/resilient_chat_integration_test.dart`
  - Test end-to-end recovery flow
  - Test fallback integration
  - Test persona integration (if backend available)
  - _Requirements: 3.1-3.5, 5.1-5.5_

---

## Checkpoint 9: Commit integration

**Action:** Commit with message: "feat(stage7a): Integrate resilient service into app"

---

## Task 10: Property-Based Tests (Part 1: Persona Properties)

Write property tests for persona system.

- [ ] 10.1 Create persona properties test file
  - File: `server/test/persona_properties.test.mjs`
  - Set up test framework
  - Import PersonaManager
  - _Property 1, 2_

- [ ] 10.2 Property 1: Persona selection consistency
  - Generate random Space names (health, finance, education, travel)
  - Call getPersona() multiple times for same Space
  - Verify returns same persona each time
  - _Property 1_

- [ ] 10.3 Property 2: Persona prompt inclusion
  - Generate random Spaces
  - Build prompt with persona
  - Verify prompt includes persona systemPromptAddition
  - _Property 2_

---

## Checkpoint 10a: Commit persona properties

**Action:** Commit with message: "test(stage7a): Add persona property tests"

---

## Task 10b: Property-Based Tests (Part 2: Error Classification Properties)

Write property tests for error classification.

- [ ] 10b.1 Create error classification properties test file
  - File: `test/core/ai/chat/services/error_classification_properties_test.dart`
  - Set up test framework
  - Import ErrorClassifier
  - _Property 3, 4_

- [ ] 10b.2 Property 3: Error classification determinism
  - Generate random errors (network, timeout, rate-limit, server)
  - Classify same error multiple times
  - Verify classification is consistent
  - _Property 3_

- [ ] 10b.3 Property 4: Recovery strategy selection
  - Generate random error types
  - Select strategy for each error
  - Verify appropriate strategy selected (rate-limit → RateLimitStrategy, etc.)
  - _Property 4_

---

## Checkpoint 10b: Commit error classification properties

**Action:** Commit with message: "test(stage7a): Add error classification property tests"

---

## Task 10c: Property-Based Tests (Part 3: Recovery Properties)

Write property tests for recovery behavior.

- [ ] 10c.1 Create recovery properties test file
  - File: `test/core/ai/chat/services/recovery_properties_test.dart`
  - Set up test framework
  - Import ResilientAiChatService
  - _Property 5, 6, 7_

- [ ] 10c.2 Property 5: Recovery attempt limit
  - Simulate continuous failures
  - Count recovery attempts
  - Verify max 2 attempts before fallback
  - _Property 5_

- [ ] 10c.3 Property 6: Fallback always succeeds
  - Generate random requests
  - Force all recoveries to fail
  - Verify fallback never throws exception
  - Verify always returns valid ChatResponse
  - _Property 6_

- [ ] 10c.4 Property 7: Recovery time bounds
  - Simulate recovery attempts
  - Measure total time
  - Verify time < 10 seconds
  - _Property 7_

---

## Checkpoint 10c: Commit recovery properties

**Action:** Commit with message: "test(stage7a): Add recovery property tests"

---

## Task 10d: Property-Based Tests (Part 4: Persona Switching & UX Properties)

Write property tests for persona switching and user experience.

- [ ] 10d.1 Property 8: Persona switch consistency
  - Generate sequence of Space switches
  - Send message after each switch
  - Verify persona changes with Space
  - _Property 8_

- [ ] 10d.2 Property 9: User message friendliness
  - Generate random errors
  - Get user-facing error messages
  - Verify no technical jargon (no "stack trace", "exception", "null pointer")
  - Verify messages are helpful
  - _Property 9_

---

## Checkpoint 10d: Commit UX properties

**Action:** Commit with message: "test(stage7a): Add persona switching and UX property tests"

---

## Task 10e: Property-Based Tests (Part 5: Metrics Properties)

Write property tests for metrics accuracy.

- [ ] 10e.1 Property 10: Metrics accuracy
  - Generate random sequence of recovery attempts
  - Track successes and failures manually
  - Compare with RecoveryMetrics calculations
  - Verify success rate = successes / total
  - Verify fallback rate = fallbacks / total
  - _Property 10_

---

## Checkpoint 10e: Commit metrics properties

**Action:** Commit with message: "test(stage7a): Add metrics property tests"

---

## Task 11: Manual Testing (Part 1: Documentation) (Part 1: Documentation)

Create manual test scenarios document.

- [ ] 11.1 Create manual test scenarios document
  - File: `docs/modules/ai/STAGE_7A_MANUAL_TEST_SCENARIOS.md`
  - Add document structure
  - Add "How to Test" section
  - Add "Success Criteria" section
  - _Requirements: All_

- [ ] 11.2 Document persona test scenarios
  - Add Health persona test scenario
  - Add Finance persona test scenario
  - Add Education persona test scenario
  - Add Travel persona test scenario
  - Add persona switching scenario
  - _Requirements: 1.1-1.5, 2.1-2.4_

- [ ] 11.3 Document error recovery test scenarios
  - Add network error recovery scenario
  - Add rate limit recovery scenario
  - Add timeout recovery scenario
  - Add fallback scenario
  - _Requirements: 3.1-3.5, 4.1-4.5, 5.1-5.5_

---

## Checkpoint 11a: Commit test documentation

**Action:** Commit with message: "docs(stage7a): Create manual test scenarios document"

---

## Task 11b: Manual Testing (Part 2: Persona Testing)

Execute persona tests manually.

- [ ] 11b.1 Test Health persona
  - Create 5 health records (blood pressure, medications, etc.)
  - Ask: "What is my blood pressure?"
  - Ask: "Should I be worried about my health?"
  - Verify empathetic tone
  - Verify medical disclaimers present
  - _Requirements: 1.1, 2.1_

- [ ] 11b.2 Test Finance persona
  - Create 5 finance records (expenses, income, etc.)
  - Ask: "How much did I spend this month?"
  - Ask: "Should I save more money?"
  - Verify practical, budget-conscious tone
  - Verify focus on saving and budgeting
  - _Requirements: 1.2, 2.2_

- [ ] 11b.3 Test Education persona
  - Create 5 education records (study sessions, notes, etc.)
  - Ask: "How are my studies going?"
  - Ask: "What should I study next?"
  - Verify constructive, learning-focused tone
  - Verify study tips and encouragement
  - _Requirements: 1.3, 2.3_

- [ ] 11b.4 Test Travel persona
  - Create 5 travel records (trips, plans, etc.)
  - Ask: "Where should I travel next?"
  - Ask: "What did I do on my last trip?"
  - Verify exploratory, enthusiastic tone
  - Verify planning-focused guidance
  - _Requirements: 1.4, 2.4_

---

## Checkpoint 11b: Commit persona testing results

**Action:** Commit with message: "test(stage7a): Complete persona manual testing"

---

## Task 11c: Manual Testing (Part 3: Persona Switching)

Test persona switching behavior.

- [ ] 11c.1 Test persona switching
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

**Action:** Commit with message: "test(stage7a): Complete persona switching testing"

---

## Task 11d: Manual Testing (Part 4: Error Recovery)

Test error recovery behavior.

- [ ] 11d.1 Test network error recovery
  - Send a message
  - Disconnect network mid-request (or before)
  - Observe "Retrying..." indicator
  - Reconnect network
  - Verify message eventually succeeds
  - Check logs for retry attempts
  - _Requirements: 3.1-3.5, 4.4_

- [ ] 11d.2 Test rate limit recovery (if possible)
  - Send many messages quickly
  - Trigger rate limit (if backend supports)
  - Verify system waits and retries
  - Verify eventual success
  - _Requirements: 4.1, 6.2_

---

## Checkpoint 11d: Commit error recovery testing

**Action:** Commit with message: "test(stage7a): Complete error recovery testing"

---

## Task 11e: Manual Testing (Part 5: Fallback)

Test fallback behavior.

- [ ] 11e.1 Test fallback with server down
  - Stop backend server
  - Send a message
  - Verify fallback response appears
  - Verify message is helpful (not technical)
  - Verify no crash or hang
  - _Requirements: 5.1-5.5, 7.1-7.5_

- [ ] 11e.2 Test fallback recovery
  - With server still down, note fallback behavior
  - Restart backend server
  - Send another message
  - Verify normal operation resumes
  - _Requirements: 5.3_

---

## Checkpoint 11e: Commit fallback testing

**Action:** Commit with message: "test(stage7a): Complete fallback testing"

---

## Task 12: Documentation

Create comprehensive documentation for Stage 7a.

- [ ] 12.1 Create Stage 7a overview document
  - File: `docs/modules/ai/STAGE_7A_PERSONAS_ERROR_RECOVERY.md`
  - Overview of personas and error recovery
  - How to configure personas
  - How error recovery works
  - Examples and use cases
  - _Requirements: All_

- [ ] 12.2 Update LLM_STAGES_OVERVIEW.md
  - Mark Stage 7a as complete
  - Add completion date
  - Add key metrics
  - _Requirements: All_

- [ ] 12.3 Update README
  - Add Stage 7a to features list
  - Mention persona system
  - Mention error recovery
  - _Requirements: All_

---

## Checkpoint 12: Commit documentation

**Action:** Commit with message: "docs(stage7a): Complete Stage 7a documentation"

---

## Success Criteria

Stage 7a is complete when:

- [ ] All 21 tasks completed (1-9, 10a-10e, 11a-11e, 12)
- [ ] All unit tests passing
- [ ] All property-based tests passing (10 properties)
- [ ] All integration tests passing
- [ ] Manual testing validates personas work correctly
- [ ] Manual testing validates error recovery works
- [ ] Documentation complete
- [ ] All changes committed to git

---

**Created:** December 1, 2025  
**Status:** Ready for implementation  
**Estimated Time:** 2-3 days for full implementation
