import test from 'node:test';
import assert from 'node:assert';
import express from 'express';
import request from 'supertest';
import { httpsEnforcer } from '../../src/security/https_enforcer.js';

test('allows https requests', async () => {
  const app = express();
  app.use(httpsEnforcer);
  app.get('/ok', (req, res) => res.json({ ok: true }));

  const res = await request(app).get('/ok').set('X-Forwarded-Proto', 'https');
  assert.strictEqual(res.status, 200);
  assert.deepStrictEqual(res.body, { ok: true });
});

test('rejects http when HTTPS_ONLY true', async () => {
  const app = express();
  process.env.HTTPS_ONLY = 'true';
  process.env.NODE_ENV = 'production';
  app.use(httpsEnforcer);
  app.get('/ok', (req, res) => res.json({ ok: true }));

  const res = await request(app).get('/ok');
  assert.strictEqual(res.status, 403);
});

test('allows http in development', async () => {
  const app = express();
  process.env.HTTPS_ONLY = 'true';
  process.env.NODE_ENV = 'development';
  app.use(httpsEnforcer);
  app.get('/ok', (req, res) => res.json({ ok: true }));

  const res = await request(app).get('/ok');
  assert.strictEqual(res.status, 200);
});

test('allows http when HTTPS_ONLY is false', async () => {
  const app = express();
  process.env.HTTPS_ONLY = 'false';
  process.env.NODE_ENV = 'production';
  app.use(httpsEnforcer);
  app.get('/ok', (req, res) => res.json({ ok: true }));

  const res = await request(app).get('/ok');
  assert.strictEqual(res.status, 200);
});
