# Architecture

Overview
- Local-first app with Isar for structured data and file storage for attachments (mobile)
- Optional encrypted backup to Google Drive App Data (mobile)
- Web build runs with IndexedDB-backed Isar; backup disabled by default
- Dual operating modes: Local Only (default) and AI-Assisted (opt-in via Together AI) for analysis and encouragement.

Key Modules
- `lib/ui/` feature wiring + navigation shell
  - `ui/app.dart` Material app, dependency injection, route registration
  - `ui/settings/settings_screen.dart` coordinates settings module surfaces
- `lib/core/` shared infrastructure (no feature-specific logic)
  - `core/db/isar.dart` open Isar with schemas
  - `core/storage/attachments.dart` manage attachments root directory
  - Planned: `core/ai/ai_processing_service.dart`, `core/support/support_network.dart`, `core/import/email_ingest.dart`, `core/vitals/vitals_service.dart` (cross-feature services exposed via interfaces)
- `packages/google_drive_backup/` reusable backup/auth library (fully encapsulated module)
- Feature modules live under `lib/features/<module>/`
  - `features/records/` (domain entities, application ports, adapters, UI state, add/list/detail screens)
  - `features/sync/` (SyncState repository, dirty tracking, future auto-sync runner)
  - Planned: `features/capture_core/`, `features/capture_modes/photo|scan|voice|file|email/`, `features/support_network/`, `features/vitals/`, etc. Each module owns its models/services/UI and exposes a compact API for other modules to consume.

## Feature Module Methodology (“Lego” Architecture)

We design every milestone as a collection of modules that can be composed, replaced, or extended without touching unrelated code. Contributors should adhere to the following principles:

- **Clear Boundaries**: Keep all code for a feature inside `lib/features/<feature>/...`. A module may expose public entry points (e.g., services, providers, routes) via `lib/features/<feature>/<feature>.dart` or a dedicated `api/` folder. Other modules import only these entry points.
- **Interfaces over Implementations**: Define service/repository interfaces in the module and inject them where needed. When a module depends on another module, it should do so through interfaces or simple function contracts rather than concrete classes.
- **Dependency Injection**: Pass dependencies via constructors or the thin `AppContainer` (`lib/core/di/app_container.dart`) initialised from `main.dart`. Avoid ad-hoc globals; modules register their services during app boot (e.g., `bootstrapAppContainer` wires the capture controller + records service).
- **Stable Data Contracts**: Shared data structures live in `core/` only if they are truly cross-cutting. If a module needs to publish data, provide DTOs or value objects in its public API.
- **Testable Modules**: Each module owns its tests and may substitute dependencies with mocks. Modules should not rely on global state or static singletons to remain test-friendly.
- **Minimal Coupling**: Avoid direct imports across sibling modules. If cross-module communication is required, use events/notifiers, callbacks, or well-defined service interfaces.
- **Documentation**: Each module includes a `README.md` or section explaining responsibilities, APIs, dependencies, and extension points. Plans (e.g., `Mx_<feature>_PLAN.md`) should list module boundaries and contracts.
- **Migration Safety**: Schema changes are owned by the module author. Provide migrations/backfills that do not break inactive modules.
- **Localization-Ready**: Never hard-code patient-facing copy inside business logic or widgets. Surface strings through a localisation layer (see below) so future languages can drop in without editing module internals.
- **AI Hook Awareness**: When a workflow can benefit from AI assistance, define clear extension points (interfaces, events) so AI modules can plug in without rewriting the base experience.
- **OOP & Functional Balance**: Encapsulate behavior behind SOLID-friendly interfaces, and prefer immutable data structures or pure helpers when transforming state so modules stay predictable and testable.

### Module Contracts & Examples

| Module | Responsibility | Public Surface | Depends On |
| --- | --- | --- | --- |
| `features/records` | CRUD operations, record list/detail UI | `RecordEntity`, `RecordsRepository` port, `RecordsService`, `RecordsHomeState`, routes for add/edit/detail screens | `core/db`, `core/storage` via adapters |
| `features/sync` | Dirty tracking, SyncState persistence, auto-sync orchestration | `AutoSyncStatus` domain entity, `SyncStateRepository` port, `IsarSyncStateRepository`, use cases (`SetAutoSyncEnabled`, `RecordAutoSyncChange`, `MarkAutoSyncSuccess`, `Read/WatchAutoSyncStatus`), `AutoSyncDirtyTracker`, `AutoSyncCoordinator`, `AutoSyncRunner` | `features/records` (via use cases), `google_drive_backup` |

### Sync Module Snapshot (Phase 2)

- **Domain**: `AutoSyncStatus` lives under `features/sync/domain/entities` and encodes the invariants for dirty counters/device IDs so adapters cannot persist invalid states.
- **Application layer**: Use cases under `features/sync/application/use_cases/` provide the single entry points the UI (`SettingsScreen`), records workflow (`AutoSyncDirtyTracker`), and lifecycle hooks (`AutoSyncCoordinator`/`AutoSyncRunner`) consume. This keeps orchestration focused on intent (toggle, record change, mark success, observe status) while hiding storage concerns.
- **Adapters**: `IsarSyncStateRepository` implements the port, maps to the generated `SyncState` collection, and caches the device id. `AutoSyncDirtyTracker`, `AutoSyncCoordinator`, and `AutoSyncRunner` now depend exclusively on the application layer so we can replace persistence without touching lifecycle code.
- **Framework**: Settings wires the toggle by invoking `SetAutoSyncEnabledUseCase`, and Records UI records dirty events via `AutoSyncDirtyTracker`. `AutoSyncRunner` still uses `DriveBackupManager`, but persistence updates now flow through `MarkAutoSyncSuccessUseCase`.
| `features/capture_core` | Multi-modal capture launcher, review flow orchestration | `CaptureControllerImpl`, `CaptureModeRegistry`, capture session/artifact storage ports | `features/records` (to save), `core/storage` via adapters |
| `features/capture_modes/photo` | Camera capture with clarity analysis and OCR stubs | `PhotoCaptureModule`, `CapturePhotoUseCase`, `PhotoCaptureService` (gateway) | Capture storage ports, `image_picker`, optional analyzers |
| `features/capture_modes/document_scan` | Multi-page document scanning with enhancement + clarity prompts and analysis hooks | `DocumentScanModule`, `CaptureDocumentUseCase`, `DocumentScanService` (gateway) | Capture storage ports, `image_picker`, `image` |
| `features/capture_modes/voice` | Voice dictation capture and shared audio pipeline for AI conversations | `VoiceCaptureModule`, `VoiceCaptureService` | Capture storage ports, microphone permissions, optional STT/TTS providers |
| `features/capture_modes/<mode>` (planned) | Concrete capture flows (voice, file, email) | `CaptureMode` implementations registered with `capture_core` | `core/storage`, optional platform APIs |
| `packages/google_drive_backup` | Google auth + encrypted backup plumbing | `DriveBackupManager` class | `http`, `googleapis` |

### Capture Module Snapshot (Phase 3)

- **Core layer**: `capture_core/application/` hosts `CaptureControllerImpl`, the in-memory registry, and the capture session/artifact storage ports. Attachments-backed adapters live under `capture_core/adapters/storage` so modes never import `AttachmentsStorage` directly.
- **Photo mode**: `PhotoCaptureService` implements `PhotoCaptureGateway`; `CapturePhotoUseCase` encapsulates the blur-prompt flow and metadata tagging; `PhotoCaptureMode` simply invokes the use case. This keeps UI widgets free of business logic while allowing tests to mock the gateway.
- **Document scan mode**: mirrored architecture with `DocumentScanService` (gateway) and `CaptureDocumentUseCase`, ensuring clarity prompts, page artifacts, and draft merging stay inside the use case.
- **Voice mode**: already routes reads/writes through the capture storage ports so later use cases can plug in without filesystem references.

This structure lets us iterate on capture behavior (e.g., swapping OCR/analysis) or storage strategies by swapping adapters/use cases without touching UI widgets.

All new modules must document:
- Public API (classes/functions exposed to other modules)
- Required dependencies and how they are injected
- Events/notifications emitted
- Storage schema owned by the module
- Tests/manual scenarios

## Clean Architecture Alignment

We follow the layered dependency rule `Frameworks & Drivers -> Interface Adapters -> Application (Use Cases) -> Domain (Entities/Value Objects)`. Dependencies always point inward so domain rules stay insulated from framework churn. Each feature folder mirrors these layers (`domain/`, `application/`, `adapters/`, `ui/`), and cross-cutting helpers in `lib/core/` must respect the same direction.

Key guardrails (see `CLEAN_ARCHITECTURE_GUIDE.md` for the full playbook):
- Domain entities hold business invariants only—no UI/HTTP/ORM/serialization helpers or active-record patterns.
- Use cases orchestrate scenarios via InputDTO/OutputDTO contracts and depend only on ports (repository/gateway interfaces).
- Interface adapters perform all mapping between entities, DTOs, and storage/transport models; controllers never talk to persistence directly.
- Framework-specific code (Flutter widgets, Isar implementations, OAuth flows) lives in the outermost layer and can be swapped without touching inner rules.

The canonical data flow is: request -> controller -> `UseCase.InputDTO` -> entity rule enforcement + ports -> persistence/adapters -> `UseCase.OutputDTO` -> presenter/response model. Testing mirrors the layers: pure domain unit tests, mocked use-case tests, and adapter contract tests.

Data Model (Isar)
- Record: id, type, date, title, text?, tags[], createdAt, updatedAt, deletedAt?
- Attachment: id, recordId, path, kind, ocrText?, createdAt
- Insight: id, recordId?, kind, text, createdAt
- SyncState (singleton): lastSyncedAt?, lastRemoteModified?, localChangeCounter, deviceId
- Planned: SupportContact, WellnessCheckIn collections (see SPEC.md for fields)
- Domain-level guards: `RecordEntity` enforces non-empty type/title strings and monotonic timestamps (createdAt ≤ updatedAt ≤ deletedAt), while `AutoSyncStatus` asserts non-negative dirty counters, consistent totals, and non-empty device ids before reaching adapters; unit tests lock in those invariants.

## Localization & Internationalisation

All patient-facing strings, accessibility labels, and menu items must be routed through a localisation mechanism (`intl`/`gen_l10n`). Modules should:

- Define copy keys or string providers inside the module’s `api/` surface.
- Avoid embedding prose inside widgets; instead request text from the localisation layer so language packs can be swapped at runtime.
- Keep structured data (menu configuration, prompts) in JSON/config files where possible to simplify translation workflows.

Until the `gen_l10n` workflow lands, stage new strings in a shared constants file with TODO markers so they are easy to extract later. New features must document any copy they introduce and note if translations are pending.

## AI-First Design Principles

The app is an AI-enabled assistant. For every new module:

- Identify decision points where AI can assist (e.g., clarity checks, OCR, data entry suggestions) and expose those via replaceable strategy interfaces.
- Ensure AI integrations respect consent: modules must work offline/local-first and emit events so the AI layer can attach when the patient opts in.
- Capture enough context (metadata, artefact descriptors) so future AI models can reason about the patient action without altering the core module.
- Document AI hooks in the module README and plans so contributors know where to extend functionality.

Existing modules should note in their README which extension points AI services consume today (e.g., photo OCR, voice dictation transcription) and which are planned.

Security
- Backup encryption: AES-GCM with random nonce; key stored in platform secure storage
- No data leaves device unencrypted for backups
- AI-assisted mode: outbound requests gated by consent, API key stored securely, responses include confidence + disclaimers, logs redact PHI

Platform Behavior
- Android/iOS: full backup/restore via Drive appData (`patient-backup-v1.enc`)
- Web: no backup (stub), app runs with UI and IndexedDB-backed Isar
- AI-assisted features target Android/iOS first; web companion requires dedicated consent UX and may ship later.

Future Work
- Implement expanded multi-modal Add Record flow (photo, scan, voice, keyboard, file upload, email import) with accessible review.
- Build `AiProcessingService` + background queue for Together AI enrichment.
- Deliver camera-based pulse capture + blood pressure integrations via `vitals_service`.
- Add support network/emergency modules and integrate with home/emergency UI.
- Ship compassionate notifications, wellness check-ins, and localisation via Flutter `gen-l10n`.
- See `TODO.md` for the detailed milestone breakdown.
