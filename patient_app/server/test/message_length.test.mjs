import test from 'node:test';
import request from 'supertest';
import { app } from '../src/index.js';

test('rejects messages longer than MAX_MESSAGE_LENGTH', async () => {
  const longMessage = 'a'.repeat(10001);
  const res = await request(app)
    .post('/api/v1/chat/echo')
    .set('x-forwarded-proto', 'https')
    .send({ threadId: 't1', message: longMessage });

  if (res.status !== 400) {
    throw new Error(`Expected 400, got ${res.status}`);
  }
  if (res.body?.error?.code !== 'MESSAGE_TOO_LONG') {
    throw new Error(`Unexpected error code: ${res.body?.error?.code}`);
  }
});

test('accepts messages at max length', async () => {
  const maxMessage = 'a'.repeat(10000);
  const res = await request(app)
    .post('/api/v1/chat/echo')
    .set('x-forwarded-proto', 'https')
    .send({ threadId: 't1', message: maxMessage });

  if (res.status !== 200) {
    throw new Error(`Expected 200, got ${res.status}`);
  }
});
