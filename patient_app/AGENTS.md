# AGENTS.md — Agent Guidelines for This Repo

Scope: applies to the entire `patient_app/` project.

Purpose
- Keep development safe, incremental, and well‑documented. Avoid large, fast changes that are risky or unverified.

Golden Rules
- Move slowly: prefer small, focused updates over big refactors.
- Validate manually: after each meaningful change, outline how to run and what to check; request approval before running commands when required by the environment, and record the outcome in `TESTING.md`.
- Comment your code: when adding/modifying code, include short, clear comments explaining intent and non-obvious choices.
- Keep docs in sync: whenever you change behavior, update the relevant info files (README, RUNNING, ARCHITECTURE, SYNC, TROUBLESHOOTING, TODO).
- Stay synced with docs: begin every work session by reading `AI_AGENT_START_HERE.md` and the listed documents; finish by revisiting them to confirm they reflect the final state.
- Understand before you change: study the existing implementation, related tests, and documentation for the feature you plan to touch. In large areas, focus first on the modules your edits could break before drafting modifications.
- Minimize blast radius: do not reformat or reorganize unrelated files; keep diffs tight and purposeful.

Workflow Expectations
Before Step 1, refresh context by reading `AI_AGENT_START_HERE.md` and opening each must-read document so the active guidance is top of mind. Then invest time in reviewing the relevant code, tests, and docs to confirm you fully understand current behavior. After Step 5, reopen those documents to double-check that every necessary update has been captured.
1) Plan: Create or update a short plan with concrete steps.
2) Implement incrementally: small patches that are easy to review and revert.
3) Document: update info files in the same patch (what changed, why, how to run/verify).
4) Validate: describe manual checks or tests performed; run analyzers/tests only with approval when needed. Append the new scenario and result to `TESTING.md` so the manual log stays current.
5) Summarize: provide a brief, scannable summary in the final message (affected files, commands to run, known limitations).

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
- Add concise comments for new logic blocks and tricky sections.
- No sweeping renames or “drive‑by” fixes outside the change scope.

When in Doubt
- Ask for confirmation before large changes.
- Split work into multiple small patches instead of one big patch.
