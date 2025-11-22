# AI Integration Plan

## Overview
- **Universal Life Companion** is a local-first Flutter application that helps people manage Information Items across customizable Spaces such as Health, Finance, Education, Travel, and Family. Data lives in Isar, attachments reside on-device, and Google Drive backups keep everything safe.
- **AI vision for v1:** introduce a careful, opt-in assistant that can turn long-form Information Items into short, compassionate summaries so people can scan key details quickly without reading entire notes. Future versions can extend to other modalities, but v1 stays focused on this single outcome to keep scope tight and testable.

## Scope of AI v1
- **Primary capability:** “Summarize an Information Item into a short, user-friendly summary.”
- **Inputs**
  - InformationItem.id (for logging only, never sent off-device)
  - InformationItem.spaceId and space display name (to give domain context)
  - Title, category, and tags
  - Body/notes (raw text, already stored locally)
  - Attachment descriptors (type + filename, no binary data)
- **Outputs**
  - Summary text (<= 120 words, plain language, neutral-positive tone)
  - Optional action hints (bullet list of up to 3 items, each under 12 words)
  - Metadata: tokensUsed, providerName, latencyMs, confidenceScore (0-1)
  - Errors represented as structured failures with message + retryable flag

## Architecture Decisions
- **Service integration:** AI logic lives behind an `AiService` abstraction so UI and use cases never talk to vendors directly. Presentation layers ask a use case to “summarize item,” and the use case coordinates with `AiService` and persistence.
- **AiService interface (plain English)**
  - `Future<AiSummaryResult> summarizeItem(InformationItem item)`
  - `AiSummaryResult` contains: `summaryText`, `actionHints`, `tokensUsed`, `latencyMs`, `provider`, `confidence`, `error`.
- **Implementations**
  - `FakeAiService` – returns deterministic summaries for development and widget tests.
  - `LoggingAiService` – decorator that wraps any `AiService` and reports calls into the Diagnostic System (AppLogger + crash logs).
  - `HttpAiService` – talks to a backend proxy via HTTPS, handles JSON mapping and timeouts.
- **Layer placement**
  - **Domain/Application:** define use cases such as `SummarizeInformationItemUseCase` that depend on `AiService` ports.
  - **Adapters:** provide Riverpod providers/controllers that orchestrate UI state (loading, success, failure).
  - **Infrastructure:** host actual service implementations (`Fake`, `Logging`, `Http`) and configure them via DI (`AppContainer`, Riverpod providers).
- This design keeps AI optional, testable, and replaceable without touching UI widgets.

## Step by Step Implementation Plan

### Phase 0: Clarify AI Role
- [ ] Document the canonical prompt template and response contract for summarization.
- [ ] Record exactly which InformationItem fields leave the device (title, category, tags, notes, attachment descriptors) and which remain local (IDs, attachment binaries).
- [ ] Capture this in `AI_ASSISTED_LIFE_COMPANION_PLAN.md` + `SPEC.md` so consent copy stays accurate.

### Phase 1: Add AiService Abstraction (No Real AI Yet)
- [ ] Create `lib/core/ai/ai_service.dart` with the `AiService` interface and `AiSummaryResult` model (immutable, JSON-free).
- [ ] Add a dedicated use case in `lib/features/information_items/application/use_cases/summarize_information_item_use_case.dart` that depends only on `AiService`.
- [ ] Extend DI (`lib/core/di/app_container.dart` + Riverpod providers) to expose an `AiService` instance, defaulting to `FakeAiService` until real wiring lands.
- [ ] Update UI view models to call the use case and provide loading/error states; no visible AI button yet—can be behind debug toggle.

### Phase 2: Implement FakeAiService
- [ ] Add `lib/core/ai/fake_ai_service.dart` that composes summary text from the InformationItem title + first sentence of notes, plus mock action hints.
- [ ] Wire the fake service into DI for all environments initially; expose a developer setting to trigger summarization from an item detail screen.
- [ ] UI should surface: loading spinner, summary output, error banner (for simulated failures) so end-to-end flow can be exercised offline.
- [ ] Manual testing: open an Information Item, tap “Generate Summary (dev)”, observe the fake summary, toggle between success/error states via debug switch.

### Phase 3: Logging and Diagnostics
- [ ] Implement `LoggingAiService` in `lib/core/ai/logging_ai_service.dart` that wraps another `AiService` and emits AppLogger entries with operation name, timestamps, duration, and success/error metadata.
- [ ] Ensure logs include context `{ 'itemId': item.id, 'spaceId': item.spaceId, 'provider': providerName }` while redacting sensitive text.
- [ ] Extend Diagnostic System UI (planned screen) with an “AI Calls” section listing the last N summaries, durations, and outcomes sourced from log files or a lightweight Isar collection.
- [ ] Update `DIAGNOSTIC_SYSTEM_INTEGRATION.md` + `LOG_STRUCTURE_GUIDE.md` (placeholder) to document the new log schema.

### Phase 4: Backend Proxy and Real AI
- [ ] Define backend endpoint spec (e.g., `POST /ai/summarize`) with JSON request:
  ```json
  {
    "space": "health",
    "title": "Latest cardiology visit",
    "category": "Visit",
    "tags": ["cardiology", "bp"],
    "body": "...note text...",
    "attachments": [
      {"type": "pdf", "name": "lab_results.pdf"}
    ]
  }
  ```
  and response:
  ```json
  {
    "summary": "Short paragraph...",
    "actionHints": ["Schedule follow-up in 3 months"],
    "tokensUsed": 1250,
    "latencyMs": 1800,
    "provider": "together",
    "confidence": 0.82
  }
  ```
- [ ] Implement `HttpAiService` in `lib/core/ai/http_ai_service.dart` using `http` or `dio`, respecting timeouts, retries, exponential backoff, and mapping results to `AiSummaryResult`.
- [ ] Handle errors: network failure, 4xx from backend (invalid input), 5xx (provider failure). Map each to user-facing error states with retry guidance.
- [ ] Update DI to choose between Fake and Http versions based on config/feature flag.

### Phase 5: Quality Evaluation
- [ ] Build a small anonymized dataset of Information Items (10–15) covering multiple Spaces; store in `docs/ai/fixtures/` for manual QA.
- [ ] Create a test checklist: expected tone, length, correctness, action hints relevance.
- [ ] During manual runs, log actual AI responses, compare against expectations, and note issues in `TESTING.md` plus a dedicated `docs/ai/ai_quality_journal.md`.
- [ ] Use findings to tweak prompts, constraints, or fallback behavior before enabling production mode.

### Phase 6: Feature Flags and Deployment Strategy
- [ ] Introduce config toggles (`ai_enabled`, `ai_mode=fake|remote`) persisted via SharedPreferences or injected via Dart defines.
- [ ] UI should hide summary buttons when `ai_enabled=false`; show beta banners when enabled.
- [ ] CI builds: default to `ai_enabled=false`; release builds opt-in only after QA sign-off.
- [ ] Document rollout steps in `RELEASE_NOTES` (future) so QA and support know how to activate/deactivate AI.

## File and Folder Suggestions
- `docs/ai/ai_integration_plan.md` – this plan (new folder `docs/ai/` already created).
- `docs/ai/fixtures/` – optional sample data + QA notes.
- `lib/core/ai/ai_service.dart` – interface + models.
- `lib/core/ai/fake_ai_service.dart` – deterministic fake summaries.
- `lib/core/ai/logging_ai_service.dart` – diagnostic decorator.
- `lib/core/ai/http_ai_service.dart` – real HTTP-backed implementation.
- `lib/features/information_items/application/use_cases/summarize_information_item_use_case.dart` – orchestrates AI requests.
- `lib/features/information_items/ui/widgets/information_item_summary_sheet.dart` – UI component showing loading/success/error states.
- `lib/core/diagnostics/models/ai_call_log.dart` + `lib/core/diagnostics/services/ai_call_logger.dart` – optional structures for surfacing AI telemetry in diagnostics.

## Risks and Open Questions
- **Technical risks**
  - Prompt or response drift leading to incorrect summaries.
  - Latency spikes affecting perceived responsiveness.
  - Token overuse driving up costs if fields are not trimmed.
  - Privacy concerns if sensitive text leaks outside consent scope.
  - Ensuring deterministic behavior for tests when Fake and Logging layers are combined.
- **Product risks**
  - Users may misinterpret summaries as medical advice; messaging must stay compassionate yet cautious.
  - AI output might conflict with the user’s tone or culture; need localized review.
- **Open questions**
  - Which AI provider (Together, OpenAI, Anthropic) offers the right mix of privacy + cost?
  - Where will the backend proxy run, and how will it authenticate requests from the app?
  - What are the token/response size limits we can afford per Information Item?
  - How do we store AI responses for offline use while honoring deletion/consent requirements?
  - Should summaries be editable by the user, and if so, how do we track edits vs AI output?
