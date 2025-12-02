import test from 'node:test';
import assert from 'node:assert';
import request from 'supertest';

process.env.NODE_ENV = 'test';
process.env.ADMIN_TOKEN = 'admin';

const { app } = await import('../../src/index.js');
const { aggregation, alerts } = await import('../../src/telemetry/metrics_controller.js');

test('GET /api/metrics/current returns snapshot', async () => {
  const res = await request(app).get('/api/metrics/current').set('X-Admin-Token', 'admin');
  assert.strictEqual(res.status, 200);
  assert.ok(res.body.requestRate);
});

test('GET /api/metrics/historical requires params', async () => {
  const res = await request(app).get('/api/metrics/historical').set('X-Admin-Token', 'admin');
  assert.strictEqual(res.status, 400);
});

test('GET /api/metrics/historical returns data', async () => {
  aggregation.push('latency', 123);
  const start = new Date(Date.now() - 1000).toISOString();
  const end = new Date(Date.now() + 1000).toISOString();

  const res = await request(app)
    .get('/api/metrics/historical')
    .set('X-Admin-Token', 'admin')
    .query({ type: 'latency', start, end, aggregation: 'hourly' });
  assert.strictEqual(res.status, 200);
  assert.ok(Array.isArray(res.body.dataPoints));
});

test('GET /api/metrics/alerts returns alerts', async () => {
  alerts.addAlert({ alertId: 'test', metric: 'latency', actualValue: 10, threshold: 5, message: 'Test' });
  const res = await request(app).get('/api/metrics/alerts').set('X-Admin-Token', 'admin');
  assert.strictEqual(res.status, 200);
  assert.ok(Array.isArray(res.body.alerts));
});
