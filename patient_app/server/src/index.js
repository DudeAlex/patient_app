import dotenv from 'dotenv';
import crypto from 'crypto';
import express from 'express';
import morgan from 'morgan';
import { buildPrompt } from './llm/prompt_template.js';
import { formatHistory } from './llm/history_manager.js';
import { TogetherClient } from './llm/together_client.js';
import { rateLimiter } from './middleware/rate_limiter.js';
import { httpsEnforcer } from './security/https_enforcer.js';
import { PersonaManager } from './llm/persona_manager.js';
import { authenticationService } from './security/authentication_service.js';
import { dataRedactionService } from './security/data_redaction_service.js';
import { inputValidator } from './security/input_validator.js';

// Load base secrets from .env first, then overlay preset via DOTENV_CONFIG_PATH.
dotenv.config({ path: '.env' });
if (process.env.DOTENV_CONFIG_PATH) {
  dotenv.config({ path: process.env.DOTENV_CONFIG_PATH, override: true });
}

const app = express();
const port = process.env.PORT || 3030;

app.use(express.json());

// Enforce HTTPS unless explicitly disabled for development.
app.use(httpsEnforcer);

const MAX_MESSAGE_LENGTH = Number.parseInt(
  process.env.MAX_MESSAGE_LENGTH ?? '10000',
  10,
);

// Configure security services with env overrides now that dotenv has loaded.
authenticationService.configure({
  requireAuth: process.env.REQUIRE_AUTH === 'true',
});
inputValidator.setMaxLength(MAX_MESSAGE_LENGTH);
dataRedactionService.setEnabled(process.env.REDACTION_ENABLED !== 'false');

function validateInput(req, res, next) {
  const msg = req.body?.message;
  const validation = inputValidator.validateMessage(msg);

  if (!validation.isValid) {
    return res.status(400).json({
      error: {
        code: 'INVALID_REQUEST',
        message: validation.error,
        correlationId: req.correlationId,
        retryable: false,
      },
    });
  }

  // Sanitize input
  if (req.body && req.body.message) {
    req.body.message = inputValidator.sanitize(req.body.message);
  }

  next();
}

// Initialize PersonaManager
const personaManager = new PersonaManager();
await personaManager.loadPersonas();

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

// Apply rate limiting and authentication to chat endpoints
app.use(
  ['/api/v1/chat/echo', '/api/v1/chat/message'],
  [rateLimiter, authenticationService.middleware()],
);

app.post('/api/v1/chat/echo', validateInput, (req, res) => {
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
    message: `Echo: ${dataRedactionService.redact(message)}`,
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

app.post('/api/v1/chat/message', validateInput, async (req, res) => {
  const { message, history = [], maxTokens = 1000, spaceContext = {} } = req.body ?? {};

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

    const spaceId = spaceContext?.spaceId || 'general';
    await personaManager.ensureLatestPersonas();
    const persona = personaManager.getPersona(spaceId);
    console.info(
      JSON.stringify({
        event: 'persona_selected',
        correlationId: req.correlationId,
        spaceId,
        persona: persona?.name,
      }),
    );

    const systemPrompt = buildPrompt({
      spaceName: spaceContext?.spaceName,
      spaceDescription: spaceContext?.description,
      categories: Array.isArray(spaceContext?.categories) ? spaceContext.categories : [],
      recordSummaries: Array.isArray(spaceContext?.recentRecords)
        ? spaceContext.recentRecords
        : [],
      historyText,
      userMessage: message,
      contextStats: spaceContext?.stats || null,
      filters: spaceContext?.filters || null,
      persona,
    });

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
        latencyMs: response.latencyMs,
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

if (process.env.NODE_ENV !== 'test') {
  app.listen(port, () => {
    console.log(`Echo server listening on http://localhost:${port}`);
  });
}

export { app };
