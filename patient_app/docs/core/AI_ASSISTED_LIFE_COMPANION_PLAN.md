Status: ACTIVE

# AI-Assisted Life Companion Plan

## Goals
- Optional AI that organizes, summarizes, and encourages across all spaces.
- Default local-only; all outbound processing is consent-gated and transparent.

## Principles
- Privacy first: originals saved locally; redact/limit payloads; secure key handling.
- Explainability: confidence, action hints, citations; compassionate tone.
- Opt-in toggles with clear banners; offline queueing with retries.

## Capabilities (staged)
- Input processing: OCR/STT/image understanding to structured suggestions.
- Organization/discovery: tags, relationships, search boosting, context-aware prompts.
- Insights/reflection: trends, reminders, proactive follow-ups.
- Adaptive UI: persona selection, context-aware help, voice-first copilot.

## Integration Plan
- Service: `AiProcessingService` behind consent + feature flag; supports fake provider + remote placeholder.
- Payload discipline: send space/category/title/tags/notes/attachment descriptors (no IDs/binaries).
- Queue: local Isar tasks survive restarts/backups; retries with backoff; failures keep originals.
- Toggle: `AiProcessingMode` localOnly vs aiAssisted; settings UI handles consent and persistence.
- Logging: AppLogger with redaction; no sensitive content; operation timing.

## Roadmap Highlights
- Short term: summaries v1 (�120 words, up to 3 action hints), AI consent toggle, fake provider default.
- Mid term: Together AI text/image provider, structured extraction, wellness companion, voice-first copilot.
- Future: personas (coach/tutor/advisor), retrieval grounding, compassionate notifications, localization.

## Safety & UX
- Consent prompts per first use; banners when sending to AI.
- Offline behavior: queue and inform; manual paths always available.
- Escalation: safety hints, encourage contacting professionals; avoid panic.
