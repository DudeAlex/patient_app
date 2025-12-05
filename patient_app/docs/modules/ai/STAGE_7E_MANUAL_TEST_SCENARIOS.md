# Stage 7e – Manual Test Scenarios

Use these to validate privacy & security behavior end-to-end.

## Rate limiting & warnings
- Send 8 requests within a minute; verify warning shown (~80%).
- Send 9th request; stronger warning (~90%).
- Send 11th request; expect 429 with retry-after and remaining quota.

## Input validation & sanitization
- Submit whitespace-only message; expect 400 with validation error.
- Submit `<script>alert(1)</script>`; expect rejection and logged validation failure event.
- Submit long (10,001 chars) message; expect 400.

## PII redaction
- Send message containing full name, email, phone, SSN, and address.
- Check logs/telemetry: no raw PII present; replaced with `[REDACTED]`.

## Authentication & RBAC
- Call chat without token; expect 401.
- Call with expired token; expect 401.
- Call admin endpoint with non-admin role; expect 403.
- Call admin endpoint with admin role; expect success.

## HTTPS enforcement
- Send HTTP request (no TLS, no `x-forwarded-proto=https`) in production mode; expect 403.
- In development mode (HTTPS_ONLY=false or NODE_ENV=development), HTTP is permitted.

## Security monitoring
- Trigger rate limit violation; verify security event recorded.
- Trigger validation failure; verify event recorded.
- Trigger repeated auth failures; monitor flags suspicious activity.

## On-device data protection
- Inspect outbound chat payloads to ensure no encryption keys or Information Item IDs are sent.
- Verify attachments omit local paths and binaries (metadata only).
