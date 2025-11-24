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
- `TOGETHER_MODEL`: Optional override for model id (default: Meta Llama 3 Turbo)
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
- The HTTP endpoint for LLM chat will be added in a later task; the client is ready for integration.
