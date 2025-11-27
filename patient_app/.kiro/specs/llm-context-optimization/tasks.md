# Implementation Plan

## Stage 3: Basic Space Context

- [x] 1. Create RecordSummaryFormatter
  - Create `lib/core/ai/chat/context/record_summary_formatter.dart`
  - Implement format() method
  - Implement note truncation (100 chars)
  - Implement token estimation
  - Handle missing fields gracefully
  - _Requirements: 2.2, 2.3_

- [x] 2. Create SpaceContextBuilder
  - Create `lib/core/ai/chat/context/space_context_builder.dart`
  - Inject RecordsRepository and SpaceManager
  - Implement buildContext() method
  - Load Space metadata (name, description, categories)
  - Load last 10 records from Space
  - Format record summaries
  - Estimate total token usage
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.5_

- [x] 3. Update SpaceContext model
  - Update `lib/core/ai/chat/models/space_context.dart`
  - Add description field
  - Add categories field
  - Add recentRecords field (List<RecordSummary>)
  - Add maxContextRecords field (default 10)
  - Update toJson() method
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 4. Create RecordSummary model
  - Create `lib/core/ai/chat/models/record_summary.dart`
  - Add fields: title, type, date, tags, summary
  - Implement toJson() method
  - Add validation (summary max 100 chars)
  - _Requirements: 2.2, 2.3_

- [x] 5. Update SendChatMessageUseCase for Stage 3
  - Load active Space ID
  - Call SpaceContextBuilder.buildContext()
  - Include SpaceContext in ChatRequest
  - Log context assembly time
  - _Requirements: 1.1, 2.1_

- [x] 6. Update ChatRequest model for Stage 3
  - Add context field (SpaceContext)
  - Update toJson() to include context
  - _Requirements: 1.1, 2.1_

- [x] 7. Update backend prompt template for Stage 3
  - Add Space name, description, categories to prompt
  - Add record summaries section
  - Format as: "Title (Type) - Date - Tags: [...] - Summary"
  - Update token budget to 4000 total
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 3.1, 3.2_

- [x] 8. Add context assembly logging
  - Log context assembly start
  - Log Space ID and record count
  - Log token estimate
  - Log assembly duration
  - _Requirements: 9.1, 9.2_

- [x] 9. Write unit tests for RecordSummaryFormatter
  - Test note truncation at 100 chars
  - Test handling null/empty notes
  - Test token estimation
  - Test various record types
  - _Requirements: 10.1_

- [x] 10. Write unit tests for SpaceContextBuilder
  - Test loading Space metadata
  - Test loading last 10 records
  - Test record summary formatting
  - Test token estimation
  - Mock RecordsRepository and SpaceManager
  - _Requirements: 10.1_

- [x] 11. Write integration test for Stage 3 flow
  - Create Space with 15 records
  - Send chat message
  - Verify context includes last 10 records
  - Verify Space metadata included
  - Verify token budget ~4000
  - _Requirements: 10.4_

- [x] 12. Write property-based test for Space isolation
  - **Property 1: Space Isolation**
  - **Validates: Requirements 1.4**
  - Generate random Spaces with records
  - Build context for each Space
  - Assert all records match Space ID

- [x] 13. Write property-based test for deleted record exclusion
  - **Property 2: Deleted Record Exclusion**
  - **Validates: Requirements 2.4**
  - Generate records with some deleted
  - Build context
  - Assert no deleted records included

- [x] 14. Write property-based test for summary truncation
  - **Property 3: Record Summary Truncation**
  - **Validates: Requirements 2.3**
  - Generate records with long notes
  - Format summaries
  - Assert all summaries ≤ 100 chars

- [x] 15. Manual testing for Stage 3
  - Test Space context inclusion
  - Test record references in responses
  - Test Space switching
  - Document scenarios in TESTING.md
  - _Requirements: 11.1, 11.2, 11.3, 14.1, 14.2_

- [x] 16. Stage 3 checkpoint - Ensure all tests pass
  - Run all unit tests
  - Run integration tests
  - Run property-based tests
  - Run manual QA checklist
  - Verify response quality improved vs Stage 2
  - Ask user if questions arise


## Stage 4: Context Optimization

- [x] 17. Create DateRange model
  - Create `lib/core/ai/chat/models/date_range.dart`
  - Add start and end fields
  - Add factory methods: last7Days(), last14Days(), last30Days()
  - _Requirements: 4.1, 4.3_

- [x] 18. Create ContextFilters model
  - Create `lib/core/ai/chat/models/context_filters.dart`
  - Add dateRange field
  - Add maxRecords field
  - Add spaceId field
  - Implement toJson() method
  - _Requirements: 4.1, 5.1_

- [x] 19. Create TokenAllocation model
  - Create `lib/core/ai/chat/models/token_allocation.dart`
  - Add fields: system, context, history, response, total
  - Implement toJson() method
  - _Requirements: 3.2, 7.1_

- [x] 20. Create ContextStats model
  - Create `lib/core/ai/chat/models/context_stats.dart`
  - Add fields: recordsFiltered, recordsIncluded, tokensEstimated, tokensAvailable, compressionRatio, assemblyTime
  - Implement toJson() method
  - _Requirements: 9.1, 9.5_

- [x] 21. Create ContextFilterEngine
  - Create `lib/core/ai/chat/context/context_filter_engine.dart`
  - Implement filterRecords() method
  - Apply date range filter
  - Exclude deleted records
  - Exclude records from other Spaces
  - Log filtering statistics
  - _Requirements: 4.1, 4.2, 5.1_

- [x] 22. Create RecordRelevanceScorer
  - Create `lib/core/ai/chat/context/record_relevance_scorer.dart`
  - Implement calculateScore() method
  - Calculate recency score (0-10)
  - Calculate access frequency score (0-10)
  - Combine scores: (recency × 0.7) + (frequency × 0.3)
  - Implement sortByRelevance() method
  - Log relevance scores
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

**Pending follow-up: resolved** — AI chat tests now pass a `tokenBudgetAllocator` and payload expectations tolerate `filters`/`tokenBudget` where applicable across `test/integration`, `test/property`, `test/features/ai_chat`, and `test/core/ai`; suites are green.

- [x] 23. Create TokenBudgetAllocator
  - Create `lib/core/ai/chat/context/token_budget_allocator.dart`
  - Implement allocate() method
  - Define budget: system (800), context (2000), history (1000), response (1000)
  - Implement getAvailableForContext() method
  - Enforce minimum response reservation (1000 tokens)
  - _Requirements: 3.2, 7.1, 7.2, 7.4_

- [x] 24. Create ContextTruncationStrategy
  - Create `lib/core/ai/chat/context/context_truncation_strategy.dart`
  - Implement truncateToFit() method
  - Iterate through sorted records
  - Add records while tokens available
  - Stop at 20 records or budget exhausted
  - Remove lowest-scoring records first
  - Log truncation events
  - _Requirements: 5.1, 5.2, 7.3, 7.4_

- [x] 25. Update SpaceContextBuilder for Stage 4
  - Inject ContextFilterEngine, RecordRelevanceScorer, TokenBudgetAllocator, ContextTruncationStrategy
  - Load ALL records from Space (not just last 10)
  - Apply date range filter
  - Score and sort by relevance
  - Allocate token budget
  - Truncate to fit budget
  - Build optimized SpaceContext
  - Generate ContextStats
  - _Requirements: 4.1, 5.1, 6.1, 7.1_

- [x] 26. Update SendChatMessageUseCase for Stage 4
  - Get date range from configuration (default 14 days)
  - Pass date range to SpaceContextBuilder
  - Include ContextFilters in ChatRequest
  - Include TokenAllocation in ChatRequest
  - Include ContextStats in response metadata
  - NOTE: ✅ COMPLETE - All requirements implemented. DateRange.last14Days() passed to SpaceContextBuilder; ContextFilters and TokenAllocation included in ChatRequest; ContextStats surfaced in response metadata and logging. Implemented in commits `253a1ca`, `b05e0a3`.
  - _Requirements: 4.1, 7.1, 9.5_

- [x] 27. Update ChatRequest model for Stage 4



  - Add filters field (ContextFilters)
  - Add tokenBudget field (TokenAllocation)
  - Update toJson() to include new fields
  - _Requirements: 4.1, 7.1_

- [x] 28. Update ChatResponse model for Stage 4



  - Add contextStats field to metadata
  - Update fromJson() to parse stats
  - _Requirements: 9.5_

- [x] 29. Update backend prompt template for Stage 4


  - Add context notes: "Showing X of Y records"
  - Add date range note: "Date range: last N days"
  - Add acknowledgment: "Older records may be excluded"
  - Update token budget to 4800 total
  - _Requirements: 3.1, 3.2, 8.1, 8.2_

- [ ] 30. Add comprehensive context logging
  - Log date range used
  - Log records filtered vs included
  - Log relevance scores
  - Log token allocation breakdown
  - Log truncation events with reason
  - Log assembly time
  - _Requirements: 9.1, 9.2, 9.3, 9.4_

- [ ] 31. Create ContextConfig for configuration
  - Create `lib/core/ai/chat/config/context_config.dart`
  - Add maxRecordsStage3 (10)
  - Add maxRecordsStage4 (20)
  - Add defaultDateRange (14 days)
  - Add totalTokenBudget (4800)
  - Add factory methods for Stage 3 and Stage 4
  - _Requirements: 4.1, 4.5, 5.5_

- [ ] 32. Add Settings UI for date range
  - Update Settings screen
  - Add "Context Settings" section
  - Add date range dropdown (7/14/30 days)
  - Persist selection in SharedPreferences
  - _Requirements: 4.5_

- [ ] 33. Add viewCount field to Record model
  - Update Record Isar schema
  - Add viewCount field (default 0)
  - Increment on record view
  - Use for access frequency scoring
  - Run database migration
  - _Requirements: 6.2, 6.3_

- [ ] 34. Write unit tests for ContextFilterEngine
  - Test date range filtering
  - Test Space filtering
  - Test deleted record exclusion
  - Test filter combinations
  - _Requirements: 10.1_

- [ ] 35. Write unit tests for RecordRelevanceScorer
  - Test recency scoring (0-10 scale)
  - Test frequency scoring (0-10 scale)
  - Test combined score calculation
  - Test sorting by relevance
  - _Requirements: 10.2_

- [ ] 36. Write unit tests for TokenBudgetAllocator
  - Test budget allocation strategy
  - Test available token calculation
  - Test response reservation enforcement
  - _Requirements: 10.3_

- [ ] 37. Write unit tests for ContextTruncationStrategy
  - Test truncation to fit budget
  - Test 20-record limit
  - Test lowest-score-first removal
  - Test truncation statistics
  - _Requirements: 10.3_

- [ ] 38. Write integration test for Stage 4 flow
  - Create Space with 50 records (various dates)
  - Send chat message
  - Verify date filtering (last 14 days)
  - Verify relevance scoring applied
  - Verify top records selected
  - Verify token budget optimized
  - Verify context stats logged
  - _Requirements: 10.4_

- [ ] 39. Write property-based test for token budget enforcement
  - **Property 4: Token Budget Enforcement**
  - **Validates: Requirements 3.1, 3.2**
  - Generate random record sets
  - Build optimized context
  - Assert total tokens ≤ budget

- [ ] 40. Write property-based test for date range filtering
  - **Property 5: Date Range Filtering**
  - **Validates: Requirements 4.2**
  - Generate records with random dates
  - Apply date range filter
  - Assert all records within range

- [ ] 41. Write property-based test for record count limit
  - **Property 6: Record Count Limit**
  - **Validates: Requirements 5.1**
  - Generate large record sets (50-100)
  - Build optimized context
  - Assert ≤ 20 records included

- [ ] 42. Write property-based test for relevance sorting
  - **Property 7: Relevance Sorting**
  - **Validates: Requirements 6.4**
  - Generate records with random scores
  - Sort by relevance
  - Assert descending order

- [ ] 43. Write property-based test for response token reservation
  - **Property 8: Response Token Reservation**
  - **Validates: Requirements 7.2**
  - Generate random token allocations
  - Assert ≥ 1000 tokens reserved for response

- [ ] 44. Write property-based test for truncation precedence
  - **Property 10: Truncation Precedence**
  - **Validates: Requirements 7.3**
  - Generate scored records
  - Truncate to fit budget
  - Assert lower scores removed first

- [ ] 45. Manual testing for Stage 4
  - Test date range filtering
  - Test relevance scoring
  - Test token budget optimization
  - Test context stats display
  - Document scenarios in TESTING.md
  - _Requirements: 14.1, 14.2, 14.3, 14.4_

- [ ] 46. Measure token savings
  - Compare Stage 3 vs Stage 4 token usage
  - Calculate average savings percentage
  - Verify 20-30% savings achieved
  - Document findings
  - _Requirements: 15.4_

- [ ] 47. Collect user feedback
  - Add thumbs up/down buttons to AI responses
  - Store feedback with message ID
  - Track feedback scores per stage
  - Compare Stage 2 vs Stage 3 vs Stage 4
  - _Requirements: 15.1, 15.2, 15.3_

- [ ] 48. Create context metrics dashboard
  - Track average records included per request
  - Track average token usage per request
  - Track context assembly time
  - Track truncation frequency
  - Display in Settings or Diagnostics
  - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_

- [ ] 49. Stage 4 checkpoint - Ensure all tests pass
  - Run all unit tests
  - Run all integration tests
  - Run all property-based tests
  - Run manual QA checklist
  - Verify token savings (20-30%)
  - Verify response quality maintained or improved
  - Ask user if questions arise

- [ ] 50. Update documentation
  - Update README.md with Stages 3-4 details
  - Update ARCHITECTURE.md with context optimization
  - Update SPEC.md with new requirements
  - Document context configuration options
  - Document relevance scoring algorithm
  - Document token budget strategy
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5_

- [ ] 51. Final checkpoint - Production readiness
  - All tests passing
  - Performance benchmarks met
  - Token savings validated
  - Response quality improved
  - User feedback positive
  - Documentation complete
  - Monitoring and metrics configured
