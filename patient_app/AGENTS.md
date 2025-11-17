# AGENTS.md — Agent Guidelines for This Repo

Scope: applies to the entire `patient_app/` project.

Purpose
- Keep development safe, incremental, and well‑documented. Avoid large, fast changes that are risky or unverified.

Golden Rules
- Move slowly: prefer small, focused updates over big refactors, and break work into tiny, testable increments.
- Validate manually: after each meaningful change, outline how to run and what to check; request approval before running commands when required by the environment, and record the outcome in `TESTING.md`.
- Comment your code: when adding/modifying code, include short, clear comments explaining intent and non-obvious choices.
- Keep docs in sync: whenever you change behavior, update the relevant info files (README, RUNNING, ARCHITECTURE, SYNC, TROUBLESHOOTING, TODO).
- Stay synced with docs: begin every work session by reading `AI_AGENT_START_HERE.md` and the listed documents; finish by revisiting them to confirm they reflect the final state.
- Understand before you change: study the existing implementation, related tests, and documentation for the feature you plan to touch. In large areas, focus first on the modules your edits could break before drafting modifications.
- Minimize blast radius: do not reformat or reorganize unrelated files; keep diffs tight and purposeful.

Workflow Expectations
Before Step 1, refresh context by reading `AI_AGENT_START_HERE.md` and opening each must-read document so the active guidance is top of mind. Then invest time in reviewing the relevant code, tests, and docs to confirm you fully understand current behavior. After Step 5, reopen those documents to double-check that every necessary update has been captured.
Before initiating any refactor or architecture-impacting change, the assigned agent must survey the current implementation end-to-end (code, tests, assets) to ensure proposed edits respect existing behaviour and layering. Document the review scope in the plan.
When drafting a new milestone/feature plan (e.g., M5 brief), duplicate `docs/templates/milestone_plan_template.md` and keep the “Must-Read References” section intact so the Clean Architecture guide + refactor plan are linked automatically.
1) Plan: Create or update a short plan with concrete steps. When kicking off a new roadmap milestone (e.g., M3), author a dedicated breakdown document in the repository (see `M2_RECORDS_CRUD_PLAN.md`) so the detailed tasks live alongside the main TODO. Keep planned steps small enough that you can implement one at a time and verify immediately (run `dart analyze`, targeted tests, or manual checks after each increment).
2) Implement incrementally: small patches that are easy to review and revert.
3) Document: update info files in the same patch (what changed, why, how to run/verify).
4) Validate: describe manual checks or tests performed; run analyzers/tests only with approval when needed. Append the new scenario and result to `TESTING.md` so the manual log stays current.
5) Summarize: provide a brief, scannable summary in the final message (affected files, commands to run, known limitations). Before ending a session (especially when stepping away), sweep relevant docs (`README`, `SPEC`, `TODO`, milestone plans, etc.) to confirm they reflect the latest changes.

Documentation Checklist (update as applicable)
- README.md: high‑level capabilities or user‑visible behavior.
- RUNNING.md: commands, flags, platform notes.
- ARCHITECTURE.md: modules, data flow, security implications.
- SYNC.md: backup/sync behavior or formats.
- TROUBLESHOOTING.md: known issues, workarounds, environment caveats.
- TODO.md: milestones, next steps, follow‑ups created by your change.
 - SPEC.md: detailed product requirements, acceptance criteria, manual test plan.

Coding Style
- Follow existing patterns; avoid introducing new frameworks/structures unless necessary.
- Align every change with the clean architecture guidance in `CLEAN_ARCHITECTURE_GUIDE.md`: keep entities free of frameworks, route all orchestration through use cases, and perform mapping inside adapters.
- Add concise comments for new logic blocks and tricky sections.
- No sweeping renames or "drive-by" fixes outside the change scope.
- Apply Clean Code practices: clear intent-revealing names, small focused functions, and minimal side effects so the code stays easy to read and maintain.
- Respect core OOP principles (SOLID, encapsulation) when shaping module interfaces, and lean on functional patterns (immutability, pure helpers) where they simplify state or side-effect handling.

Logging Requirements
- Use `AppLogger` for all significant operations, state changes, and errors (see `.kiro/steering/logging-guidelines.md` for details).
- Always log errors with context: `await AppLogger.error('Message', error: e, stackTrace: stackTrace, context: {...})`.
- Use `AppLogger.startOperation()` / `endOperation()` for performance-critical code.
- Include rich context with all log messages: `context: {'key': 'value'}`.
- Avoid logging sensitive data (privacy filter will redact, but be mindful).
- Check logs after changes to ensure no infinite logging loops or excessive noise.

When in Doubt
- Ask for confirmation before large changes.
- Split work into multiple small patches instead of one big patch.
