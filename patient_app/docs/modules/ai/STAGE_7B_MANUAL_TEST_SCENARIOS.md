# Stage 7b: Telemetry & Analytics Manual Test Scenarios

## Overview
This guide lists manual scenarios to validate the Stage 7b telemetry stack end-to-end: collection in the chat flow, aggregation, alerts, and the dashboard API.

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
