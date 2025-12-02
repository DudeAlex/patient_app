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

## Task 8: Flutter - Resilient Service Wrapper

Create the main resilient service that orchestrates recovery.

- [ ] 8.1 Create ResilientAiChatService class
  - File: `lib/core/ai/chat/services/resilient_ai_chat_service.dart`
  - Wrap HttpAiChatService
  - Implement sendMessage() with recovery logic
  - _Requirements: 3.1-3.5_

- [ ] 8.2 Implement recovery orchestration
  - Try primary service
  - On error: classify → select strategy → attempt recovery
  - Max 2 recovery attempts
  - Fallback if all attempts fail
  - _Requirements: 3.1-3.5, 4.1-4.5_

- [ ] 8.3 Add comprehensive logging
  - Log all recovery attempts
  - Log strategy selection
  - Log fallback events
  - Use correlation IDs
  - _Requirements: 3.4, 5.4_

- [ ] 8.4 Implement timeout enforcement
  - Total recovery time < 10s
  - Individual attempt timeout: 30s
  - _Requirements: 9.1-9.5_

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

## Task 10: Property-Based Tests

Write property-based tests for correctness properties.

- [ ] 10.1 Property 1: Persona selection consistency
  - File: `server/test/persona_properties.test.mjs`
  - Generate random Space names
  - Verify getPersona() returns same result
  - _Property 1_

- [ ] 10.2 Property 2: Persona prompt inclusion
  - Generate random Spaces
  - Verify prompt includes persona text
  - _Property 2_

- [ ] 10.3 Property 3: Error classification determinism
  - File: `test/core/ai/chat/services/error_classification_properties_test.dart`
  - Generate random errors
  - Verify classification consistency
  - _Property 3_

- [ ] 10.4 Property 4: Recovery strategy selection
  - Generate random error types
  - Verify appropriate strategy selected
  - _Property 4_

- [ ] 10.5 Property 5: Recovery attempt limit
  - File: `test/core/ai/chat/services/recovery_limit_properties_test.dart`
  - Simulate failures
  - Verify max 2 attempts
  - _Property 5_

- [ ] 10.6 Property 6: Fallback always succeeds
  - Generate random requests
  - Verify fallback never throws
  - _Property 6_

- [ ] 10.7 Property 7: Recovery time bounds
  - Simulate recoveries
  - Verify time < 10s
  - _Property 7_

- [ ] 10.8 Property 8: Persona switch consistency
  - Generate Space switches
  - Verify persona changes
  - _Property 8_

- [ ] 10.9 Property 9: User message friendliness
  - Generate errors
  - Verify no jargon in messages
  - _Property 9_

- [ ] 10.10 Property 10: Metrics accuracy
  - Generate recovery sequences
  - Verify metrics calculations
  - _Property 10_

---

## Checkpoint 10: Commit property tests

**Action:** Commit with message: "test(stage7a): Add property-based tests"

---

## Task 11: Manual Testing

Create manual test scenarios and documentation.

- [ ] 11.1 Create manual test scenarios document
  - File: `docs/modules/ai/STAGE_7A_MANUAL_TEST_SCENARIOS.md`
  - Persona testing scenarios
  - Error recovery scenarios
  - Fallback testing scenarios
  - _Requirements: All_

- [ ] 11.2 Test Health persona
  - Create health records
  - Ask health questions
  - Verify empathetic tone and disclaimers
  - _Requirements: 1.1, 2.1_

- [ ] 11.3 Test Finance persona
  - Create finance records
  - Ask finance questions
  - Verify practical, budget-focused tone
  - _Requirements: 1.2, 2.2_

- [ ] 11.4 Test Education persona
  - Create education records
  - Ask study questions
  - Verify constructive, learning-focused tone
  - _Requirements: 1.3, 2.3_

- [ ] 11.5 Test Travel persona
  - Create travel records
  - Ask travel questions
  - Verify exploratory, planning tone
  - _Requirements: 1.4, 2.4_

- [ ] 11.6 Test persona switching
  - Start in Health Space
  - Switch to Finance Space mid-conversation
  - Verify persona changes
  - _Requirements: 1.5_

- [ ] 11.7 Test network error recovery
  - Disconnect network
  - Send message
  - Verify retry and recovery
  - _Requirements: 3.1-3.5, 4.4_

- [ ] 11.8 Test fallback behavior
  - Stop backend server
  - Send message
  - Verify fallback response
  - Verify helpful error message
  - _Requirements: 5.1-5.5, 7.1-7.5_

---

## Checkpoint 11: Commit manual testing

**Action:** Commit with message: "docs(stage7a): Add manual test scenarios and complete testing"

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

- [ ] All 12 tasks completed
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
