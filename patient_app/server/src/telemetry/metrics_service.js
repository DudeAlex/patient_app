// Lightweight, in-memory telemetry aggregation to make the dashboard endpoints
// return meaningful values without persisting data. Intentionally small and
// PII-free: we never store message text or user identifiers.

const MAX_EVENTS = 5_000; // cap memory
const ONE_MIN = 60 * 1000;
const ONE_HOUR = 60 * ONE_MIN;
const ONE_DAY = 24 * ONE_HOUR;

class TelemetryAggregation {
  constructor() {
    this.events = [];
  }

  recordSample({
    latencyMs = null,
    promptTokens = 0,
    completionTokens = 0,
    errorType = null,
    cacheHit = null,
    timestamp = new Date(),
  }) {
    this.events.push({
      timestamp: new Date(timestamp),
      latencyMs,
      promptTokens,
      completionTokens,
      errorType,
      cacheHit,
    });
    if (this.events.length > MAX_EVENTS) {
      this.events.splice(0, this.events.length - MAX_EVENTS);
    }
  }

  // Backwards-compatible helper used by existing tests.
  push(type, value) {
    if (type === 'latency') {
      this.recordSample({ latencyMs: value });
    } else if (type === 'tokens') {
      this.recordSample({ promptTokens: value });
    } else if (type === 'errors') {
      this.recordSample({ errorType: 'test_error' });
    } else {
      this.recordSample({});
    }
  }

  getCurrentSnapshot() {
    const now = Date.now();
    const perMinuteEvents = this.#since(now - ONE_MIN);
    const perHourEvents = this.#since(now - ONE_HOUR);
    const perDayEvents = this.#since(now - ONE_DAY);

    const latencyStats = this.#latencyStats(perHourEvents); // recent-ish window
    const tokenStats = this.#tokenStats(perHourEvents);
    const errorStats = this.#errorStats(perHourEvents);
    const cacheStats = this.#cacheStats(perHourEvents);

    return {
      requestRate: {
        perMinute: perMinuteEvents.length,
        perHour: perHourEvents.length,
        perDay: perDayEvents.length,
      },
      latency: latencyStats,
      tokenUsage: tokenStats,
      errorRate: errorStats,
      cacheHitRate: cacheStats.rate,
    };
  }

  getHistorical(type, start, end, aggregation = 'hourly') {
    const startDate = new Date(start);
    const endDate = new Date(end);
    const filtered = this.events.filter(
      (e) => e.timestamp >= startDate && e.timestamp <= endDate,
    );
    const bucketMs = aggregation === 'daily' ? ONE_DAY : ONE_HOUR;
    const buckets = new Map();

    for (const e of filtered) {
      const bucketKey = Math.floor(e.timestamp.getTime() / bucketMs) * bucketMs;
      if (!buckets.has(bucketKey)) {
        buckets.set(bucketKey, []);
      }
      buckets.get(bucketKey).push(e);
    }

    const dataPoints = [];
    for (const [bucketKey, events] of buckets.entries()) {
      if (events.length === 0) continue;
      const ts = new Date(bucketKey).toISOString();
      if (type === 'latency') {
        const stats = this.#latencyStats(events);
        dataPoints.push({ timestamp: ts, value: stats.average });
      } else if (type === 'tokens') {
        const stats = this.#tokenStats(events);
        dataPoints.push({ timestamp: ts, value: stats.total });
      } else if (type === 'errors') {
        const stats = this.#errorStats(events);
        dataPoints.push({ timestamp: ts, value: stats.total });
      } else if (type === 'requests') {
        dataPoints.push({ timestamp: ts, value: events.length });
      } else if (type === 'cache') {
        const stats = this.#cacheStats(events);
        dataPoints.push({ timestamp: ts, value: stats.rate });
      }
    }

    return dataPoints.sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));
  }

  #since(cutoffMs) {
    return this.events.filter((e) => e.timestamp.getTime() >= cutoffMs);
  }

  #latencyStats(events) {
    const latencies = events
      .map((e) => e.latencyMs)
      .filter((v) => typeof v === 'number' && v >= 0);
    if (!latencies.length) {
      return { average: 0, median: 0, p95: 0, p99: 0 };
    }
    latencies.sort((a, b) => a - b);
    const sum = latencies.reduce((a, b) => a + b, 0);
    const pct = (p) => latencies[Math.min(latencies.length - 1, Math.floor(p * latencies.length))];
    const median = pct(0.5);
    const p95 = pct(0.95);
    const p99 = pct(0.99);
    return {
      average: Math.round(sum / latencies.length),
      median,
      p95,
      p99,
    };
  }

  #tokenStats(events) {
    const prompt = events.reduce((acc, e) => acc + (e.promptTokens || 0), 0);
    const completion = events.reduce((acc, e) => acc + (e.completionTokens || 0), 0);
    return { total: prompt + completion, prompt, completion };
  }

  #errorStats(events) {
    const byType = {};
    let total = 0;
    for (const e of events) {
      if (!e.errorType) continue;
      total++;
      byType[e.errorType] = (byType[e.errorType] || 0) + 1;
    }
    return { total, byType };
  }

  #cacheStats(events) {
    let hits = 0;
    let attempts = 0;
    for (const e of events) {
      if (e.cacheHit === null || e.cacheHit === undefined) continue;
      attempts++;
      if (e.cacheHit) hits++;
    }
    const rate = attempts === 0 ? 0 : Math.round((hits / attempts) * 100);
    return { hits, attempts, rate };
  }
}

class TelemetryAlerts {
  constructor(aggregation) {
    this.aggregation = aggregation;
    this.alerts = [];
    this.thresholds = {
      latencyP95Ms: 5000,
      errorRatePct: 10, // of last hour window
    };
  }

  evaluateAndRecord() {
    const snapshot = this.aggregation.getCurrentSnapshot();
    const now = new Date().toISOString();
    const newAlerts = [];

    if (snapshot.latency.p95 > this.thresholds.latencyP95Ms) {
      newAlerts.push({
        alertId: 'latency-high',
        actualValue: snapshot.latency.p95,
        threshold: this.thresholds.latencyP95Ms,
        triggeredAt: now,
      });
    }

    const totalReq = snapshot.requestRate.perHour || 0;
    const errors = snapshot.errorRate.total || 0;
    const errorPct = totalReq === 0 ? 0 : Math.round((errors / totalReq) * 100);
    if (errorPct > this.thresholds.errorRatePct) {
      newAlerts.push({
        alertId: 'error-rate-high',
        actualValue: errorPct,
        threshold: this.thresholds.errorRatePct,
        triggeredAt: now,
      });
    }

    for (const alert of newAlerts) {
      this.alerts.push(alert);
      if (this.alerts.length > 200) {
        this.alerts.splice(0, this.alerts.length - 200);
      }
    }
  }

  getAlerts(since) {
    if (!since) return this.alerts;
    return this.alerts.filter((a) => new Date(a.triggeredAt) > since);
  }

  // Backwards-compatible helper used by existing tests.
  addAlert(alert) {
    this.alerts.push({
      ...alert,
      triggeredAt: alert.triggeredAt || new Date().toISOString(),
    });
  }
}

export { TelemetryAggregation, TelemetryAlerts };
