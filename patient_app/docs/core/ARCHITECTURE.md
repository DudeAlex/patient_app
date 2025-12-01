Status: ACTIVE

# Architecture

## Overview
- Local-first: Isar for structured data, attachments on filesystem (mobile), IndexedDB-backed Isar on web (no backup).
- Backup: optional AES-GCM export to Google Drive App Data (mobile).
- Modes: Local Only (default) and opt-in AI-Assisted (Together AI) for enrichment/encouragement.

## Technology and Infrastructure Selection Principles
To ensure long term maintainability and consistency, the project should rely on well established community solutions for all generic technical infrastructure. This includes areas such as configuration and dependency management, networking and external communication, data storage and caching, authentication and security, logging and observability, background and scheduled processing, state and workflow management, user interaction layers, intelligent and AI assisted features, testing and quality assurance, build and deployment processes, monitoring and analytics, and developer tooling. Custom infrastructure may be implemented only when the project has specific requirements that cannot be met by existing tools. In such cases, the decision must be documented with a clear rationale, identified trade offs, and maintenance expectations.

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


## AI Chat Context Optimization

### Overview
The AI chat system uses a multi-stage context optimization approach to provide relevant information to the LLM while staying within token budgets.

### Architecture Layers

**Stage 3: Basic Space Context**
- **Domain:** `SpaceContext`, `RecordSummary` models
- **Application:** `SpaceContextBuilder` interface, `RecordSummaryFormatter`
- **Adapters:** `SpaceContextBuilderImpl` coordinates with `RecordsRepository` and `SpaceManager`
- **Framework:** Integrated into `SendChatMessageUseCase`

**Stage 4: Context Optimization**
- **Domain:** `DateRange`, `ContextFilters`, `TokenAllocation`, `ContextStats` models
- **Application:** 
  - `ContextFilterEngine` - Filters records by date/space/deletion
  - `RecordRelevanceScorer` - Scores by recency (70%) + frequency (30%)
  - `TokenBudgetAllocator` - Allocates 4800 tokens across sections
  - `ContextTruncationStrategy` - Truncates to fit budget (≤20 records)
- **Adapters:** `ContextConfigRepository` for user preferences
- **Framework:** Settings UI for date range configuration

### Data Flow

1. **Request Initiation**
   - User sends chat message
   - `SendChatMessageUseCase` triggered

2. **Context Assembly**
   - Load active Space ID from `SpaceManager`
   - Fetch all records from `RecordsRepository`
   - Apply filters (date range, space, deletion status)
   - Score records by relevance
   - Sort by score (descending)
   - Allocate token budget
   - Truncate to fit budget and record limit
   - Build `SpaceContext` with metadata and summaries

3. **Request Submission**
   - Assemble `ChatRequest` with context, filters, token allocation
   - Send to AI service
   - Log context stats (records, tokens, assembly time)

4. **Response Processing**
   - Receive `ChatResponse` with metadata
   - Store message with context stats
   - Display to user with feedback buttons

### Token Budget Strategy

**Total Budget:** 4800 tokens

**Allocation:**
- System Prompt: 800 tokens (fixed)
- Context (Space + Records): ≤2000 tokens (variable)
- Conversation History: 1000 tokens (fixed)
- Response: ≥1000 tokens (minimum reservation)

**Enforcement:**
- Response always gets minimum 1000 tokens
- Context reduced if needed to maintain response budget
- Unused context tokens remain available (no artificial padding)

### Relevance Scoring Algorithm

```
relevance_score = (recency_score × 0.7) + (frequency_score × 0.3)

recency_score = max(0, 10 - (days_old / 30) × 10)
frequency_score = min(10.0, viewCount)
```

**Rationale:**
- Recency (70%): Recent information usually more relevant
- Frequency (30%): Frequently accessed records are important
- Score range: 0.0 to 10.0

### Context Metrics

**Tracked per request:**
- `recordsFiltered`: Total after date filtering
- `recordsIncluded`: Actually included (≤20)
- `tokensEstimated`: Estimated for context
- `tokensAvailable`: Available budget
- `compressionRatio`: Included/filtered ratio
- `assemblyTime`: Build duration (ms)

**Logged via:** `AppLogger` with structured context

**Dashboard:** Settings → Context Metrics card

### User Feedback System

**Purpose:** Track satisfaction across stages for comparison

**Implementation:**
- `MessageFeedback` enum (positive/negative)
- Stored in `ChatMessageEntity` with timestamp
- UI: Thumbs up/down buttons on AI messages
- Repository: `updateMessageFeedback` method

### Configuration

**User Settings:**
- Date range: 7/14/30 days (default 14)
- Stored in `SharedPreferences`
- Accessible via Settings → Context Settings

**System Constants:**
- Max records: 20
- Token budget: 4800
- Response minimum: 1000
- Context maximum: 2000

### Testing Strategy

**Unit Tests:**
- Each component tested in isolation
- Mocked dependencies
- Edge cases covered

**Integration Tests:**
- End-to-end Stage 3 flow
- End-to-end Stage 4 flow
- Offline queue handling

**Property-Based Tests:**
- Space isolation
- Deleted record exclusion
- Summary truncation
- Token budget enforcement
- Date range filtering
- Record count limit
- Relevance sorting
- Response token reservation
- Truncation precedence

### Performance Targets

- Assembly time: < 500ms
- Token utilization: 80-95% of available context
- Records included: 10-20 (content dependent)
- Compression ratio: 0.2-0.4

### Module Dependencies

**Context Optimization depends on:**
- `core/domain`: Space entities
- `features/records`: RecordsRepository
- `features/spaces`: SpaceManager
- `core/infrastructure`: SharedPreferences

**Consumed by:**
- `features/ai_chat`: SendChatMessageUseCase
- `ui/settings`: Context configuration UI

### Future Enhancements

- Semantic similarity scoring
- User-specific relevance weights
- Dynamic token budget adjustment
- Multi-space context aggregation
- Real-time metric visualization
- Machine learning-based scoring

---

**Reference:** See `docs/ai/LLM_CONTEXT_OPTIMIZATION.md` for detailed documentation.
