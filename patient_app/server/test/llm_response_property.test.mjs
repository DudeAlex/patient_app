import assert from 'node:assert';
import request from 'supertest';

process.env.NODE_ENV = 'test';

// Stub TogetherClient to return a minimal non-empty response with usage.
const { TogetherClient } = await import('../src/llm/together_client.js');
TogetherClient.prototype.sendChat = async ({ messages, correlationId, maxTokens }) => {
  return {
    message: `Stubbed response for: ${messages.at(-1).content}`,
    finishReason: 'stop',
    usage: { total_tokens: 42 },
    provider: 'stub',
    correlationId,
    latencyMs: 5,
  };
};

const { app } = await import('../src/index.js');

const randomMessages = Array.from({ length: 5 }, (_, i) => `msg-${i}-${Math.random().toString(16).slice(2, 6)}`);

for (const msg of randomMessages) {
  const res = await request(app)
    .post('/api/v1/chat/message')
    .send({
      message: msg,
      history: [],
      maxTokens: 64,
    })
    .set('Content-Type', 'application/json');

  assert.strictEqual(res.statusCode, 200);
  assert.ok(res.body.message && res.body.message.length > 0);
  assert.ok(res.body.metadata?.usage);
}
