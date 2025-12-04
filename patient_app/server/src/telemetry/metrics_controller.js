import express from 'express';
import { TelemetryAggregation } from './metrics_service.js';
import { TelemetryAlerts } from './metrics_service.js';
import { rateLimiter } from '../middleware/rate_limiter.js';

const metricsRouter = express.Router();

// In-memory telemetry services (placeholder; swap with DI if added)
const aggregation = new TelemetryAggregation();
const alerts = new TelemetryAlerts(aggregation);

// Basic admin auth middleware using header token. Extend/replace with real auth provider when available.
metricsRouter.use((req, res, next) => {
  const adminToken = process.env.ADMIN_TOKEN || 'admin';
  const provided = req.header('X-Admin-Token');
  if (provided !== adminToken) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
});

// Apply rate limiting to metrics endpoints
metricsRouter.use(rateLimiter);

// GET /api/metrics/current
metricsRouter.get('/current', (req, res) => {
  const data = aggregation.getCurrentSnapshot();
  res.json(data);
});

// GET /api/metrics/historical?type=latency&start=2024-12-01&end=2024-12-02&aggregation=hourly
metricsRouter.get('/historical', (req, res) => {
  const { type, start, end, aggregation: agg = 'hourly' } = req.query;
  if (!type || !start || !end) {
    return res.status(400).json({ error: 'type, start, and end are required' });
  }
  const data = aggregation.getHistorical(type, start, end, agg);
  res.json({ dataPoints: data });
});

// GET /api/metrics/alerts
metricsRouter.get('/alerts', (req, res) => {
  const since = req.query.since ? new Date(req.query.since) : null;
  const data = alerts.getAlerts(since);
  res.json({ alerts: data });
});

// POST /api/metrics/simulate
// Helper endpoint for manual testing: injects synthetic samples (no PII).
metricsRouter.post('/simulate', (req, res) => {
  const {
    count = 1,
    latencyMs = 100,
    promptTokens = 0,
    completionTokens = 0,
    errorType = null,
    cacheHit = null,
  } = req.body ?? {};

  const samples = Math.max(1, Math.min(Number(count) || 1, 1000));
  for (let i = 0; i < samples; i++) {
    aggregation.recordSample({
      latencyMs,
      promptTokens,
      completionTokens,
      errorType,
      cacheHit,
    });
  }
  alerts.evaluateAndRecord();
  res.json({ added: samples });
});

export { metricsRouter, aggregation, alerts };
