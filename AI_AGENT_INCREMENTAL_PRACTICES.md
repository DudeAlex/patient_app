# AI Agent Incremental Practices

These guidelines keep AI-assisted development safe, verifiable, and free from hallucination drift. Apply them on every project where an agent contributes.

## 1. Plan First
- Break the task into tiny, testable steps before touching code.
- Confirm dependencies (docs, specs, feature flags) are up to date and aligned with the latest requirements.
- Write down assumptions and confirm them with source documents (specs, architecture, tickets) before implementing.

## 2. Make One Change at a Time
- Implement a single logical change per step; avoid parallel edits or refactors that broaden scope.
- Keep diffs tight—no drive-by formatting or unrelated cleanups.
- If unexpected files change, pause, re-read the requirements, or ask a human for clarification before continuing.

## 3. Validate Immediately
- After each step, run the lightweight checks that matter:
  - `dart analyze`, `flutter analyze`, `npm test`, etc.
  - Targeted unit/widget tests for the code you touched.
  - Manual smoke checks whenever UI behaviour shifts.
- Only proceed when the current step passes; log validations so humans can audit what ran.

## 4. Sync Documentation as You Go
- Update specs, READMEs, runbooks, and migration guides in the same increment when behaviour changes.
- Append new manual verification steps and outcomes to the project’s testing log.
- Cross-check that documentation matches the actual implementation to avoid hallucinated features.

## 5. Summarise Before Hand-off
- Record what changed, how it was validated, and any follow-ups or blocked items.
- Call out assumptions and open questions explicitly so humans can resolve them quickly.

## 6. Re-plan When Scope Grows
- If the task expands, re-plan instead of stretching a single increment.
- Split the work into fresh steps and re-enter the plan → change → validate loop.
- Escalate to humans when requirements conflict or feel ambiguous; do not invent missing details.

## 7. Guardrails Against Hallucinations
- Cite concrete file paths, line numbers, or commands when describing changes or instructions.
- If an answer relies on external knowledge, confirm it with provided documentation or note the uncertainty.
- Never fabricate API responses, test results, or dependencies—flag unknowns and propose how to verify them.

## 8. Security & Privacy Awareness
- Treat credentials, PHI, or other sensitive data with zero-trust assumptions; never log or expose secrets.
- Follow project-specific security guidelines (consent flows, encryption, retention policies).
- Document any privacy implications introduced by your changes so reviewers can inspect them.

## 9. Documentation Toolkit for Every Project
- Establish a lightweight doc set at project kick-off so expectations stay explicit. Recommended files (mirroring the `patient_app` structure):
  - `README.md`: high-level purpose, feature summary, setup prerequisites, and current focus.
  - `RUNNING.md`: platform-specific commands, environment quirks, and troubleshooting steps for launching the app.
  - `SPEC.md`: living product requirements, acceptance criteria, and manual test plan.
  - `ARCHITECTURE.md`: module boundaries, core dependencies, data flow, and planned extensions.
  - `SYNC.md` or equivalent: data durability/sync strategy, backup formats, and consent constraints.
  - `TROUBLESHOOTING.md`: known issues, diagnostics, and recovery playbooks.
  - `TODO.md`: roadmap milestones with links to per-milestone breakdown docs (e.g., `M2_RECORDS_CRUD_PLAN.md`).
  - `TESTING.md`: manual or automated verification log capturing commands, environments, and outcomes.
  - `AGENTS.md` / contributor guidelines: operational rules for humans and AI, emphasizing incremental delivery.
  - `AI_AGENT_START_HERE.md`: a quick entry point linking to all must-read docs before work begins.
- Keep these files synchronized with code changes; when working on a new project, clone this structure and tailor the content to the domain.

Keeping changes small, validated, and grounded in documentation protects every project—adopt these practices as the default working mode for AI agents and humans collaborating together.
