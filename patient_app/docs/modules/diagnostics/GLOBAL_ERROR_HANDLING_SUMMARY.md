Status: ACTIVE

# Global Error Handling Summary

## Principles
- Centralize error capture; log with context; surface friendly UI; avoid leaking sensitive data.

## Patterns
- Wrap async operations with try/catch -> `AppLogger.error('message', error: e, stackTrace: st, context: {...})`; rethrow if needed.
- Use domain/application errors where possible; adapters translate to user-facing failures.
- Provide SnackBars/dialogs with actionable hints; keep copy concise.
- For performance-critical blocks, track via `startOperation/endOperation`.

## UI Guidance
- Do not block with fatal dialogs unless necessary; allow retry paths.
- Include minimal context for support (operation, ids) without PII.

## Testing
- Add tests for failure paths (network/auth/storage); assert logging occurred and UI response is correct.
- Simulate error responses in adapters/use cases to ensure mapping to presentation-layer messages.
