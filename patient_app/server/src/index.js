import crypto from 'crypto';
import express from 'express';
import morgan from 'morgan';

const app = express();
const port = process.env.PORT || 3030;

app.use(express.json());

// Structured logging with correlation id support.
app.use((req, res, next) => {
  const correlationId = req.header('X-Correlation-ID') || crypto.randomUUID();
  req.correlationId = correlationId;
  res.setHeader('X-Correlation-ID', correlationId);
  next();
});

app.use(
  morgan((tokens, req, res) => {
    const context = {
      correlationId: req.correlationId,
      method: tokens.method(req, res),
      url: tokens.url(req, res),
      status: tokens.status(req, res),
      responseTimeMs: tokens['response-time'](req, res),
      contentLength: tokens.res(req, res, 'content-length'),
    };
    return JSON.stringify(context);
  }),
);

app.post('/api/v1/chat/echo', (req, res) => {
  const { threadId, message, timestamp, userId } = req.body ?? {};

  if (!threadId || !message) {
    return res.status(400).json({
      error: {
        code: 'INVALID_REQUEST',
        message: 'threadId and message are required',
        correlationId: req.correlationId,
        retryable: false,
      },
    });
  }

  const responsePayload = {
    responseId: crypto.randomUUID(),
    threadId,
    message: `Echo: ${message}`,
    timestamp: new Date().toISOString(),
    metadata: {
      processingTimeMs: 5,
      stage: 'echo',
      llmProvider: 'none',
      tokenUsage: {
        prompt: 0,
        completion: 0,
        total: 0,
      },
      correlationId: req.correlationId,
      userId: userId ?? null,
      requestTimestamp: timestamp ?? null,
    },
  };

  return res.json(responsePayload);
});

app.use((req, res) => {
  res.status(404).json({
    error: {
      code: 'NOT_FOUND',
      message: 'Endpoint not found',
      correlationId: req.correlationId,
      retryable: false,
    },
  });
});

app.listen(port, () => {
  console.log(`Echo server listening on http://localhost:${port}`);
});
