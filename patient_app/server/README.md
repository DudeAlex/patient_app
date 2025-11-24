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
