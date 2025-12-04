import test from 'node:test';
import assert from 'node:assert';
import express from 'express';
import request from 'supertest';
import { requireAdmin } from '../../src/security/admin_middleware.js';

test('allows admin role', async () => {
  const app = express();
  app.use((req, res, next) => {
    req.user = { roles: ['admin'] };
    next();
  });
  app.use(requireAdmin);
  app.get('/admin', (req, res) => res.json({ ok: true }));

  const res = await request(app).get('/admin');
  assert.strictEqual(res.status, 200);
});

test('rejects non-admin', async () => {
  const app = express();
  app.use((req, res, next) => {
    req.user = { roles: ['user'] };
    next();
  });
  app.use(requireAdmin);
  app.get('/admin', (req, res) => res.json({ ok: true }));

  const res = await request(app).get('/admin');
  assert.strictEqual(res.status, 403);
});
