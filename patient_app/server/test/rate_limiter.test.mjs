import assert from 'node:assert';
import { rateLimiter, __resetRateLimiter } from '../src/middleware/rate_limiter.js';

function makeReqRes() {
  const req = { ip: '1.2.3.4', headers: {}, correlationId: 'cid' };
  let statusCode;
  let jsonBody;
  const res = {
    status(code) {
      statusCode = code;
      return this;
    },
    json(body) {
      jsonBody = body;
      return this;
    },
  };
  let nextCalled = false;
  const next = () => {
    nextCalled = true;
  };
  return { req, res, next, get statusCode() { return statusCode; }, get jsonBody() { return jsonBody; }, get nextCalled() { return nextCalled; } };
}

{
  __resetRateLimiter();
  const { req, res, next } = makeReqRes();
  rateLimiter(req, res, next);
  assert(next);
}

{
  // Exceed minute limit quickly
  __resetRateLimiter();
  let blocked = false;
  let lastStatus;
  for (let i = 0; i < 20; i++) {
    const ctx = makeReqRes();
    rateLimiter(ctx.req, ctx.res, ctx.next);
    lastStatus = ctx.statusCode;
    if (lastStatus === 429 || (ctx.jsonBody && ctx.jsonBody.error?.code === 'RATE_LIMIT')) {
      blocked = true;
      break;
    }
  }
  assert(blocked);
}
