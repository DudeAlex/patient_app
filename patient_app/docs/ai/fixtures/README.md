# AI Fixtures

Use these anonymized Information Item samples to validate AI summarization quality (Task 13 in `.kiro/specs/ai-summarization/tasks.md`).

## Files
- `information_items.json` – 10 items spanning Health, Finance, Education, Travel, Family, Business, Creative, and Home spaces. Each entry lists:
  - `title`, `spaceId`, `domainId`, `tags`, `notes`, `attachments`
  - `expectedSummary` – what the AI should highlight
  - `expectedTone` – the writing style QA should look for

## How to Use
1. Load the JSON into tooling or copy a sample into the app via Add Record (adjust type/tags as needed).
2. Enable AI features + consent in Settings, open the corresponding record detail, and request a summary.
3. Compare AI output to the `expectedSummary`/`expectedTone` hints; note observations in `docs/ai/ai_quality_journal.md` once it is created (Task 14).
4. Repeat across multiple Spaces to ensure coverage before turning on remote mode.

These fixtures should remain PHI-free and may be extended as new domains are added. When you add more, keep the same structure so QA scripts remain compatible.
