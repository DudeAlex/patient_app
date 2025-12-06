# Stage 7e – Privacy & Security

## Overview
Stage 7e adds layered protections to AI chat: per-user rate limiting, PII redaction, strict input validation, HTTPS enforcement, token auth + admin RBAC, and security monitoring. The secure chat wrapper runs these checks before delegating to the underlying AI service, and all security events are tracked for telemetry.

## Components
- **SecureAiChatService**: Decorator enforcing auth, rate limits, validation/sanitization, and redacted logging before calling the primary AI service.
- **RateLimiterImpl**: Sliding-window in-memory limiter (10/min, 100/hr, 500/day) with soft/warning thresholds at 80/90%.
- **InputValidatorImpl**: Length + whitespace checks, control-char stripping, SQL/XSS/command injection detection, space ID validation, sanitization.
- **DataRedactionServiceImpl**: Regex-based PII redaction (names, emails, phones, SSNs, addresses) with custom pattern support.
- **AuthenticationServiceImpl**: HMAC-signed tokens with expiry and revocation list; roles carried in payload for RBAC.
- **SecurityMonitorImpl**: 24h in-memory event store with basic suspicious-activity detection and telemetry hook.
- **HTTPS Enforcer / Admin Middleware (Node)**: Rejects HTTP when HTTPS_ONLY, honors x-forwarded-proto, and restricts admin endpoints to admin role.

## Configuration
Environment variables (backend):
- `HTTPS_ONLY=true` (allow HTTP only in dev/test)
- `TOKEN_EXPIRY_HOURS=24`
- `RATE_LIMIT_PER_MINUTE=10`, `RATE_LIMIT_PER_HOUR=100`, `RATE_LIMIT_PER_DAY=500`
- `REQUIRE_AUTH=true`
- `MAX_MESSAGE_LENGTH=10000`

Flutter security defaults (bootstrap):
- Rate limits: 10/min, 100/hr, 500/day
- Token expiry: 24h
- Input max length: 10,000 chars

## How it works (chat request path)
1. **Auth**: Validate/generate token; reject expired or tampered tokens.
2. **Rate limit**: Check all windows; emit soft/warning signals at 80/90%; block with 429-style error.
3. **Validation**: Reject malformed/malicious input; sanitize whitespace/control characters.
4. **Redaction**: Log safe, redacted preview; keep PII out of logs.
5. **Monitoring**: Log security events (auth failure, rate limit, validation failure) for telemetry.
6. **Delegate**: Forward sanitized request to the resilient AI chat service.

## Testing
Automated:
- Unit: Rate limiter, redaction, validation, auth, security monitor.
- Integration: Secure chat wrapper covering rate limits, validation, auth expiry, redaction, event logging.
- Property-based (Stage 7e): rate limit enforcement/soft warnings, redaction completeness/patterns, data protection, validation rejection, HTTPS policy, token validation, admin RBAC, monitoring.

Manual (see `STAGE_7E_MANUAL_TEST_SCENARIOS.md`):
- Approach and exceed limits (warnings, 429 + retry-after).
- Send PII and confirm redaction in logs.
- Invalid input (script, SQL) rejected with clear 400.
- Expired/invalid token gets 401; admin-only endpoints blocked for non-admin.
- HTTP request rejected unless dev mode.
- Security events visible in monitor/telemetry.

## Rollout notes
- Deploy with `HTTPS_ONLY=true`, `REQUIRE_AUTH=true`; keep rate limits slightly higher initially, then tighten to targets.
- Monitor security event volume and suspicious activity flags after enabling.
- Keep redaction enabled in production; only disable for local debugging.
