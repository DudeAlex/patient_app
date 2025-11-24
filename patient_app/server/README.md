# Patient App Echo Server

Tiny Node.js + Express server that implements the Stage 1 echo endpoint for the AI chat HTTP foundation. No database or authentication.

## Setup
```bash
cd server
npm install
```

## Run
```bash
npm start
# or with auto-reload:
npm run dev
```

Environment
- `TOGETHER_API_KEY`: API key for Together AI (required for Stage 2 LLM calls)
- `TOGETHER_MODEL`: Optional override for chat model id (default: see model catalog)
- `LLM_TIMEOUT_MS`: Optional request timeout in milliseconds (default: 60000)

Server defaults to `http://localhost:3030`.

## Endpoint
- `POST /api/v1/chat/echo`
  - Headers: `Content-Type: application/json`, optional `X-Correlation-ID`
  - Body:
    ```json
    {
      "threadId": "thread_123",
      "message": "Hello, AI!",
      "timestamp": "2025-11-24T10:00:00Z",
      "userId": "user_456"
    }
    ```
  - Success response (200):
    ```json
    {
      "responseId": "uuid",
      "threadId": "thread_123",
      "message": "Echo: Hello, AI!",
      "timestamp": "2025-11-24T10:00:01Z",
      "metadata": {
        "processingTimeMs": 5,
        "stage": "echo",
        "llmProvider": "none",
        "tokenUsage": {"prompt":0,"completion":0,"total":0},
        "correlationId": "uuid",
        "userId": "user_456",
        "requestTimestamp": "2025-11-24T10:00:00Z"
      }
    }
    ```
  - Error response (400) if `threadId` or `message` missing:
    ```json
    {
      "error": {
        "code": "INVALID_REQUEST",
        "message": "threadId and message are required",
        "correlationId": "uuid",
        "retryable": false
      }
    }
    ```

## Notes
- Logs as JSON via `morgan`, including correlation IDs and response times.
- No tests are defined yet (`npm test` will warn about a missing script).

Stage 2 LLM foundation
- `src/llm/together_client.js` implements a thin Together AI chat client with 60s timeout, correlation IDs, and error classification (auth/429/server/timeout).
- `src/llm/errors.js` defines structured errors used by the client.
- `src/llm/prompt_template.js` provides the base system prompt (v1.0) with placeholders for history and user message.
- `src/llm/history_manager.js` formats conversation history (last 3 turns, role/content pairs) for prompts.
- `src/llm/models.js` catalogs default model ids (chat friendly google/gemma-3n-E4B-it, reasoning Apriel-1.5-15B-Thinker, fallback openai/gpt-oss-20b, image Apriel) and resolves chat model with optional env override.
- `scripts/ping_model.mjs` probes a model with a short prompt (uses .env key). Gemma may be unsupported on Together; Apriel and gpt-oss-20b succeed.
- `src/llm/token_counter.js` estimates token usage for system prompt, history, and user message using tiktoken with model fallback.
- `src/middleware/rate_limiter.js` applies in-memory rate limiting (10/min, 100/hr, 500/day) to chat endpoints.

Stage 2 LLM chat endpoint
- `POST /api/v1/chat/message` accepts `{ message: string, history?: [{role, content}], maxTokens?: number }`.
- Builds system prompt from `prompt_template`, formats last 3 history messages, and calls Together via `TogetherClient`.
- Returns `{ message, metadata: { finishReason, usage, provider, correlationId } }` or structured error with `code`, `retryable`, `correlationId`.
