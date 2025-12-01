Status: ACTIVE

# AI Integration Plan

## Goal (v1)
- Opt-in assistant to summarize Information Items into short, compassionate summaries.

## Inputs / Outputs
- Inputs: item id (logging only), space id/name, title, category, tags, body text, attachment descriptors (type+filename, no binaries).
- Outputs: summary ≤120 words; up to 3 action hints (≤12 words); metadata (tokensUsed, provider, latencyMs, confidence, error/retryable).

## Architecture
- `AiService` port: `summarizeItem(item) -> AiSummaryResult`.
- Implementations: `FakeAiService` (deterministic), `LoggingAiService` (decorator to AppLogger), `HttpAiService` (backend proxy).
- Layers: use cases depend on `AiService`; adapters/presenters handle UI state; infrastructure wires concrete services via DI (`AppContainer`/Riverpod).
- Design keeps AI optional, replaceable, and testable.

## Phases
- Phase 0: align on AI role (summary-only v1; future modalities later).
- Phase 1: define port + DTOs; build Fake + Logging implementations; add use case + tests.
- Phase 2: add Http proxy client with timeouts/retries, JSON mapping, error handling; wire DI switch.
- Phase 3: UX polish (consent prompts, loading/success/failure states, action hints), analytics logging.
- Phase 4: expand modes (photo/scan/voice/email), retrieval grounding, structured extraction once core is stable.

## Safety & Privacy
- Opt-in toggle with consent banners; keep original data local.
- Send minimal payload; no IDs/binaries off-device; secure API keys/proxy; redact logs.
- Structured errors with retryable flag; queue offline work for future phases.
