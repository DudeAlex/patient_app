Status: ACTIVE

# AI Quality Journal

Use this log to capture observations when running manual AI summarization tests. Update entries after each QA pass so everyone can track how the AI behaves over time.

## Entry Template

```
## YYYY-MM-DD — QA Run #
- **Environment**: (device/emulator, mode: Fake/Remote, app build)
- **Fixtures Tested**: (IDs from docs/ai/fixtures/information_items.json)
- **Observations**:
  - Item X: expected…, actual…, issues?
  - …
- **Action Items**:
  - (Prompt adjustments, bug tickets, etc.)
```

## Tips
- Reference `docs/ai/fixtures/information_items.json` to ensure broad space coverage.
- Note both positives (when AI performed well) and negatives (hallucinations, wrong tone, etc.).
- Keep PHI out of this file; fixtures are anonymized, and so should your notes be.

## 2025-11-21 — QA Run 1
- **Environment**: Android emulator (Pixel, debug build), AI mode Fake → Remote
- **Fixtures Tested**: #1 Cardiology follow-up (health, tags: cardiology, bp)
- **Observations**:
  - Fake mode: summary generated without errors; loading → success flow worked as expected.
  - Remote mode: failed with `AiServiceException` (Network failure contacting AI provider; retryable=true) because the remote provider/backend is not wired up yet.
- **Action Items**:
  - Keep using Fake mode for local QA until the remote AI backend is available.
  - Once the backend is online, rerun Remote mode on the same fixture to validate end-to-end behavior and logging.

