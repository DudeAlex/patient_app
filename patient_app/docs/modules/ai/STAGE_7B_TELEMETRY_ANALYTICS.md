# Stage 7b: Telemetry & Analytics

## Overview
Stage 7b adds end-to-end telemetry for AI chat: request/latency/token tracking, error categorization, cache hit rates, alerts, and dashboard endpoints. The goal is near-real-time visibility (<10ms collection overhead, <50MB memory).

## Architecture
- **Emitters:** `TelemetryCollectorImpl` in the chat flow emits `start|complete|error` events with hashed userId, spaceId, messageId, latencies, tokens, cache flag.
- **Ingest:** `TelemetryIngestService` listens to collector events and writes to `MetricsStore` time-series buffers.
- **Storage:** `MetricsStore` uses circular `TimeSeriesBuffer`s per metric and enforces a 50MB budget (configurable).
- **Aggregation:** `MetricsAggregationServiceImpl` computes request rates, latency stats (avg/median/p95/p99/min/max), token usage (by user/space), error rates by type, cache hit rate, and historical slices.
- **Alerts:** `AlertMonitoringServiceImpl` evaluates thresholds (error rate, latency, token budget overage, request rate) with consecutive violation support.
- **Dashboard API (Node):** `/api/metrics/current`, `/api/metrics/historical`, `/api/metrics/alerts` with admin header auth and rate limiting.

## Data Flow
1. `ResilientAiChatService` calls `startRequest` at the beginning of sendMessage.
2. On completion, it records total/context/LLM latency, prompt/completion tokens, cache flag; on failure, `recordError` includes classified error type.
3. Ingest service persists points; aggregation/alerts consume buffers for dashboards and notifications.

## Metrics Tracked
- **Request Rate:** per-minute/hour/day counts.
- **Latency:** total, context assembly, LLM call; stats include avg/median/p95/p99/min/max.
- **Tokens:** prompt, completion, total; aggregates by user/space.
- **Errors:** counts and rates by type; total error rate.
- **Cache Hit Rate:** hits vs total; percent.
- **Alerts (defaults):** error rate >10%; latency >5s; token usage > (budget *1.2); request rate > capacity *1.5.

## Components & Locations
- Collector: `lib/core/ai/chat/telemetry/services/telemetry_collector_impl.dart`
- Ingest: `lib/core/ai/chat/telemetry/services/telemetry_ingest_service.dart`
- Store: `lib/core/ai/chat/telemetry/storage/metrics_store.dart`
- Aggregation: `lib/core/ai/chat/telemetry/services/metrics_aggregation_service_impl.dart`
- Alerts: `lib/core/ai/chat/telemetry/services/alert_monitoring_service_impl.dart`
- DI wiring: `lib/core/di/bootstrap.dart`
- Dashboard API: `server/src/telemetry/metrics_controller.js`

## Configuration
- **Memory budget:** `MetricsStore.totalMemoryBudgetBytes` (default 50MB); `bytesPerPointEstimate` (128B) and `maxDataPointsPerBuffer` control capacity.
- **Alert thresholds:** Constructor params on `AlertMonitoringServiceImpl` (request rate capacity/min, latency ms, token budget/day, error rate %).
- **Dashboard auth:** `ADMIN_TOKEN` env; rate limits 10/min, 100/hr, 500/day per IP (see `server/src/middleware/rate_limiter.js`).
- **Privacy:** User IDs hashed in collector; no message content recorded.

## Testing
- **Property tests:** `test/core/ai/chat/telemetry/properties/` (12 properties: request counting, windows, tokens, latency, errors, cache, alerts, performance, privacy).
- **Integration:** `test/integration/telemetry_integration_test.dart` validates end-to-end collection from chat flow.
- **API tests:** `server/test/telemetry/metrics_controller.test.js` cover endpoints/auth.

## Operational Notes
- Cleanup: `MetricsStore.cleanupAll()` trims expired points; buffers auto-trim on add.
- Investigations: Use `getHistoricalMetrics` for custom slices; alert list provides triggered thresholds.
- Performance: Collector emits on microtasks to avoid blocking; ingestion is in-memory only.
- Privacy: Verify payloads omit message content and raw identifiers; hashes are deterministic for aggregation only.
