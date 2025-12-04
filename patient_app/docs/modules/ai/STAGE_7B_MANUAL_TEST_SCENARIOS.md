# Stage 7b: Telemetry & Analytics Manual Test Scenarios

## Overview
This guide lists manual scenarios to validate the Stage 7b telemetry stack end-to-end: collection in the chat flow, aggregation, alerts, and the dashboard API.

**Manual validation status (dev):** Completed. Real-time, historical, alerts, cache/tokens/errors, and privacy toggle verified as described below.

## How to Test
1. Ensure dashboard API is running with `ADMIN_TOKEN` set.
2. Use an admin token header (`X-Admin-Token`) for all calls.
3. Generate traffic via the app or targeted scripts to exercise specific metrics.
4. Validate responses against expected values and note any anomalies.

## Success Criteria
- Real-time metrics reflect recent traffic within seconds.
- Historical queries return points for the requested window.
- Alerts trigger only when thresholds are exceeded for the configured duration.
- No PII or message content appears in telemetry payloads.
- Cache hit/miss, token, latency, and error rates sum correctly.

## Current Validation Status (dev env)
- Real-time snapshot: ✅ `/api/metrics/current` showing recent traffic (perMinute/perHour counts, latency averages, token totals).
- Historical window: ✅ `/api/metrics/historical` returns hourly bucket with latency averages for today's traffic.
- Alerts: ✅ Triggered via `/api/metrics/simulate` (latency-high, error-rate-high).
- Privacy: ✅ Dashboard stores aggregates only; app chat message/response logging is gated by `DEBUG_AI_LOGS` (off in prod/release).
- Cache/tokens/errors sum: ✅ Cache hit rate 100% after simulation; errors counted; token totals populated.

## Quick commands (dev)
- Start server: `cd server && set ADMIN_TOKEN=qwerty && npm run dev`
- Live snapshot: `curl -H "X-Admin-Token: qwerty" http://localhost:3030/api/metrics/current`
- Historical latency:  
  `curl -H "X-Admin-Token: qwerty" "http://localhost:3030/api/metrics/historical?type=latency&start=<ISO-start>&end=<ISO-end>&aggregation=hourly"`
- Alerts: `curl -H "X-Admin-Token: qwerty" http://localhost:3030/api/metrics/alerts`
- Simulate traffic (for manual checks only):  
  `curl -H "X-Admin-Token: qwerty" -H "Content-Type: application/json" -d '{"count":3,"latencyMs":6000,"errorType":"timeout","promptTokens":50,"completionTokens":10,"cacheHit":true}' http://localhost:3030/api/metrics/simulate`

## Privacy reminder
- Dashboard API stores only aggregates. App chat logs now gate message/response text behind `DEBUG_AI_LOGS`; leave it unset in prod/PII-sensitive runs, enable only for local debugging.

---

## Scenarios

### 1) Real-Time Snapshot
**Objective:** Verify `/api/metrics/current` shows live rates.  
**Steps:**  
1. Send 5 chat requests within a minute.  
2. GET `/api/metrics/current` with admin token.  
**Expected:** `requestRate.perMinute` ≈ 5; latency fields non-zero; tokenUsage totals > 0.

### 2) Historical Window
**Objective:** Validate historical range query.  
**Steps:**  
1. Generate traffic over 10 minutes.  
2. GET `/api/metrics/historical?type=latency&start=<t-15m>&end=<now>&aggregation=hourly`.  
**Expected:** Returned `dataPoints` include timestamps within range; values > 0; no gaps exceeding aggregation window when traffic exists.

### 3) Alert: Error Rate Spike
**Objective:** Ensure alerts trigger on high error rate.  
**Steps:**  
1. Force 5 failing requests out of 10 (simulate network/server errors).  
2. Wait 30s for alert evaluation.  
3. GET `/api/metrics/alerts`.  
**Expected:** Alert with `alertId` similar to `error-rate-high`; `actualValue` > 10%; message notes threshold.

### 4) Alert: Latency Threshold
**Objective:** Validate latency alerting.  
**Steps:**  
1. Inject artificial delay >5s in chat responses (or simulate via test harness).  
2. Wait for evaluator run.  
3. GET `/api/metrics/alerts`.  
**Expected:** `latency-high` alert with threshold ≈ 5000ms.

### 5) Token Budget Overage
**Objective:** Confirm token usage alerting.  
**Steps:**  
1. Send large-context prompts to exceed daily token budget +20%.  
2. Query alerts.  
**Expected:** `token-budget-overage` alert fires; token totals in historical view align with usage.

### 6) Cache Hit Rate
**Objective:** Verify cache hit/miss accounting.  
**Steps:**  
1. Issue identical prompts twice with cache enabled.  
2. GET `/api/metrics/current`.  
**Expected:** Cache hit rate > 0 on second call; total hits + misses equals total attempts.

### 7) Rate Limiting & Auth
**Objective:** Ensure admin auth and rate limiting are enforced.  
**Steps:**  
1. Call dashboard endpoints without `X-Admin-Token`.  
2. Call endpoints rapidly (>10/min) with token.  
**Expected:** Unauthorized without token; 429 responses when limits exceeded.

### 8) Privacy Validation
**Objective:** Confirm no message content/PII in telemetry.  
**Steps:**  
1. Inspect emitted telemetry events or logs.  
2. Verify payloads contain anonymized userId hashes and omit message text.  
**Expected:** No raw user identifiers or message content present.

---

## Notes
- Record anomalies with timestamps and request IDs to cross-check in metrics store.
- If alerts misfire, capture current metric snapshots and thresholds for debugging.
- Dashboard API is in-memory only (no persistence). Send fresh chat traffic to see non-zero metrics; alerts fire on latency p95 >5s or error rate >10% over recent traffic.
