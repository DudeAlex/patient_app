# Stage 7e Manual Test Notes (2025-12-05)

Use this as a checkpoint for continuing manual validation.

## What we changed today
- **Model config**: `server/src/llm/models.js` now loads model IDs from `server/config/models.json` (no JS defaults; validation added). `TOGETHER_MODEL` env override still works.
- **Env presets**: Added `server/config/env/{local,emulator,staging,prod}.env` plus npm scripts:
  - `npm run dev:local`
  - `npm run dev:emulator`
  - `npm run start:staging`
  - `npm run start:prod`
  - Uses `.env` first (for secrets), then overlays the preset via `DOTENV_CONFIG_PATH`.
- **Message length enforcement**: Server rejects messages > `MAX_MESSAGE_LENGTH` with `400/MESSAGE_TOO_LONG` on both `/api/v1/chat/echo` and `/api/v1/chat/message`. Default 10,000; for manual testing we temporarily set 100.
- **Tests**: Added `server/test/message_length.test.mjs` (over-limit 400, max-length 200). Test runner sets `NODE_ENV=test`.

## Current server state (end of day)
- Running preset: **emulator**
- Override: **MAX_MESSAGE_LENGTH=100** (for easy manual check)
- Base URL: `http://10.0.2.2:3030` from Android emulator (backend is on localhost:3030)
- HTTPS: relaxed in emulator preset (`HTTPS_ONLY=false`)
- Auth: per preset (emulator: `REQUIRE_AUTH=false`)
- Model: from `server/config/models.json` (Gemma by default) unless `TOGETHER_MODEL` set
- Key: pulled from `server/.env` (`TOGETHER_API_KEY`)

## Manual checks done/observed
- Length: Verified via curl — 150 chars → 400 `MESSAGE_TOO_LONG`; 100 chars → 200 OK. No MESSAGE_TOO_LONG yet observed in app UI (ensure app points to `http://10.0.2.2:3030`).
- Rate limit warnings: Backend only enforces hard 429; no 80/90% warnings implemented in middleware. Need 11th request within window to see 429.
- HTTPS enforcement: Works in staging preset with `x-forwarded-proto=https`; emulator preset skips HTTPS.

## How to resume quickly
1) If you want normal limits (10,000) and stricter security:
   - Stop server: `Stop-Process -Name node`
   - `cd server`
   - `npm run start:staging` (uses HTTPS_ONLY=true, REQUIRE_AUTH=true, MAX_MESSAGE_LENGTH=10000)
   - App Remote URL: `http://localhost:3030` (desktop/sim) or `http://10.0.2.2:3030` (emulator, but will need HTTPS header/proxy).
2) If you want to keep testing with 100-char limit and HTTP:
   - Server already running with `npm run dev:emulator` and `MAX_MESSAGE_LENGTH=100`.
   - App Remote URL: `http://10.0.2.2:3030`.
3) To switch presets fast: use npm scripts above; `.env` holds the Together key, presets override non-secret settings.

## Files touched today (key ones)
- `server/src/llm/models.js`, `server/config/models.json`
- `server/src/index.js`, `server/test/message_length.test.mjs`
- `server/config/env/*.env`, `server/package.json`
- `docs/modules/ai/STAGE_7E_MANUAL_TEST_SCENARIOS.md` (setup section, model note)

## Outstanding manual steps to redo/finish
- Rate limit hard limit: send 11 requests within 60s → expect 429 bubble.
- Validation/XSS/SQL: send `<script>alert(1)</script>` → expect 400.
- PII redaction: send PII and confirm logs/telemetry are redacted.
- Auth/RBAC: verify 401/403 paths.
- HTTPS enforcement: rerun with staging preset and `x-forwarded-proto=https` vs plain HTTP.
- Security monitoring events: check monitor/telemetry after rate limit or validation failures.

