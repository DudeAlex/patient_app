# Stage 7e – Manual Test Scenarios

Use these to validate privacy & security behavior end-to-end. Run with production-like settings (`HTTPS_ONLY=true`, `REQUIRE_AUTH=true`) unless a scenario calls out dev mode.

## Environment setup (manual tester quickstart)
- **Flutter prep (root):**
  - `flutter clean`
  - `flutter pub get`
- **Backend prep (server/):**
  - Install deps if needed: `npm install`
  - Set env (PowerShell example):
    ```
    cd server
    $env:PORT="3030"
    $env:HTTPS_ONLY="true"          # set false or NODE_ENV=development to allow plain HTTP from emulator
    $env:REQUIRE_AUTH="true"
    $env:TOKEN_EXPIRY_HOURS="24"
    $env:RATE_LIMIT_PER_MINUTE="10"
    $env:RATE_LIMIT_PER_HOUR="100"
    $env:RATE_LIMIT_PER_DAY="500"
    $env:MAX_MESSAGE_LENGTH="10000"
    $env:REDACTION_ENABLED="true"
    $env:TOGETHER_API_KEY="<your-key>"
    $env:TOGETHER_MODEL="<your-model-id>"  # e.g., mistralai/Mixtral-8x7B-Instruct or another provider/model you use
    $env:LLM_TIMEOUT_MS="60000"
    # For emulator traffic use:
    # $env:NODE_ENV="development"    # lets HTTP through; flip to "production" for HTTPS-only test
    npm run dev
    ```
- **Emulator/device:**
  - Android: `flutter emulators` → `flutter emulators --launch <id>`; use backend URL `http://10.0.2.2:3030`.
  - iOS sim/desktop/web: backend URL `http://localhost:3030`.
- **App run (root):**
  - `flutter run -d <device>`
  - In-app AI settings: enable AI, switch mode to Remote, set Remote URL per above.

## Rate limiting & warnings
- **RL-1 Minute window + warnings:** Send 8 requests within 60s; expect soft warning (~80%). Send 9th; expect stronger warning (~90%). Send 11th; expect 429 with `retry-after` and remaining quota in response/UI.
- **RL-2 Hour/day windows:** Drive usage to 90/hour then 101st in the same hour → 429; repeat for 500/day → 429. Confirm counters reset at UTC midnight (simulate time advance or verify next day).

## Input validation & sanitization
- **IV-1 Empty/whitespace:** Submit whitespace-only; expect 400 with validation error and trimmed/sanitized echo in logs (no raw whitespace-only payload).
- **IV-2 Injection blocking:** Submit `<script>alert(1)</script>`; expect 400, validation failure logged/telemetry tagged `validation_failed`, no script content in downstream payloads.
- **IV-3 Length limit:** Submit 10,001-char body; expect 400 stating max length 10,000. Retry with exactly 10,000 chars; expect success.

## PII redaction
- **PR-1 Redaction in logs:** Send message containing full name, email, phone, SSN, and street address. Inspect logs/telemetry: all PII replaced with `[REDACTED]`; no raw values present. Ensure chat response does not echo raw PII.
- **PR-2 Custom pattern:** Add a custom redaction regex (e.g., medical record number) and resend; confirm the new pattern is redacted in logs/telemetry.

## Authentication & RBAC
- **AU-1 Missing/expired/tampered:** Call chat without token → 401; with expired token → 401; with tampered signature → 401. Verify `auth_failed` security events recorded.
- **AU-2 Admin-only:** Call admin endpoint with non-admin role → 403. Call with admin role → success. Verify role is logged but no PII/token material is persisted.

## HTTPS enforcement
- **HP-1 Prod HTTPS only:** With `HTTPS_ONLY=true`, send plain HTTP (no TLS, no `x-forwarded-proto=https`) → 403. Repeat with `x-forwarded-proto=https` → allowed.
- **HP-2 Dev override:** Set `HTTPS_ONLY=false` or `NODE_ENV=development`; send HTTP → request is allowed.

## Security monitoring
- **SM-1 Rate limit event:** Trigger 429; verify security monitor recorded `rate_limit_exceeded` and forwarded to telemetry.
- **SM-2 Validation event:** Trigger validation failure (IV-2); verify `validation_failed` event with redacted payload preview only.
- **SM-3 Suspicious activity:** Send 5+ consecutive auth failures from the same user/IP; confirm suspicious flag raised and emitted to telemetry.

## On-device data protection
- **DP-1 Payload contents:** Inspect outbound chat payloads; confirm no encryption keys or Information Item IDs are sent—only anonymized summaries and attachment metadata.
- **DP-2 Attachments:** Send attachment; verify only descriptor/metadata leaves device (no local path or binary) and logs contain redacted metadata only.
