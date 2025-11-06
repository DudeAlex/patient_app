# AI Agent Start Here

Purpose: give any AI or contributor a single launchpad to the repo’s must-read guidance while keeping the source documents in their canonical locations.

## Core Snapshot (read first)
- **Mission & Scope**: Local-first patient records app with optional multi-modal capture (photo, scan, voice, keyboard, file, email) and consented AI assistance. Privacy is default; everything works offline first.
- **Process Guardrails**: Work in tiny, verifiable increments, comment intent, and keep documentation in sync (`AGENTS.md` for full rules).
- **Run Basics**: From `patient_app/`, use `flutter run -d chrome` (web) or follow the Android flow (`flutter clean`, `flutter pub get`, `dart run build_runner build --delete-conflicting-outputs`, then `flutter run -d <emulator>` with the Google server client id).
- **Quality Gates**: After each change, run `dart analyze` or targeted tests as appropriate and log manual/automated results in `TESTING.md`.
- **Backup & Consent**: Mobile backups encrypt to `patient-backup-v1.enc` (AES-GCM) in Drive App Data; AI features require explicit opt-in and must keep originals local.
- **Troubleshooting Triggers**: Symlink issues on Windows, emulator GPU/Play Services quirks, and Google auth scopes are documented in `TROUBLESHOOTING.md`.
- **Roadmap**: Current milestone focus is M4 Auto Sync and upcoming multi-modal capture (see `TODO.md` and milestone plans).

## Immediate Must Reads (in order)
- `AGENTS.md` - operational rules for changes (planning, validation, documentation expectations).
- `README.md` - project overview, feature set, quickstart instructions, and current focus.
- `RUNNING.md` - platform-specific setup, commands, and environment caveats.
- `ARCHITECTURE.md` - module boundaries, data flow, and planned extensions.
- `CLEAN_ARCHITECTURE_GUIDE.md` - layer responsibilities, dependency rules, DTO boundaries, and clean architecture testing playbook.
- `SPEC.md` - current product requirements and acceptance criteria.
- `SYNC.md` - backup/sync behaviour and formats.
- `TROUBLESHOOTING.md` - known issues, diagnostics, and workarounds.
- `TODO.md` - roadmap items and follow-ups to keep in mind after each change.

## Reference Map
- **Process & Quality**: `AGENTS.md`, `TESTING.md`, `TODO.md`.
- **Product & UX Context**: `README.md`, `SPEC.md`, `Health_Tracker_Advisor_UX_Documentation.md`, milestone plans (`Mx_*.md`).
- **Architecture & Data Flow**: `ARCHITECTURE.md`, `AI_ASSISTED_PATIENT_APP_PLAN.md`, `SYNC.md`.
- **Build & Troubleshooting**: `RUNNING.md`, `TROUBLESHOOTING.md`.

## Strategic & UX Context
- `../AI_ASSISTED_PATIENT_APP_PLAN.md` – holistic plan for the AI-assisted experience, privacy posture, and rollout sequence.
- `Health_Tracker_Advisor_UX_Documentation.md` – detailed UX vision, screen flows, and accessibility principles.

## Usage Notes
1. At the start of every work session, read through this index and open each must-read document to refresh the current expectations before making changes.
2. If you are just beginning work on this project (or a brand-new feature area), generate or refresh the core docs/specs first so everyone has an up-to-date reference frame.
3. After reviewing the docs, study the specific code, tests, and assets you intend to modify so you fully understand current behavior-especially in large or critical areas-before drafting changes.
4. Implement in tiny, testable increments: after each small change, run `dart analyze`, relevant tests, or manual checks before proceeding. Keep the referenced documents in sync; record updates as soon as behavior or requirements shift. Log any new manual verification steps and outcomes in `TESTING.md`.
5. Before delivering the final summary—or whenever you wrap a session—revisit every must-read document and confirm they reflect the final state of the work, updating them before signing off.
6. Update this index whenever a new "must read" document is introduced so agents always have a single authoritative entry point.
