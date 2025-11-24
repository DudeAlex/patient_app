import dotenv from 'dotenv';
import crypto from 'crypto';
import express from 'express';
import morgan from 'morgan';
import { SYSTEM_PROMPT_TEMPLATE } from './llm/prompt_template.js';
import { formatHistory } from './llm/history_manager.js';
import { TogetherClient } from './llm/together_client.js';
import { rateLimiter } from './middleware/rate_limiter.js';

dotenv.config();

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

app.post('/api/v1/chat/message', async (req, res) => {
  const { message, history = [], maxTokens = 512 } = req.body ?? {};

  if (!message || typeof message !== 'string' || !message.trim()) {
    return res.status(400).json({
      error: {
        code: 'INVALID_REQUEST',
        message: 'message is required',
        correlationId: req.correlationId,
        retryable: false,
      },
    });
  }

  try {
    const formattedHistory = formatHistory(Array.isArray(history) ? history : []);
    const historyText =
      formattedHistory.length === 0
        ? 'None'
        : formattedHistory.map((m) => `${m.role}: ${m.content}`).join('\n');

    const systemPrompt = SYSTEM_PROMPT_TEMPLATE.replace('{history}', historyText).replace(
      '{user_message}',
      message,
    );

    const client = new TogetherClient();
    const response = await client.sendChat({
      messages: [
        { role: 'system', content: systemPrompt },
        ...formattedHistory,
        { role: 'user', content: message },
      ],
      correlationId: req.correlationId,
      maxTokens,
    });

    return res.json({
      message: response.message,
      metadata: {
        finishReason: response.finishReason,
        usage: response.usage,
        provider: response.provider,
        correlationId: response.correlationId,
      },
    });
  } catch (error) {
    const status = error.status || 502;
    return res.status(status).json({
      error: {
        code: error.code || 'LLM_ERROR',
        message: error.message || 'LLM request failed',
        correlationId: req.correlationId,
        retryable: error.retryable ?? false,
      },
    });
  }
});

// Apply rate limiting to chat endpoints
app.use(['/api/v1/chat/echo', '/api/v1/chat/message'], rateLimiter);

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
