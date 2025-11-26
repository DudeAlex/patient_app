Status: ACTIVE

# TESTING

## Principles
- Prefer deterministic, targeted tests; small increments.
- Log every manual/automated run here; include scenario, env, result.
- Use AppLogger; avoid sensitive data in logs.

## What to Run
- Analyzer: `dart analyze`.
- Codegen when models change: `dart run build_runner build --delete-conflicting-outputs`.
- Targeted suites: unit/use-case/adapter/widget as relevant to touched modules.
- Manual checks for UX/backups/auth; record outcomes.

## Recording Results
- Append entries with: date, scope, commands, result, notes.
- Include device/emulator, OS, branch, relevant flags (dart-define).

## Logging Expectations
- Use structured AppLogger messages with context.
- Capture failures with error + stack trace; note follow-ups.

## Manual Scenario Templates
- Sign-in/out; backup/restore success/failure; auto-sync cadence; capture flows; AI consent/offline queue; performance hotspots; accessibility checks.

## Current Log
- (Add entries below)
