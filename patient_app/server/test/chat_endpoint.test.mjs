import assert from 'node:assert';
import request from 'supertest';

process.env.NODE_ENV = 'test';

const { TogetherClient } = await import('../src/llm/together_client.js');
TogetherClient.prototype.sendChat = async ({ messages, correlationId, maxTokens }) => {
  return {
    message: `Echo: ${messages.at(-1).content}`,
    finishReason: 'stop',
    usage: { total_tokens: 10 },
    provider: 'stub',
    correlationId,
    latencyMs: 5,
  };
};

const { app } = await import('../src/index.js');

const res = await request(app)
  .post('/api/v1/chat/message')
  .send({
    message: 'Hello integration',
    history: [
      { role: 'user', content: 'Hi' },
      { role: 'assistant', content: 'Hey!' },
    ],
    maxTokens: 64,
  })
  .set('Content-Type', 'application/json');

assert.strictEqual(res.statusCode, 200);
assert.strictEqual(res.body.message, 'Echo: Hello integration');
assert.strictEqual(res.body.metadata.provider, 'stub');
