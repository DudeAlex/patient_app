# AI Agent Start Here

Purpose: give any AI or contributor a single launchpad to the repo’s must-read guidance while keeping the source documents in their canonical locations.

## Immediate Must Reads (in order)
- `AGENTS.md` – operational rules for changes (planning, validation, documentation expectations).
- `README.md` – project overview, feature set, quickstart instructions, and current focus.
- `RUNNING.md` – platform-specific setup, commands, and environment caveats.
- `ARCHITECTURE.md` – module boundaries, data flow, and planned extensions.
- `SPEC.md` – current product requirements and acceptance criteria.
- `SYNC.md` – backup/sync behaviour and formats.
- `TROUBLESHOOTING.md` – known issues, diagnostics, and workarounds.
- `TODO.md` – roadmap items and follow-ups to keep in mind after each change.

## Strategic & UX Context
- `../AI_ASSISTED_PATIENT_APP_PLAN.md` – holistic plan for the AI-assisted experience, privacy posture, and rollout sequence.
- `Health_Tracker_Advisor_UX_Documentation.md` – detailed UX vision, screen flows, and accessibility principles.

## Usage Notes
1. At the start of every work session, read through this index and open each must-read document to refresh the current expectations before making changes.
2. If you are just beginning work on this project (or a brand-new feature area), generate or refresh the core docs/specs first so everyone has an up-to-date reference frame.
3. After reviewing the docs, study the specific code, tests, and assets you intend to modify so you fully understand current behavior-especially in large or critical areas-before drafting changes.
4. Implement in tiny, testable increments: after each small change, run `dart analyze`, relevant tests, or manual checks before proceeding. Keep the referenced documents in sync; record updates as soon as behavior or requirements shift. Log any new manual verification steps and outcomes in `TESTING.md`.
5. Before delivering the final summary, revisit every must-read document and confirm they reflect the final state of the work, making edits where necessary.
6. Update this index whenever a new "must read" document is introduced so agents always have a single authoritative entry point.
