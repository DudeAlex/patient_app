import { randomUUID } from 'crypto';

// Simple in-memory metric holders for demonstration.
class TelemetryAggregation {
  constructor() {
    this.snapshots = {
      requestRate: { perMinute: 0, perHour: 0, perDay: 0 },
      latency: { average: 0, median: 0, p95: 0, p99: 0 },
      tokenUsage: { total: 0, prompt: 0, completion: 0 },
      errorRate: { total: 0, byType: {} },
      cacheHitRate: 0,
    };
    this.historical = [];
  }

  getCurrentSnapshot() {
    return this.snapshots;
  }

  getHistorical(type, start, end, aggregation) {
    // For now return the stored list filtered by type and date
    const startDate = new Date(start);
    const endDate = new Date(end);
    return this.historical.filter(
      (p) => p.type === type && new Date(p.timestamp) >= startDate && new Date(p.timestamp) <= endDate,
    );
  }

  // Placeholder to push data (not wired to collectors yet)
  push(type, value) {
    this.historical.push({
      id: randomUUID(),
      type,
      value,
      timestamp: new Date().toISOString(),
    });
  }
}

class TelemetryAlerts {
  constructor(aggregation) {
    this.aggregation = aggregation;
    this.alerts = [];
  }

  getAlerts(since) {
    if (!since) return this.alerts;
    return this.alerts.filter((a) => new Date(a.triggeredAt) > since);
  }

  // Placeholder to add an alert
  addAlert(alert) {
    this.alerts.push({
      ...alert,
      triggeredAt: alert.triggeredAt || new Date().toISOString(),
    });
  }
}

export { TelemetryAggregation, TelemetryAlerts };
