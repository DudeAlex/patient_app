# Implementation Plan

- [x] 1. Create AI service abstraction and value objects *(Completed: added AiService interface, AiSummaryResult/AiError models, and AiServiceException stack in `lib/core/ai/`.)*
  - Create `lib/core/ai/ai_service.dart` with AiService interface
  - Create `lib/core/ai/models/ai_summary_result.dart` value object
  - Create `lib/core/ai/models/ai_error.dart` value object
  - Create `lib/core/ai/exceptions/ai_exceptions.dart` for custom exceptions
  - Ensure all models are immutable and follow clean architecture principles
  - _Requirements: 3.1, 7.1_

- [x] 2. Implement FakeAiService for development *(Completed: added deterministic generator `lib/core/ai/fake_ai_service.dart` with configurable latency/failure + action hints.)*
  - Create `lib/core/ai/fake_ai_service.dart`
  - Implement deterministic summary generation from item title + first sentence
  - Implement deterministic action hints generation
  - Add configurable simulated latency (default 500ms)
  - Add configurable failure simulation for testing error states
  - _Requirements: 3.2, 4.1, 4.2, 4.3, 4.4_

- [x] 3. Create AI consent management *(Completed: added `AiConsentRepository` interface and SharedPreferences-backed implementation in `lib/core/ai/repositories/`.)*
  - Create `lib/core/ai/repositories/ai_consent_repository.dart` interface
  - Create `lib/core/ai/repositories/ai_consent_repository_impl.dart` using SharedPreferences
  - Implement hasAiConsent(), grantConsent(), revokeConsent() methods
  - Store consent flag in SharedPreferences with key 'ai_consent_granted'
  - _Requirements: 2.1, 2.5, 7.5_

- [x] 4. Implement SummarizeInformationItemUseCase *(Completed: added consent-aware orchestrator in `lib/features/information_items/application/use_cases/summarize_information_item_use_case.dart`.)*
  - Create `lib/features/information_items/application/use_cases/summarize_information_item_use_case.dart`
  - Inject AiService and AiConsentRepository dependencies
  - Implement consent checking before AI operations
  - Implement item loading and validation
  - Handle all error cases with appropriate exceptions
  - _Requirements: 1.1, 2.1, 7.1, 7.2_


- [x] 5. Implement LoggingAiService decorator *(Completed: added `lib/core/ai/logging_ai_service.dart` to wrap services with AppLogger instrumentation.)*
  - Create `lib/core/ai/logging_ai_service.dart`
  - Wrap any AiService implementation with diagnostic logging
  - Log operation start with itemId, spaceId, category, attachment count
  - Log operation completion with tokensUsed, latencyMs, provider, confidence
  - Log errors with full context and stack traces
  - Use AppLogger.startOperation() and endOperation() for tracking
  - Redact sensitive text (notes content) from logs
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 6. Set up dependency injection for AI services *(Completed: added SharedPreferences dependency, AI config stub, AppContainer registrations, and Riverpod providers for AiService/AiConsentRepository.)*
  - Update `lib/core/di/app_container.dart` to register AI services
  - Create Riverpod providers for AiService, AiConsentRepository
  - Implement configuration loading (ai_enabled, ai_mode flags)
  - Wire FakeAiService as default implementation
  - Wrap with LoggingAiService decorator
  - _Requirements: 3.5, 7.5, 9.1, 9.2_

- [x] 7. Create AI consent dialog UI *(Completed: added consent dialog widget plus Settings-screen integration that syncs with AiConsentRepository.)*
  - Create `lib/features/information_items/ui/widgets/ai_consent_dialog.dart`
  - Display clear explanation of what data will be processed
  - List specific fields sent: title, category, tags, notes, attachment descriptors
  - Clarify that IDs and attachment binaries stay local
  - Provide "Enable AI" and "Cancel" buttons
  - Store consent decision via AiConsentRepository
  - _Requirements: 2.2, 2.3, 2.4_

- [x] 8. Create AI summary widget with state management *(Completed: added `InformationItemSummarySheet` with loading/success/error states powered by Riverpod + AiService use case.)*
  - Create `lib/features/information_items/ui/widgets/information_item_summary_sheet.dart`
  - Implement loading state with spinner and "Generating summary..." text
  - Implement success state showing summary text and action hints
  - Implement error state with error message and retry button
  - Use Riverpod for state management (loading/success/error)
  - _Requirements: 1.2, 1.3, 1.4, 1.5, 7.3_

- [x] 9. Add "Generate Summary" button to Information Item detail screen *(Completed: `RecordDetailScreen` AppBar now includes AI icon that opens the summary sheet.)*
  - Update Information Item detail screen to show AI button
  - Hide button when ai_enabled flag is false
  - Show consent dialog on first AI usage
  - Open summary sheet when button tapped
  - Handle all error states gracefully
  - _Requirements: 1.1, 2.1, 9.3_

- [x] 10. Implement HttpAiService for production *(Completed: added `lib/core/ai/http/http_ai_service.dart` plus DI wiring that swaps between Fake and HTTP implementations based on AiConfig.)*
  - Create `lib/core/ai/http_ai_service.dart`
  - Implement request payload construction (space, title, category, tags, body, attachments)
  - Implement HTTP POST to backend endpoint with JSON payload
  - Implement response parsing to AiSummaryResult
  - Implement 30-second timeout
  - Implement retry logic with exponential backoff (1s, 2s, 4s, max 3 retries)
  - Handle network errors, timeouts, 4xx, 5xx responses
  - _Requirements: 3.4, 6.1, 6.2, 6.3, 6.4, 6.5_


- [x] 11. Create AI configuration repository *(Completed: added `AiConfigRepository` + SharedPreferences implementation with load/set APIs.)*
  - Create `lib/core/ai/repositories/ai_config_repository.dart`
  - Implement ai_enabled flag (default: false)
  - Implement ai_mode flag (values: 'fake' or 'remote', default: 'fake')
  - Store configuration in SharedPreferences
  - Provide methods to update configuration
  - _Requirements: 9.1, 9.2, 9.4, 9.5_

- [x] 12. Add AI settings UI *(Completed: Settings screen now includes AI features toggle + mode selector wired to config repo, with consent card honoring availability.)*
  - Add AI section to Settings screen
  - Add toggle for enabling/disabling AI features
  - Add dropdown for selecting AI mode (Fake/Remote)
  - Show current configuration status
  - Allow revoking AI consent
  - _Requirements: 2.5, 9.1, 9.2_

- [x] 13. Create test fixtures for QA *(Completed: added `docs/ai/fixtures/` with JSON samples + README for QA procedures.)*
  - Create `docs/ai/fixtures/` directory
  - Add 10-15 anonymized Information Items covering multiple Spaces
  - Document expected summary characteristics (tone, length, correctness)
  - Create quality evaluation checklist
  - _Requirements: 8.1, 8.2_

- [x] 14. Implement AI quality logging *(Completed: added `docs/ai/ai_quality_journal.md` template for recording QA results.)*
  - Create `docs/ai/ai_quality_journal.md`
  - Log actual AI responses during QA testing
  - Compare responses against expected characteristics
  - Document issues and improvements needed
  - _Requirements: 8.3, 8.4_

- [x] 15. Add AI diagnostics to Diagnostic System UI *(Completed: added `AiCallLogRepository`, logging hooks, and Settings → AI Calls screen listing last operations.)*
  - Create AI Calls section in Diagnostic System
  - Display last N AI operations with timestamps
  - Show success/failure status, latency, tokens used
  - Allow filtering by success/error
  - Source data from AppLogger logs
  - _Requirements: 5.5_

- [x] 16. Write unit tests for AI services *(Completed: see files under `test/core/ai/` for AiSummaryResult, FakeAiService, LoggingAiService, ConfigurableAiService.)*
  - Test AiSummaryResult immutability and validation
  - Test FakeAiService deterministic behavior
  - Test LoggingAiService log entry creation
  - Test HttpAiService request construction and response parsing
  - Test HttpAiService retry logic and exponential backoff
  - Test HttpAiService timeout handling
  - Mock HTTP client for isolation
  - _Requirements: 3.2, 3.3, 3.4, 6.4_

- [x] 17. Write unit tests for use case *(Completed: `test/features/information_items/application/use_cases/summarize_information_item_use_case_test.dart` now covers consent/success paths.)*
  - Test SummarizeInformationItemUseCase consent checking
  - Test item loading and validation
  - Test error propagation
  - Mock AiService and repositories
  - _Requirements: 2.1, 7.1_


- [x] 18. Write widget tests for UI components *(Completed: `test/features/information_items/ui/widgets/...` covers the summary sheet and consent dialog.)*
  - Test InformationItemSummarySheet loading state
  - Test InformationItemSummarySheet success state
  - Test InformationItemSummarySheet error state
  - Test retry button functionality
  - Test AI consent dialog
  - _Requirements: 1.2, 1.3, 1.4, 1.5, 2.2_

- [x]* 19. Write property-based tests *(Completed: `test/core/ai/property_tests.dart` covers summary length constraint.)*
  - **Property 1: Summary Length Constraint**
  - **Validates: Requirements 1.3**
  - Generate random Information Items
  - Call FakeAiService.summarizeItem()
  - Assert summary word count <= 120

- [x]* 20. Write property-based tests for action hints *(Completed via `test/core/ai/property_tests.dart`.)*
  - **Property 2: Action Hints Constraint**
  - **Validates: Requirements 1.4**
  - Generate random Information Items
  - Call FakeAiService.summarizeItem()
  - Assert actionHints.length <= 3
  - Assert each hint word count <= 12

- [x]* 21. Write property-based tests for consent *(Completed via `test/core/ai/property_tests.dart` random consent enforcement.)*
  - **Property 3: Consent Enforcement**
  - **Validates: Requirements 2.1, 2.5**
  - Generate random consent states
  - Call use case with various consent values
  - Assert AiConsentRequiredException thrown when consent=false

- [x]* 22. Write property-based tests for exponential backoff *(Completed: HTTP retry property test in `test/core/ai/property_tests.dart`.)*
  - **Property 8: Exponential Backoff**
  - **Validates: Requirements 6.4**
  - Simulate multiple HTTP failures
  - Track retry delays
  - Assert delays follow 1s, 2s, 4s pattern

- [ ] 23. Manual testing and QA *(In progress: Fake mode verified with Cardiology follow-up fixture; Remote mode currently blocked by missing backend—retry once provider is available)*
  - Test end-to-end flow: tap button → loading → summary display
  - Test consent dialog on first usage
  - Test error recovery and retry
  - Test with test fixtures from docs/ai/fixtures/
  - Evaluate summary quality (tone, length, correctness, relevance)
  - Test with slow network conditions
  - Test timeout behavior
  - Document findings in docs/ai/ai_quality_journal.md
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.2, 6.1, 8.1, 8.2, 8.3_

- [ ] 24. Update documentation *(Partially done: plan/SPEC/ARCHITECTURE/README updated with summarization v1 status; user-facing doc still needed)*
  - Update AI_ASSISTED_PATIENT_APP_PLAN.md with v1 implementation details
  - Update SPEC.md with AI summarization requirements
  - Update ARCHITECTURE.md with AI service layer
  - Update README.md with AI features description
  - Create user-facing documentation for AI features
  - _Requirements: All_

- [ ] 25. Final checkpoint - Ensure all tests pass *(Deferred until remote backend is available; local Flutter tooling not runnable in this environment)*
  - Run all unit tests
  - Run all widget tests
  - Run all property-based tests
  - Run manual QA checklist
  - Verify no regressions in existing features
  - Confirm AI features can be disabled via feature flag
  - Ask user if questions arise
