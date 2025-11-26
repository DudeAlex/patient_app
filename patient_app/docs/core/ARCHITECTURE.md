Status: ACTIVE

# Architecture

## Overview
- Local-first: Isar for structured data, attachments on filesystem (mobile), IndexedDB-backed Isar on web (no backup).
- Backup: optional AES-GCM export to Google Drive App Data (mobile).
- Modes: Local Only (default) and opt-in AI-Assisted (Together AI) for enrichment/encouragement.

## Key Modules
- `lib/ui/`: app shell and navigation (`ui/app.dart`, `ui/settings/settings_screen.dart`).
- `lib/core/`: shared infra (Isar open, attachments root, Space entities/gradients, SpaceManager service/ports, SharedPreferences storage, migrations). Planned cross-cutting: AI processing, support network, email ingest, vitals service.
- `packages/google_drive_backup/`: reusable backup/auth helper.
- `lib/features/<feature>/`: modular features (spaces, records, sync; planned capture_core + capture_modes, support_network, vitals). Each owns its API and UI.

## Feature Module Methodology ("Lego" Architecture)
- Layer rule: domain <- application <- adapters <- framework; modules plug together without leaks.
- Boundaries: keep code in `lib/features/<feature>/...`; expose only a small API (e.g., `<feature>.dart` or `api/`).
- Interfaces first: depend on ports/contracts; inject via constructors or `AppContainer`.
- Shared data: place truly cross-cutting DTOs/value objects in `core/` sparingly.
- Testability: module-owned tests; avoid globals/static singletons.
- Coupling: no sibling imports; use events or service interfaces for cross-module needs.
- Documentation: each module documents responsibilities, APIs, deps, extension points; plans list contracts.
- Migration safety: authors own migrations/backfills that avoid breaking inactive modules.
- Localization: keep patient-facing copy out of business logic; use localization layer.
- AI hooks: define extension points where AI can assist without rewrites.
- Style: SOLID-friendly interfaces; prefer immutable/pure helpers for state transforms.

### Module Contracts (examples)
| Module | Responsibility | Public Surface | Depends On |
| --- | --- | --- | --- |
| `features/spaces` | Space management & UI | `Space`, `SpaceRegistry`, `SpaceManager`, `SpaceProvider`, onboarding/selector/creation screens | `core/domain`, `core/application`, `core/infrastructure` |
| `features/records` | CRUD + list/detail UI | `RecordEntity`, `RecordsRepository` port, `RecordsService`, `RecordsHomeState`, add/edit/detail routes | `core/db`, `core/storage` adapters, `features/spaces` |
| `features/sync` | Dirty tracking + auto-sync | `AutoSyncStatus`, `SyncStateRepository`, use cases (`SetAutoSyncEnabled`, `RecordAutoSyncChange`, `MarkAutoSyncSuccess`, `Read/WatchAutoSyncStatus`), `AutoSyncDirtyTracker`, `AutoSyncCoordinator`, `AutoSyncRunner` | `features/records`, `google_drive_backup` |
| `features/capture_core` | Capture orchestration | `CaptureControllerImpl`, `CaptureModeRegistry`, capture session/artifact storage ports | `features/records`, `core/storage` |
| `features/capture_modes/*` | Mode-specific flows | `CapturePhotoUseCase`/`DocumentScanUseCase`/`VoiceCaptureService` etc. | capture storage ports, platform APIs |
| `packages/google_drive_backup` | Backup plumbing | `DriveBackupManager` | `http`, `googleapis` |

### Sync Snapshot (Phase 2)
- Domain: `AutoSyncStatus` guards dirty counters/device ids.
- Application: use cases wrap toggles, dirty events, success marking, reads/watches.
- Adapters: `IsarSyncStateRepository` maps to `SyncState`; lifecycle classes depend on application layer only.
- Framework: Settings uses `SetAutoSyncEnabledUseCase`; Records uses `AutoSyncDirtyTracker`; `AutoSyncRunner` calls `DriveBackupManager` then `MarkAutoSyncSuccessUseCase`.

### Capture Snapshot (Phase 3)
- Core: `capture_core/application` hosts controller, registry, storage ports; adapters keep modes away from filesystem specifics.
- Photo: `PhotoCaptureService` (gateway) + `CapturePhotoUseCase` handle clarity prompts/metadata; `PhotoCaptureMode` calls the use case.
- Document scan: parallel structure with `DocumentScanService`/`CaptureDocumentUseCase`.
- Voice: routes through capture storage ports to stay decoupled from filesystem; prepared for AI hooks.

## Clean Architecture Alignment
- Dependency rule: Frameworks & Drivers -> Interface Adapters -> Application (Use Cases) -> Domain (Entities/Value Objects); dependencies point inward.
- Entities: invariants only, no UI/HTTP/ORM helpers.
- Use cases: orchestrate via DTOs and ports; no business rules in adapters/UI.
- Adapters: map entities/DTOs to storage/transport; controllers never hit persistence directly.
- Framework: Flutter UI/Isar/OAuth stay replaceable without touching inner layers.
- Data flow: request -> controller -> InputDTO -> entities + ports -> adapters -> OutputDTO -> presenter.
- Testing mirrors layers: domain unit -> use-case with mocks -> adapter contract tests.

## Data Model (Isar)
- Record: id, spaceId, type, date, title, text?, tags[], createdAt, updatedAt, deletedAt?; index on (spaceId, type, date); backfill missing spaceId to 'health'.
- Attachment: id, recordId, path, kind (image/pdf/audio/email), ocrText?, createdAt.
- Insight: id, recordId?, kind, text, createdAt.
- SyncState (singleton id=1): lastSyncedAt?, lastRemoteModified?, localChangeCounter, deviceId.
- Planned: SupportContact, WellnessCheckIn, VitalMeasurement (see SPEC).
- Domain guards: `RecordEntity` enforces non-empty type/title and monotonic timestamps; `AutoSyncStatus` asserts non-negative counters/valid ids before persistence.

### Spaces System Data Model
- Space entity (`lib/core/domain/entities/space.dart`): id, name, icon, gradient, description, categories, isDefault, isCustom, createdAt.
- Storage (SharedPreferences): active space ids, current space id, custom spaces JSON, onboarding completion flag.
- Defaults: 8 preconfigured spaces (Health, Education, Home & Life, Business, Finance, Travel, Family, Creative) with gradients/categories.
- Migration: existing records without spaceId default to 'health'; tracked via prefs version; existing users auto-enable Health and mark onboarding complete; new users run onboarding.
