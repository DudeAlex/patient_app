# Design Document

## Overview

Stage 7b implements a comprehensive telemetry and analytics system for the AI Chat Companion. The system collects, aggregates, and visualizes key performance metrics to enable monitoring, optimization, and cost management. The design emphasizes minimal performance impact, privacy protection, and real-time visibility into system health.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     AI Chat System                          │
│  ┌──────────────┐      ┌──────────────┐                    │
│  │   Flutter    │      │   Backend    │                    │
│  │    Client    │◄────►│    Server    │                    │
│  └──────┬───────┘      └──────┬───────┘                    │
│         │                     │                             │
│         │                     │                             │
│         ▼                     ▼                             │
│  ┌──────────────────────────────────────┐                  │
│  │      Telemetry Collection Layer      │                  │
│  │  - Request interceptors              │                  │
│  │  - Metric collectors                 │                  │
│  │  - Async event emitters              │                  │
│  └──────────────┬───────────────────────┘                  │
│                 │                                           │
│                 ▼                                           │
│  ┌──────────────────────────────────────┐                  │
│  │      Metrics Aggregation Service     │                  │
│  │  - Time-series data                  │                  │
│  │  - Statistical calculations          │                  │
│  │  - Trend analysis                    │                  │
│  └──────────────┬───────────────────────┘                  │
│                 │                                           │
│                 ▼                                           │
│  ┌──────────────────────────────────────┐                  │
│  │       Metrics Storage (In-Memory)    │                  │
│  │  - Rolling time windows              │                  │
│  │  - Efficient data structures         │                  │
│  │  - Automatic cleanup                 │                  │
│  └──────────────┬───────────────────────┘                  │
│                 │                                           │
│                 ▼                                           │
│  ┌──────────────────────────────────────┐                  │
│  │      Alert Monitoring Service        │                  │
│  │  - Threshold checking                │                  │
│  │  - Alert triggering                  │                  │
│  │  - Notification dispatch             │                  │
│  └──────────────┬───────────────────────┘                  │
│                 │                                           │
│                 ▼                                           │
│  ┌──────────────────────────────────────┐                  │
│  │      Dashboard API / UI              │                  │
│  │  - Real-time metrics endpoint        │                  │
│  │  - Historical data queries           │                  │
│  │  - Visualization components          │                  │
│  └──────────────────────────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

### Component Interaction Flow

1. **Request Interception**: Every AI chat request is intercepted by telemetry collectors
2. **Metric Collection**: Key metrics (latency, tokens, errors) are collected asynchronously
3. **Aggregation**: Metrics are aggregated into time-series data (per minute, hour, day)
4. **Storage**: Aggregated metrics are stored in memory with rolling windows
5. **Alert Monitoring**: Thresholds are checked continuously, alerts triggered when exceeded
6. **Dashboard**: Real-time and historical metrics are exposed via API and displayed in UI

## Components and Interfaces

### 1. Telemetry Collector

**Purpose**: Intercept requests and collect raw metrics

**Interface**:
```dart
abstract class TelemetryCollector {
  /// Start tracking a request
  String startRequest({
    required String userId,
    required String spaceId,
    required String messageId,
  });
  
  /// Record request completion
  Future<void> completeRequest({
    required String requestId,
    required Duration totalLatency,
    required Duration contextAssemblyTime,
    required Duration llmCallTime,
    required int promptTokens,
    required int completionTokens,
    bool fromCache = false,
  });
  
  /// Record request error
  Future<void> recordError({
    required String requestId,
    required String errorType,
    required String errorMessage,
  });
}
```

**Implementation**: `TelemetryCollectorImpl`
- Generates unique request IDs
- Timestamps all events
- Emits metric events asynchronously
- Never blocks the main request flow

### 2. Metrics Aggregation Service

**Purpose**: Aggregate raw metrics into time-series data

**Interface**:
```dart
abstract class MetricsAggregationService {
  /// Get current request rate (requests per minute)
  int getCurrentRequestRate();
  
  /// Get average response latency
  Duration getAverageLatency({TimeWindow window = TimeWindow.hour});
  
  /// Get token usage statistics
  TokenUsageStats getTokenUsage({TimeWindow window = TimeWindow.day});
  
  /// Get error rate by type
  Map<String, double> getErrorRates({TimeWindow window = TimeWindow.hour});
  
  /// Get cache hit rate
  double getCacheHitRate({TimeWindow window = TimeWindow.hour});
  
  /// Get historical metrics
  List<MetricDataPoint> getHistoricalMetrics({
    required MetricType type,
    required DateTime startTime,
    required DateTime endTime,
    Aggregation aggregation = Aggregation.hourly,
  });
}
```

**Implementation**: `MetricsAggregationServiceImpl`
- Maintains rolling time windows (1 min, 1 hour, 1 day, 30 days)
- Calculates statistics (average, median, p95, p99)
- Aggregates by user, Space, error type
- Automatically prunes old data

### 3. Metrics Storage

**Purpose**: Store time-series metrics efficiently in memory

**Data Structures**:
```dart
class MetricDataPoint {
  final DateTime timestamp;
  final double value;
  final Map<String, dynamic> metadata;
}

class TimeSeriesBuffer {
  final Duration windowSize;
  final int maxDataPoints;
  final List<MetricDataPoint> _buffer;
  
  void add(MetricDataPoint point);
  List<MetricDataPoint> getRange(DateTime start, DateTime end);
  void cleanup(); // Remove old data
}

class MetricsStore {
  // Request rate: per minute, hour, day
  final TimeSeriesBuffer requestsPerMinute;
  final TimeSeriesBuffer requestsPerHour;
  final TimeSeriesBuffer requestsPerDay;
  
  // Latency: total, context, LLM
  final TimeSeriesBuffer totalLatency;
  final TimeSeriesBuffer contextLatency;
  final TimeSeriesBuffer llmLatency;
  
  // Token usage
  final TimeSeriesBuffer promptTokens;
  final TimeSeriesBuffer completionTokens;
  
  // Errors by type
  final Map<String, TimeSeriesBuffer> errorsByType;
  
  // Cache hits
  final TimeSeriesBuffer cacheHits;
  final TimeSeriesBuffer cacheMisses;
}
```

**Memory Management**:
- Maximum 50MB total memory usage
- Rolling windows: 1 hour (1-min resolution), 7 days (1-hour resolution), 30 days (1-day resolution)
- Automatic cleanup of data older than retention period
- Efficient circular buffers to avoid memory fragmentation

### 4. Alert Monitoring Service

**Purpose**: Monitor metrics and trigger alerts when thresholds are exceeded

**Interface**:
```dart
abstract class AlertMonitoringService {
  /// Register an alert threshold
  void registerAlert({
    required String alertId,
    required MetricType metric,
    required AlertCondition condition,
    required double threshold,
    required AlertHandler handler,
  });
  
  /// Check all alerts (called periodically)
  Future<void> checkAlerts();
  
  /// Get triggered alerts
  List<Alert> getTriggeredAlerts({DateTime? since});
}

class AlertCondition {
  final ComparisonOperator operator; // >, <, >=, <=, ==
  final Duration evaluationWindow;
  final int consecutiveViolations; // Trigger after N consecutive violations
}

class Alert {
  final String alertId;
  final DateTime triggeredAt;
  final MetricType metric;
  final double actualValue;
  final double threshold;
  final String message;
}
```

**Implementation**: `AlertMonitoringServiceImpl`
- Checks alerts every 30 seconds
- Requires consecutive violations to avoid false positives
- Logs all triggered alerts
- Supports multiple alert handlers (log, email, webhook)

### 5. Dashboard API

**Purpose**: Expose metrics via REST API for dashboard UI

**Endpoints**:
```
GET /api/metrics/current
Response: {
  requestRate: { perMinute: 45, perHour: 2500, perDay: 50000 },
  latency: { average: 1.2, median: 0.9, p95: 2.5, p99: 4.1 },
  tokenUsage: { total: 125000, prompt: 75000, completion: 50000 },
  errorRate: { total: 0.02, byType: { network: 0.01, timeout: 0.005, ... } },
  cacheHitRate: 0.35
}

GET /api/metrics/historical?type=latency&start=2024-12-01&end=2024-12-02&aggregation=hourly
Response: {
  dataPoints: [
    { timestamp: "2024-12-01T00:00:00Z", value: 1.1 },
    { timestamp: "2024-12-01T01:00:00Z", value: 1.3 },
    ...
  ]
}

GET /api/metrics/alerts
Response: {
  alerts: [
    { alertId: "error-rate-high", triggeredAt: "2024-12-01T14:30:00Z", ... },
    ...
  ]
}
```

### 6. Dashboard UI (Optional - Backend Focus)

**Purpose**: Visualize metrics in real-time

**Components**:
- Real-time metric cards (request rate, latency, tokens, errors)
- Time-series charts (line charts for trends)
- Alert notifications panel
- Filters (date range, user, Space)

**Technology**: Simple HTML/JS dashboard served by backend (or Flutter admin screen)

## Data Models

### MetricType Enum
```dart
enum MetricType {
  requestRate,
  totalLatency,
  contextLatency,
  llmLatency,
  promptTokens,
  completionTokens,
  totalTokens,
  errorRate,
  cacheHitRate,
}
```

### TimeWindow Enum
```dart
enum TimeWindow {
  minute,  // Last 60 seconds
  hour,    // Last 60 minutes
  day,     // Last 24 hours
  week,    // Last 7 days
  month,   // Last 30 days
}
```

### TokenUsageStats
```dart
class TokenUsageStats {
  final int totalTokens;
  final int promptTokens;
  final int completionTokens;
  final Map<String, int> byUser;
  final Map<String, int> bySpace;
  final double averagePerRequest;
}
```

### LatencyStats
```dart
class LatencyStats {
  final Duration average;
  final Duration median;
  final Duration p95;
  final Duration p99;
  final Duration min;
  final Duration max;
}
```

### ErrorStats
```dart
class ErrorStats {
  final double totalErrorRate;
  final Map<String, double> errorRateByType;
  final Map<String, int> errorCountByType;
  final int totalErrors;
  final int totalRequests;
}
```

## Correct
ness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

Before defining correctness properties, let me analyze each acceptance criterion for testability:

### Acceptance Criteria Testing Prework:

**1.1** THE System SHALL track the number of AI chat requests per minute
Thoughts: This is about tracking a count over time. We can generate random requests, track them, and verify the count matches.
Testable: yes - property

**1.2** THE System SHALL track the number of AI chat requests per hour
Thoughts: Similar to 1.1, but different time window. Can be tested with the same approach.
Testable: yes - property

**1.3** THE System SHALL track the number of AI chat requests per day
Thoughts: Similar to 1.1 and 1.2, different time window.
Testable: yes - property

**1.4** THE System SHALL track request rates per user to identify heavy users
Thoughts: This is about aggregating by user. We can generate requests from different users and verify counts per user.
Testable: yes - property

**1.5** THE System SHALL track request rates per Space to identify popular domains
Thoughts: Similar to 1.4, but aggregating by Space instead of user.
Testable: yes - property

**2.1** THE System SHALL measure total response time from request to completion
Thoughts: This is about measuring duration. We can generate requests, measure time, and verify it's recorded.
Testable: yes - property

**2.2** THE System SHALL measure context assembly time separately
Thoughts: Similar to 2.1, but for a specific phase.
Testable: yes - property

**2.3** THE System SHALL measure LLM API call time separately
Thoughts: Similar to 2.1 and 2.2, for another specific phase.
Testable: yes - property

**2.4** THE System SHALL calculate average, median, and 95th percentile latencies
Thoughts: This is about statistical calculations. We can generate random latencies and verify the calculations are correct.
Testable: yes - property

**2.5** THE System SHALL track latency trends over time (hourly, daily)
Thoughts: This is about time-series aggregation. We can generate data points over time and verify aggregation.
Testable: yes - property

**3.1** THE System SHALL track total tokens used per request (prompt + completion)
Thoughts: This is about summing two values. We can generate random token counts and verify the sum.
Testable: yes - property

**3.2** THE System SHALL track prompt tokens and completion tokens separately
Thoughts: This is about tracking two separate values. We can verify both are recorded correctly.
Testable: yes - property

**3.3** THE System SHALL calculate token usage per user per day
Thoughts: This is about aggregating tokens by user and day. We can generate requests and verify aggregation.
Testable: yes - property

**3.4** THE System SHALL calculate token usage per Space per day
Thoughts: Similar to 3.3, but aggregating by Space.
Testable: yes - property

**3.5** THE System SHALL track token usage trends over time to identify cost patterns
Thoughts: This is about time-series tracking. Similar to 2.5.
Testable: yes - property

**4.1** THE System SHALL track error rate as percentage of total requests
Thoughts: This is about calculating a percentage. We can generate requests with some errors and verify the calculation.
Testable: yes - property

**4.2** THE System SHALL categorize errors by type (network, timeout, rate-limit, server, validation)
Thoughts: This is about classification. We can generate different error types and verify they're categorized correctly.
Testable: yes - property

**4.3** THE System SHALL track error rates per error type separately
Thoughts: This is about aggregating by error type. We can verify counts per type.
Testable: yes - property

**4.4** THE System SHALL track error trends over time (hourly, daily)
Thoughts: Time-series tracking for errors. Similar to 2.5 and 3.5.
Testable: yes - property

**4.5** THE System SHALL identify error spikes (sudden increases above baseline)
Thoughts: This is about detecting anomalies. We can generate normal data then a spike and verify detection.
Testable: yes - property

**5.1** THE System SHALL track the number of requests served from cache
Thoughts: This is about counting cache hits. We can generate requests with cache flags and verify counts.
Testable: yes - property

**5.2** THE System SHALL track the number of requests requiring LLM calls
Thoughts: This is about counting cache misses. Complement of 5.1.
Testable: yes - property

**5.3** THE System SHALL calculate cache hit rate as percentage of total requests
Thoughts: This is about calculating a percentage. Similar to 4.1.
Testable: yes - property

**5.4** THE System SHALL track cache hit rates per Space
Thoughts: This is about aggregating by Space. Similar to 1.5.
Testable: yes - property

**5.5** THE System SHALL track cache hit rate trends over time
Thoughts: Time-series tracking for cache hits. Similar to other trend tracking.
Testable: yes - property

**6.1-6.5** Dashboard requirements
Thoughts: These are about UI display, not computational properties.
Testable: no

**7.1-7.5** Historical data requirements
Thoughts: These are about data retention and querying, which are implementation details.
Testable: yes - example (specific retention periods)

**8.1-8.5** Alert threshold requirements
Thoughts: These are about triggering alerts based on conditions. We can test the trigger logic.
Testable: yes - property

**9.1-9.5** Performance impact requirements
Thoughts: These are about performance characteristics. Some are testable (async, timing), others are harder (memory limits).
Testable: yes - property (for timing), edge-case (for memory limits)

**10.1-10.5** Privacy and security requirements
Thoughts: These are about what should NOT be included in metrics. We can test for absence of sensitive data.
Testable: yes - property

### Property Reflection:

After reviewing all properties, I notice several can be combined:
- Properties about tracking different time windows (1.1, 1.2, 1.3) can be combined into one property about time window tracking
- Properties about measuring different latency phases (2.1, 2.2, 2.3) can be combined into one property about latency measurement
- Properties about tracking trends (2.5, 3.5, 4.4, 5.5) can be combined into one property about time-series aggregation
- Properties about aggregating by dimension (1.4, 1.5, 3.3, 3.4, 5.4) can be combined into one property about dimensional aggregation

### Correctness Properties:

**Property 1: Request counting accuracy**
*For any* sequence of requests, the total count of tracked requests should equal the number of requests generated.
**Validates: Requirements 1.1, 1.2, 1.3**

**Property 2: Time window aggregation**
*For any* time window (minute, hour, day), the count of requests in that window should equal the number of requests with timestamps within that window.
**Validates: Requirements 1.1, 1.2, 1.3**

**Property 3: Dimensional aggregation consistency**
*For any* dimension (user, Space), the sum of counts across all dimension values should equal the total count.
**Validates: Requirements 1.4, 1.5, 3.3, 3.4, 5.4**

**Property 4: Latency measurement completeness**
*For any* request, the sum of context assembly time and LLM call time should be less than or equal to total response time.
**Validates: Requirements 2.1, 2.2, 2.3**

**Property 5: Statistical calculation accuracy**
*For any* set of latency values, the calculated average should equal the sum divided by count, and the median should be the middle value when sorted.
**Validates: Requirements 2.4**

**Property 6: Token sum consistency**
*For any* request, total tokens should equal prompt tokens plus completion tokens.
**Validates: Requirements 3.1, 3.2**

**Property 7: Error rate calculation**
*For any* set of requests with some errors, the error rate should equal (error count / total count) * 100.
**Validates: Requirements 4.1**

**Property 8: Error categorization completeness**
*For any* error, it should be categorized into exactly one error type, and the sum of errors across all types should equal total errors.
**Validates: Requirements 4.2, 4.3**

**Property 9: Cache hit rate calculation**
*For any* set of requests, cache hit rate should equal (cache hits / total requests) * 100, and cache hits + cache misses should equal total requests.
**Validates: Requirements 5.1, 5.2, 5.3**

**Property 10: Alert threshold triggering**
*For any* metric value that exceeds a threshold, an alert should be triggered, and for any value below the threshold, no alert should be triggered.
**Validates: Requirements 8.1, 8.2, 8.3, 8.4**

**Property 11: Metric collection timing**
*For any* request, metric collection should complete in less than 10ms and should not block the request.
**Validates: Requirements 9.4**

**Property 12: Privacy preservation**
*For any* collected metric, it should not contain user message content, PII, or unencrypted sensitive data.
**Validates: Requirements 10.1, 10.2, 10.3**

## Error Handling

### Metric Collection Failures

**Strategy**: Graceful degradation - never fail requests due to telemetry issues

**Scenarios**:
1. **Storage Full**: Stop collecting new metrics, log warning, continue serving requests
2. **Aggregation Error**: Skip aggregation for that cycle, retry next cycle
3. **Alert Check Failure**: Log error, continue monitoring
4. **Dashboard API Error**: Return cached data or error response, don't crash

**Implementation**:
- Wrap all telemetry operations in try-catch
- Use circuit breaker pattern for repeated failures
- Log all telemetry errors separately from application errors
- Provide health check endpoint for telemetry system

### Data Consistency

**Challenges**:
- Concurrent metric updates from multiple requests
- Time synchronization across distributed components
- Data loss during system restarts

**Solutions**:
- Use atomic operations for counters
- Use synchronized clocks (NTP)
- Accept eventual consistency for non-critical metrics
- Persist critical metrics to disk periodically (optional)

## Testing Strategy

### Unit Testing

**Focus**: Individual components and calculations

**Test Cases**:
- TelemetryCollector: Request ID generation, event emission
- MetricsAggregationService: Statistical calculations (average, median, percentiles)
- TimeSeriesBuffer: Data insertion, retrieval, cleanup
- AlertMonitoringService: Threshold checking, alert triggering
- Dashboard API: Endpoint responses, data formatting

**Tools**: Dart test framework, mockito for mocking

### Property-Based Testing

**Focus**: Universal properties that should hold across all inputs

**Properties to Test**:
1. Request counting accuracy (Property 1)
2. Time window aggregation (Property 2)
3. Dimensional aggregation consistency (Property 3)
4. Latency measurement completeness (Property 4)
5. Statistical calculation accuracy (Property 5)
6. Token sum consistency (Property 6)
7. Error rate calculation (Property 7)
8. Error categorization completeness (Property 8)
9. Cache hit rate calculation (Property 9)
10. Alert threshold triggering (Property 10)
11. Metric collection timing (Property 11)
12. Privacy preservation (Property 12)

**Tools**: 
- Dart: `test` package with custom generators
- JavaScript (backend): `fast-check` library

**Configuration**:
- Minimum 100 iterations per property test
- Each test tagged with: `**Feature: llm-stage-7b-telemetry-analytics, Property {number}: {property_text}**`

### Integration Testing

**Focus**: End-to-end metric collection and aggregation

**Test Scenarios**:
1. Send 100 requests, verify all metrics are collected
2. Simulate errors, verify error rates are calculated correctly
3. Simulate cache hits/misses, verify cache hit rate
4. Trigger alert thresholds, verify alerts are generated
5. Query dashboard API, verify data is returned correctly

### Performance Testing

**Focus**: Verify minimal performance impact

**Test Scenarios**:
1. Measure request latency with and without telemetry (should be < 10ms difference)
2. Measure memory usage over time (should stay under 50MB)
3. Measure CPU usage during metric collection (should be < 5%)
4. Stress test with 1000 requests/second

### Manual Testing

**Focus**: Dashboard UI and alert notifications

**Test Scenarios**:
1. View real-time metrics on dashboard
2. View historical trends
3. Trigger alerts by exceeding thresholds
4. Verify privacy (no PII in metrics)

## Performance Considerations

### Optimization Strategies

1. **Asynchronous Collection**: All metric collection happens asynchronously
2. **Batching**: Batch metric writes to reduce I/O
3. **Sampling**: For very high request rates, sample metrics (e.g., 10% of requests)
4. **Efficient Data Structures**: Use circular buffers, avoid frequent allocations
5. **Lazy Aggregation**: Calculate aggregates on-demand, not on every metric update

### Memory Management

**Target**: Maximum 50MB for all metrics storage

**Breakdown**:
- Request rate buffers: 10MB (1 hour at 1-min resolution)
- Latency buffers: 10MB (1 hour at 1-min resolution)
- Token usage buffers: 10MB (1 day at 1-hour resolution)
- Error buffers: 10MB (1 day at 1-hour resolution)
- Cache hit buffers: 5MB (1 day at 1-hour resolution)
- Alert state: 5MB

**Cleanup Strategy**:
- Automatic cleanup every 5 minutes
- Remove data older than retention period
- Compress historical data (hourly → daily aggregates)

### Scalability

**Current Design**: Single-server, in-memory storage

**Future Enhancements** (if needed):
- Distributed metrics collection (multiple servers)
- External time-series database (InfluxDB, Prometheus)
- Metrics aggregation service (separate from API server)

## Security Considerations

### Access Control

- Dashboard API requires authentication
- Admin-only access to metrics endpoints
- Rate limiting on dashboard API (prevent abuse)

### Data Privacy

- No user message content in metrics
- Anonymized user IDs (hashed)
- No PII in logs or metrics
- Encrypted metrics data at rest (if persisted)

### Audit Trail

- Log all dashboard access
- Log all alert triggers
- Log all configuration changes

## Deployment Considerations

### Configuration

**Environment Variables**:
```
TELEMETRY_ENABLED=true
TELEMETRY_RETENTION_DAYS=30
TELEMETRY_MEMORY_LIMIT_MB=50
TELEMETRY_ALERT_CHECK_INTERVAL_SECONDS=30
TELEMETRY_DASHBOARD_PORT=3001
```

### Monitoring the Monitor

**Health Checks**:
- Telemetry system health endpoint: `/api/telemetry/health`
- Metrics: collection rate, storage usage, alert check latency
- Alerts: Telemetry system down, storage full, alert check failing

### Rollout Strategy

1. Deploy telemetry collection (disabled by default)
2. Enable collection for 10% of requests (canary)
3. Monitor performance impact
4. Gradually increase to 100%
5. Enable dashboard and alerts

## Future Enhancements

### Phase 2 (Optional)

- Persistent storage (database or time-series DB)
- Advanced analytics (anomaly detection, forecasting)
- Custom dashboards (user-defined metrics)
- Export metrics (CSV, JSON)
- Integration with external monitoring tools (Grafana, Datadog)

### Phase 3 (Optional)

- Distributed tracing (OpenTelemetry)
- Real-time alerting (email, Slack, PagerDuty)
- Cost optimization recommendations
- A/B testing support (compare metrics across variants)

---

## References

- **Requirements:** `.kiro/specs/llm-stage-7b-telemetry-analytics/requirements.md`
- **LLM Stages Overview:** `docs/modules/ai/LLM_STAGES_OVERVIEW.md`
- **Stage 7a Design:** `.kiro/specs/llm-stage-7a-personas-error-recovery/design.md`
- **Property-Based Testing Guide:** [fast-check documentation](https://github.com/dubzzz/fast-check)
