# Implementation Plan

## Overview

This implementation plan breaks down Stage 7b (Telemetry & Analytics) into detailed, actionable tasks. The plan follows an incremental approach: implement data collection first, then aggregation, then alerts, then dashboard.

**Task Breakdown:**
- **Main Tasks:** 10 task groups
- **Total Subtasks:** 60+ individual coding tasks

**Important Notes:**
- Each task builds on previous tasks
- Tasks are broken down to minimize complexity
- Test as you go (unit tests after each component)
- Commit after each checkpoint
- Backend and Flutter changes can be developed in parallel

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

---

## Task List

### Task 1: Set up telemetry infrastructure

Create the foundational data models and interfaces for telemetry.

- [ ] 1.1 Create MetricType enum
  - File: `lib/core/ai/chat/telemetry/models/metric_type.dart`
  - Values: requestRate, totalLatency, contextLatency, llmLatency, promptTokens, completionTokens, totalTokens, errorRate, cacheHitRate
  - _Requirements: All_

- [ ] 1.2 Create TimeWindow enum
  - File: `lib/core/ai/chat/telemetry/models/time_window.dart`
  - Values: minute, hour, day, week, month
  - _Requirements: 1.1-1.3, 2.5_

- [ ] 1.3 Create MetricDataPoint model
  - File: `lib/core/ai/chat/telemetry/models/metric_data_point.dart`
  - Fields: timestamp, value, metadata
  - _Requirements: All_

- [ ] 1.4 Create TokenUsageStats model
  - File: `lib/core/ai/chat/telemetry/models/token_usage_stats.dart`
  - Fields: totalTokens, promptTokens, completionTokens, byUser, bySpace, averagePerRequest
  - _Requirements: 3.1-3.5_

- [ ] 1.5 Create LatencyStats model
  - File: `lib/core/ai/chat/telemetry/models/latency_stats.dart`
  - Fields: average, median, p95, p99, min, max
  - _Requirements: 2.1-2.5_


- [ ] 1.6 Create ErrorStats model
  - File: `lib/core/ai/chat/telemetry/models/error_stats.dart`
  - Fields: totalErrorRate, errorRateByType, errorCountByType, totalErrors, totalRequests
  - _Requirements: 4.1-4.5_

---

## Checkpoint 1: Commit data models

**Actions Required:**
1. Mark tasks 1.1-1.6 as complete [x]
2. Commit: `git commit -m "feat(stage7b): Add telemetry data models"`
3. STOP and ask user before continuing

---

### Task 2: Implement time-series storage

Create efficient in-memory storage for time-series metrics.

- [ ] 2.1 Create TimeSeriesBuffer class
  - File: `lib/core/ai/chat/telemetry/storage/time_series_buffer.dart`
  - Implement circular buffer with fixed size
  - Methods: add(), getRange(), cleanup()
  - _Requirements: 7.1-7.5, 9.3_

- [ ] 2.2 Create MetricsStore class
  - File: `lib/core/ai/chat/telemetry/storage/metrics_store.dart`
  - Initialize buffers for all metric types
  - Implement memory management (50MB limit)
  - _Requirements: 9.3_

- [ ] 2.3 Write TimeSeriesBuffer tests
  - File: `test/core/ai/chat/telemetry/storage/time_series_buffer_test.dart`
  - Test add, getRange, cleanup
  - Test memory limits
  - _Requirements: 7.1-7.5_

- [ ] 2.4 Write MetricsStore tests
  - File: `test/core/ai/chat/telemetry/storage/metrics_store_test.dart`
  - Test buffer initialization
  - Test memory management
  - _Requirements: 9.3_

---

## Checkpoint 2: Commit storage layer

**Actions Required:**
1. Mark tasks 2.1-2.4 as complete [x]
2. Commit: `git commit -m "feat(stage7b): Add time-series storage layer"`
3. STOP and ask user before continuing

---

### Task 3: Implement telemetry collector

Create the component that intercepts requests and collects metrics.

- [x] 3.1 Create TelemetryCollector interface
  - File: `lib/core/ai/chat/telemetry/interfaces/telemetry_collector.dart`
  - Methods: startRequest(), completeRequest(), recordError()
  - _Requirements: All_

- [x] 3.2 Implement TelemetryCollectorImpl
  - File: `lib/core/ai/chat/telemetry/services/telemetry_collector_impl.dart`
  - Generate unique request IDs
  - Timestamp all events
  - Emit events asynchronously
  - _Requirements: 9.1, 9.4_

- [x] 3.3 Write TelemetryCollector tests
  - File: `test/core/ai/chat/telemetry/services/telemetry_collector_test.dart`
  - Test request ID generation
  - Test event emission
  - Test async behavior
  - _Requirements: 9.1, 9.4_

---

## Checkpoint 3: Commit telemetry collector

**Actions Required:**
1. Mark tasks 3.1-3.3 as complete [x]
2. Commit: `git commit -m "feat(stage7b): Add telemetry collector"`
3. STOP and ask user before continuing

---

### Task 4: Implement metrics aggregation service

Create the service that aggregates raw metrics into statistics.

- [x] 4.1 Create MetricsAggregationService interface
  - File: `lib/core/ai/chat/telemetry/interfaces/metrics_aggregation_service.dart`
  - Methods: getCurrentRequestRate(), getAverageLatency(), getTokenUsage(), getErrorRates(), getCacheHitRate(), getHistoricalMetrics()
  - _Requirements: 1.1-5.5_

- [x] 4.2 Implement request rate tracking
  - File: `lib/core/ai/chat/telemetry/services/metrics_aggregation_service_impl.dart`
  - Track requests per minute, hour, day
  - Track by user and Space
  - _Requirements: 1.1-1.5_

- [x] 4.3 Implement latency tracking
  - Calculate average, median, p95, p99
  - Track total, context, LLM latencies separately
  - _Requirements: 2.1-2.5_

- [x] 4.4 Implement token usage tracking
  - Track prompt and completion tokens
  - Aggregate by user and Space
  - Calculate trends
  - _Requirements: 3.1-3.5_

- [x] 4.5 Implement error rate tracking
  - Calculate error rate percentage
  - Categorize by error type
  - Track trends
  - Detect spikes
  - _Requirements: 4.1-4.5_

- [x] 4.6 Implement cache hit rate tracking
  - Track cache hits and misses
  - Calculate hit rate percentage
  - Aggregate by Space
  - _Requirements: 5.1-5.5_

- [x] 4.7 Write MetricsAggregationService tests
  - File: `test/core/ai/chat/telemetry/services/metrics_aggregation_service_test.dart`
  - Test all aggregation methods
  - Test statistical calculations
  - _Requirements: 1.1-5.5_

---

## Checkpoint 4: Commit metrics aggregation

**Actions Required:**
1. Mark tasks 4.1-4.7 as complete [x]
2. Commit: `git commit -m "feat(stage7b): Add metrics aggregation service"`
3. STOP and ask user before continuing

---

### Task 5: Implement alert monitoring service

Create the service that monitors metrics and triggers alerts.

- [x] 5.1 Create AlertCondition model
  - File: `lib/core/ai/chat/telemetry/models/alert_condition.dart`
  - Fields: operator, evaluationWindow, consecutiveViolations
  - _Requirements: 8.1-8.5_

- [x] 5.2 Create Alert model
  - File: `lib/core/ai/chat/telemetry/models/alert.dart`
  - Fields: alertId, triggeredAt, metric, actualValue, threshold, message
  - _Requirements: 8.1-8.5_

- [x] 5.3 Create AlertMonitoringService interface
  - File: `lib/core/ai/chat/telemetry/interfaces/alert_monitoring_service.dart`
  - Methods: registerAlert(), checkAlerts(), getTriggeredAlerts()
  - _Requirements: 8.1-8.5_

- [x] 5.4 Implement AlertMonitoringServiceImpl
  - File: `lib/core/ai/chat/telemetry/services/alert_monitoring_service_impl.dart`
  - Check alerts every 30 seconds
  - Require consecutive violations
  - Log triggered alerts
  - _Requirements: 8.1-8.5_

- [x] 5.5 Register default alerts
  - Error rate > 10%
  - Latency > 5 seconds
  - Token usage > budget + 20%
  - Request rate > capacity + 50%
  - _Requirements: 8.1-8.4_

- [x] 5.6 Write AlertMonitoringService tests
  - File: `test/core/ai/chat/telemetry/services/alert_monitoring_service_test.dart`
  - Test threshold checking
  - Test alert triggering
  - Test consecutive violations
  - _Requirements: 8.1-8.5_

---

## Checkpoint 5: Commit alert monitoring

**Actions Required:**
1. Mark tasks 5.1-5.6 as complete [x]
2. Commit: `git commit -m "feat(stage7b): Add alert monitoring service"`
3. STOP and ask user before continuing

---

### Task 6: Implement dashboard API (Backend)

Create REST API endpoints for dashboard.

- [ ] 6.1 Create metrics controller
  - File: `server/src/telemetry/metrics_controller.js`
  - Endpoint: GET /api/metrics/current
  - Return current metrics snapshot
  - _Requirements: 6.1-6.5_

- [ ] 6.2 Create historical metrics endpoint
  - Endpoint: GET /api/metrics/historical
  - Query params: type, start, end, aggregation
  - Return time-series data
  - _Requirements: 7.1-7.5_

- [ ] 6.3 Create alerts endpoint
  - Endpoint: GET /api/metrics/alerts
  - Return triggered alerts
  - _Requirements: 8.5_

- [ ] 6.4 Add authentication middleware
  - Require admin authentication
  - Rate limit dashboard API
  - _Requirements: 10.4_

- [ ] 6.5 Write API tests
  - File: `server/test/telemetry/metrics_controller.test.js`
  - Test all endpoints
  - Test authentication
  - _Requirements: 6.1-6.5, 7.1-7.5_

---

## Checkpoint 6: Commit dashboard API

**Actions Required:**
1. Mark tasks 6.1-6.5 as complete [x]
2. Commit: `git commit -m "feat(stage7b): Add dashboard API endpoints"`
3. STOP and ask user before continuing

---

### Task 7: Integrate telemetry into AI chat flow

Wire up telemetry collection in the existing AI chat service.

- [ ] 7.1 Add telemetry to ResilientAiChatService
  - File: `lib/core/ai/chat/services/resilient_ai_chat_service.dart`
  - Call startRequest() at beginning
  - Call completeRequest() on success
  - Call recordError() on failure
  - _Requirements: All_

- [ ] 7.2 Add telemetry to context assembly
  - Measure context assembly time
  - Record in telemetry
  - _Requirements: 2.2_

- [ ] 7.3 Add telemetry to LLM calls
  - Measure LLM call time
  - Record token usage
  - Record cache hits/misses
  - _Requirements: 2.3, 3.1-3.2, 5.1-5.2_

- [ ] 7.4 Update dependency injection
  - File: `lib/core/di/bootstrap.dart`
  - Register telemetry services
  - Wire up dependencies
  - _Requirements: All_

- [ ] 7.5 Write integration tests
  - File: `test/integration/telemetry_integration_test.dart`
  - Send requests, verify metrics collected
  - Verify all metric types tracked
  - _Requirements: All_

---

## Checkpoint 7: Commit telemetry integration

**Actions Required:**
1. Mark tasks 7.1-7.5 as complete [x]
2. Commit: `git commit -m "feat(stage7b): Integrate telemetry into AI chat flow"`
3. STOP and ask user before continuing

---

### Task 8: Property-based tests

Write property tests for all 12 correctness properties.

- [ ] 8.1 Property 1: Request counting accuracy
  - File: `test/core/ai/chat/telemetry/properties/counting_properties_test.dart`
  - Generate random requests, verify count matches
  - **Feature: llm-stage-7b-telemetry-analytics, Property 1: Request counting accuracy**
  - **Validates: Requirements 1.1, 1.2, 1.3**

- [ ] 8.2 Property 2: Time window aggregation
  - Generate requests with timestamps, verify window counts
  - **Feature: llm-stage-7b-telemetry-analytics, Property 2: Time window aggregation**
  - **Validates: Requirements 1.1, 1.2, 1.3**

- [ ] 8.3 Property 3: Dimensional aggregation consistency
  - Generate requests with user/Space, verify sum equals total
  - **Feature: llm-stage-7b-telemetry-analytics, Property 3: Dimensional aggregation consistency**
  - **Validates: Requirements 1.4, 1.5, 3.3, 3.4, 5.4**

- [ ] 8.4 Property 4: Latency measurement completeness
  - File: `test/core/ai/chat/telemetry/properties/latency_properties_test.dart`
  - Verify context + LLM ≤ total latency
  - **Feature: llm-stage-7b-telemetry-analytics, Property 4: Latency measurement completeness**
  - **Validates: Requirements 2.1, 2.2, 2.3**

- [ ] 8.5 Property 5: Statistical calculation accuracy
  - Generate random latencies, verify average and median
  - **Feature: llm-stage-7b-telemetry-analytics, Property 5: Statistical calculation accuracy**
  - **Validates: Requirements 2.4**

- [ ] 8.6 Property 6: Token sum consistency
  - File: `test/core/ai/chat/telemetry/properties/token_properties_test.dart`
  - Verify total = prompt + completion
  - **Feature: llm-stage-7b-telemetry-analytics, Property 6: Token sum consistency**
  - **Validates: Requirements 3.1, 3.2**

- [ ] 8.7 Property 7: Error rate calculation
  - File: `test/core/ai/chat/telemetry/properties/error_properties_test.dart`
  - Verify error rate = (errors / total) * 100
  - **Feature: llm-stage-7b-telemetry-analytics, Property 7: Error rate calculation**
  - **Validates: Requirements 4.1**

- [ ] 8.8 Property 8: Error categorization completeness
  - Verify sum of errors by type = total errors
  - **Feature: llm-stage-7b-telemetry-analytics, Property 8: Error categorization completeness**
  - **Validates: Requirements 4.2, 4.3**

- [ ] 8.9 Property 9: Cache hit rate calculation
  - File: `test/core/ai/chat/telemetry/properties/cache_properties_test.dart`
  - Verify hit rate = (hits / total) * 100
  - Verify hits + misses = total
  - **Feature: llm-stage-7b-telemetry-analytics, Property 9: Cache hit rate calculation**
  - **Validates: Requirements 5.1, 5.2, 5.3**

- [ ] 8.10 Property 10: Alert threshold triggering
  - File: `test/core/ai/chat/telemetry/properties/alert_properties_test.dart`
  - Verify alerts trigger when threshold exceeded
  - Verify no alerts when below threshold
  - **Feature: llm-stage-7b-telemetry-analytics, Property 10: Alert threshold triggering**
  - **Validates: Requirements 8.1, 8.2, 8.3, 8.4**

- [ ] 8.11 Property 11: Metric collection timing
  - File: `test/core/ai/chat/telemetry/properties/performance_properties_test.dart`
  - Verify collection completes in < 10ms
  - Verify non-blocking behavior
  - **Feature: llm-stage-7b-telemetry-analytics, Property 11: Metric collection timing**
  - **Validates: Requirements 9.4**

- [ ] 8.12 Property 12: Privacy preservation
  - File: `test/core/ai/chat/telemetry/properties/privacy_properties_test.dart`
  - Verify no message content in metrics
  - Verify no PII in metrics
  - **Feature: llm-stage-7b-telemetry-analytics, Property 12: Privacy preservation**
  - **Validates: Requirements 10.1, 10.2, 10.3**

---

## Checkpoint 8: Commit property tests

**Actions Required:**
1. Mark tasks 8.1-8.12 as complete [x]
2. Commit: `git commit -m "test(stage7b): Add property-based tests for telemetry"`
3. STOP and ask user before continuing

---

### Task 9: Manual testing and documentation

Create manual test scenarios and documentation.

- [ ] 9.1 Create manual test scenarios document
  - File: `docs/modules/ai/STAGE_7B_MANUAL_TEST_SCENARIOS.md`
  - Document test scenarios for dashboard
  - Document alert testing
  - _Requirements: All_

- [ ] 9.2 Create Stage 7b documentation
  - File: `docs/modules/ai/STAGE_7B_TELEMETRY_ANALYTICS.md`
  - Document architecture
  - Document API endpoints
  - Document configuration
  - _Requirements: All_

- [ ] 9.3 Update LLM Stages Overview
  - File: `docs/modules/ai/LLM_STAGES_OVERVIEW.md`
  - Mark Stage 7b as complete
  - Add completion date and metrics
  - _Requirements: All_

---

## Checkpoint 9: Commit documentation

**Actions Required:**
1. Mark tasks 9.1-9.3 as complete [x]
2. Commit: `git commit -m "docs(stage7b): Add manual test scenarios and documentation"`
3. STOP and ask user before continuing

---

### Task 10: Final validation and cleanup

Ensure all tests pass and system is production-ready.

- [ ] 10.1 Run all unit tests
  - Verify all tests pass
  - Fix any failures
  - _Requirements: All_

- [ ] 10.2 Run all property tests
  - Verify all 12 properties pass
  - Fix any failures
  - _Requirements: All_

- [ ] 10.3 Run integration tests
  - Verify end-to-end telemetry works
  - Fix any issues
  - _Requirements: All_

- [ ] 10.4 Performance validation
  - Measure telemetry overhead (< 10ms)
  - Measure memory usage (< 50MB)
  - _Requirements: 9.1-9.5_

- [ ] 10.5 Manual dashboard testing
  - View real-time metrics
  - View historical trends
  - Trigger alerts
  - _Requirements: 6.1-6.5, 7.1-7.5, 8.1-8.5_

---

## Checkpoint 10: Final commit

**Actions Required:**
1. Mark tasks 10.1-10.5 as complete [x]
2. Commit: `git commit -m "feat(stage7b): Complete Stage 7b - Telemetry & Analytics"`
3. STOP and ask user before continuing

---

## Stage 7b Completion Criteria

Stage 7b is complete when:

- [ ] All 10 task groups completed (1-10)
- [ ] All 60+ subtasks completed
- [ ] All unit tests passing
- [ ] All 12 property-based tests passing
- [ ] All integration tests passing
- [ ] Performance requirements met (< 10ms overhead, < 50MB memory)
- [ ] Manual testing validates dashboard works correctly
- [ ] Manual testing validates alerts work correctly
- [ ] Documentation complete
- [ ] All changes committed to git

---

## Summary

**Total Tasks**: 60+ subtasks across 10 main task groups
**Estimated Time**: 3-4 days
**Key Deliverables**:
- Telemetry collection system
- Metrics aggregation service
- Alert monitoring service
- Dashboard API
- 12 property-based tests
- Complete documentation

**Next Stage**: Stage 7c (User Feedback & Quality) or Stage 7e (Privacy & Security)
