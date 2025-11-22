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
- **Diagnostic System**: Comprehensive logging, crash detection, and memory monitoring are active. Logs are stored in app documents directory. Use `tool/get_crash_logs.ps1` to retrieve logs from emulator. See `CRASH_DETECTION_SUMMARY.md` and `DIAGNOSTIC_SYSTEM_INTEGRATION.md` for details.
- **Logging Requirements**: All code must use `AppLogger` for significant operations, errors, and state changes. See `.kiro/steering/logging-guidelines.md` for mandatory practices.
- **Flutter UI Performance**: All Flutter UI code must follow performance guidelines to prevent frame drops and crashes. See `.kiro/steering/flutter-ui-performance.md` for mandatory rules.
- **Kiro Specs & Steering**: The `.kiro/` folder contains feature specifications (requirements, design, tasks) and steering guidelines that provide context-specific rules for development. Always check relevant specs before working on features.

## Immediate Must Reads (in order)
- `VISION.md` - **Long-term vision**: Evolution from health app to universal personal information system.
- `AGENTS.md` - operational rules for changes (planning, validation, documentation expectations).
- `GLOSSARY.md` - canonical terms to use consistently across code and docs.
- `README.md` - project overview, feature set, quickstart instructions, and current focus.
- `RUNNING.md` - platform-specific setup, commands, and environment caveats.
- `ARCHITECTURE.md` - module boundaries, data flow, and planned extensions.
- `CLEAN_ARCHITECTURE_GUIDE.md` - layer responsibilities, dependency rules, DTO boundaries, and clean architecture testing playbook.
- `SPEC.md` - current product requirements and acceptance criteria.
- `SYNC.md` - backup/sync behaviour and formats.
- `TROUBLESHOOTING.md` - known issues, diagnostics, and workarounds.
- `TODO.md` - roadmap items and follow-ups to keep in mind after each change.
- `CRASH_DETECTION_SUMMARY.md` - crash detection system, log preservation, and debugging workflow.
- `DIAGNOSTIC_SYSTEM_INTEGRATION.md` - logging infrastructure, privacy filtering, and performance tracking.
- `.kiro/steering/` - **Mandatory guidelines**: logging practices, Flutter UI performance rules, and feature-specific checklists that apply to all development work.

## Reference Map
- **Process & Quality**: `AGENTS.md`, `TESTING.md`, `TODO.md`.
- **Product & UX Context**: `README.md`, `SPEC.md`, `Health_Tracker_Advisor_UX_Documentation.md`, `UI Design Samples/`, milestone plans (`Mx_*.md`).
- **Architecture & Data Flow**: `ARCHITECTURE.md`, `AI_ASSISTED_LIFE_COMPANION_PLAN.md`, `SYNC.md`.
- **Build & Troubleshooting**: `RUNNING.md`, `TROUBLESHOOTING.md`, `KNOWN_ISSUES_AND_FIXES.md`.
- **Diagnostics & Debugging**: `CRASH_DETECTION_SUMMARY.md`, `DIAGNOSTIC_SYSTEM_INTEGRATION.md`, `KNOWN_ISSUES_AND_FIXES.md`, `tool/get_crash_logs.ps1`, `.kiro/steering/logging-guidelines.md`.
- **Kiro Specs & Guidelines**: `.kiro/specs/` (feature requirements, design, and tasks), `.kiro/steering/` (mandatory development guidelines and performance rules).

## Strategic & UX Context
- `AI_ASSISTED_LIFE_COMPANION_PLAN.md` – holistic plan for the AI-assisted experience, privacy posture, and rollout sequence.
- `Health_Tracker_Advisor_UX_Documentation.md` – detailed UX vision, screen flows, and accessibility principles.
- `UI Design Samples/` – visual mockups for dashboard, records page, and multi-modal capture launcher.

## Kiro Folder Structure
The `.kiro/` folder contains critical development resources:

### `.kiro/specs/` - Feature Specifications
Each feature has its own subfolder with three key documents:
- **`requirements.md`** - User stories and acceptance criteria following EARS patterns
- **`design.md`** - Architecture, components, data models, and correctness properties
- **`tasks.md`** - Implementation plan with numbered, actionable coding tasks

**Current specs include:**
- `ai-chat-companion/` - AI chat interface for patient records
- `ai-summarization/` - AI-powered record summarization
- `diagnostic-system/` - Logging, crash detection, and diagnostics
- `file-upload-capture/` - File upload and attachment handling
- `onboarding-screen-performance/` - Onboarding flow optimization
- `photo-capture-processing-indicator/` - Photo capture UI feedback
- `records-home-performance/` - Records list performance optimization
- `space-initialization-performance/` - Space setup optimization
- `spaces-system/` - Multi-space organization system
- `user-authentication/` - User authentication and session management

**When to read specs:**
- Before implementing any feature, read its spec to understand requirements and design
- When debugging, check if a spec exists for the problematic area
- When planning new work, review related specs for context and patterns

### `.kiro/steering/` - Development Guidelines
Mandatory rules and best practices that apply across the codebase:
- **`logging-guidelines.md`** - Required AppLogger usage patterns, when/what/how to log
- **`flutter-ui-performance.md`** - Performance rules to prevent frame drops and crashes
- **`onboarding-performance-checklist.md`** - Specific guidelines for onboarding screen work

**These are not optional** - all code must follow steering guidelines. They are automatically included in relevant contexts.

## Usage Notes
1. At the start of every work session, read through this index and open each must-read document to refresh the current expectations before making changes.
2. **Check `.kiro/specs/` for relevant feature specifications** - Before working on any feature, look for its spec folder to understand requirements, design, and implementation plan.
3. **Review `.kiro/steering/` guidelines** - These mandatory rules apply to all development work. Familiarize yourself with logging requirements and performance guidelines.
4. If you are drafting a new milestone/feature plan (M5, capture mode brief, etc.), copy `docs/templates/milestone_plan_template.md` and keep the “Must-Read References” section intact so the Clean Architecture docs stay linked in every plan.
5. If you are just beginning work on this project (or a brand-new feature area), generate or refresh the core docs/specs first so everyone has an up-to-date reference frame.
6. After reviewing the docs, study the specific code, tests, and assets you intend to modify so you fully understand current behavior—especially in large or critical areas—before drafting changes.
7. Implement in tiny, testable increments: after each small change, run `dart analyze`, relevant tests, or manual checks before proceeding. Keep the referenced documents in sync; record updates as soon as behavior or requirements shift. Log any new manual verification steps and outcomes in `TESTING.md`.
8. Before delivering the final summary—or whenever you wrap a session—revisit every must-read document and confirm they reflect the final state of the work, updating them before signing off.
9. Update this index whenever a new "must read" document is introduced so agents always have a single authoritative entry point.
