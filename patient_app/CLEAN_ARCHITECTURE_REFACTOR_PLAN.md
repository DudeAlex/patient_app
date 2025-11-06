# Clean Architecture Refactor Plan (2025-11-04)

Purpose: translate the Clean Architecture guide into actionable, bite-sized refactors so the patient app adopts the documented layering and testing practices without destabilising core flows. Each task is intentionally small; validate and document results after every step per `AGENTS.md`.

### Prioritisation Notes (2025-11-05)
- Focus immediately on Phase 1 (records) and Phase 2 (sync); they de-risk the active M4 roadmap without blocking ongoing capture experiments.
- Treat Phase 3 work on capture modules as a stretch goal once capture UX stabilises so we avoid refactoring code that is still in heavy flux.
- Defer the Phase 4 DI container introduction until a real wiring pain point appears; current factory-based composition is sufficient.
- Revisit the broad Phase 5 testing-matrix reorganisation after the first two phases, keeping per-feature unit tests mandatory in the meantime.

### Progress Log
- 2025-11-05: Completed Phase 1 tasks 1-3 (Record entity/storage split, repository port, Isar adapter wiring across UI + sync, plus mapper/adapter tests).

### Next Session Starting Point
1. Finish Phase 1 task 4 by drafting explicit records use cases (`SaveRecord`, `FetchRecentRecords`, etc.) that consume the new port.
2. Refactor `RecordsHomeState` to depend on those use cases and adjust UI widgets accordingly.
3. Backfill use-case unit tests (mocking the repository) and update `TESTING.md` once manual UI smoke checks run.

---

## Phase 0 – Baseline & Guardrails
1. **Confirm Documentation Sync**  
   - Verify contributors have read `CLEAN_ARCHITECTURE_GUIDE.md`.  
   - Outcome: shared understanding before code moves.

2. **Codify Layer Folder Structure**  
   - Decide final folder layout: `domain/`, `application/`, `adapters/`, `ui/`.  
   - Draft naming conventions for DTOs, ports, and entities (add to guide appendix if needed).

3. **Inventory Current Dependencies**  
   - For each feature (records, sync, capture_core, capture_modes), list cross-imports that violate the inward dependency rule.  
   - Output: short table noting files that need port abstractions or relocation.

---

## Phase 1 – Records Feature Foundations
1. **Separate Entity vs Storage Model**
   - Create `lib/features/records/domain/entities/record.dart` without Isar annotations.  
   - Introduce `lib/features/records/adapters/storage/record_isar_model.dart` to keep `@collection` annotations.  
   - Map between the two in dedicated mapper functions.

2. **Define Repository Port**
   - Add `lib/features/records/application/ports/records_repository.dart` describing required methods using domain entities.  
   - Update existing code to depend on the interface (no direct `Isar` imports outside adapters).

3. **Implement Isar Repository Adapter**
   - Move persistence logic to `lib/features/records/adapters/repositories/isar_records_repository.dart`.  
   - Use mapper to convert between domain entity and storage model.  
   - Write adapter-level contract test to confirm CRUD round-trips.

4. **Extract Use Cases**
   - Introduce explicit use cases (`FetchRecentRecords`, `SearchRecords`, `SaveRecord`, `DeleteRecord`) under `application/use_cases`.  
   - Define InputDTO/OutputDTO for each, execute against the repository port.  
   - Add unit tests with mocked repository.

5. **Refactor UI State**
   - Update `RecordsHomeState` (or new presenter) to call use cases instead of repositories/Isar.  
   - Remove persistence imports from UI layer.  
   - Add state tests that mock use cases.

6. **Adjust RecordsService Bootstrap**
   - Replace singleton static with a factory that wires dependencies: open Isar, instantiate adapter, wrap with use-case instances, expose to UI via a provider.  
   - Ensure initialization logic lives in the outer layer (e.g., `lib/ui/app.dart` or a DI bootstrapper).  
   - Add doc comment noting offline constraints and encryption TODO alignment.

7. **Update Tests & Docs**
   - Add unit tests for domain entity invariants (e.g., record must have title, createdAt).  
   - Update `TESTING.md` with new scenarios.  
   - Refresh `ARCHITECTURE.md` and `CLEAN_ARCHITECTURE_GUIDE.md` examples to reflect the new structure.

---

## Phase 2 – Sync Feature Alignment
1. **Create Sync Domain Models**
   - Introduce domain value objects/entities for auto-sync status and counters, free of Isar.  
   - Keep storage schema under `adapters/storage` with annotations.

2. **Define Sync Ports**
   - Repository port for sync state + port for auto-sync runner.  
   - Use `application/use_cases` to orchestrate enabling/disabling, marking changes, promoting routine → critical.

3. **Adapter & Use Case Tests**
   - Contract test for Isar sync repository mapping.  
   - Use case tests verifying dirty counter logic with mocks.

4. **Refactor Dirty Tracker & Auto Sync**
   - Rework `AutoSyncDirtyTracker` and coordinator to depend on ports/use cases, not direct Isar writes.  
   - Ensure background scheduling remains in framework layer (e.g., platform hooks).

5. **Documentation & Test Updates**
   - Record the new flow in `SYNC.md` and `ARCHITECTURE.md`.  
   - Append manual/automated test notes in `TESTING.md` after each increment.

---

## Phase 3 - Capture Modules Cleanup *(stretch – schedule after capture UX solidifies)*
1. **Stabilize API vs Domain Layers**
   - Confirm `capture_core/api` surfaces only interfaces/DTOs.  
   - Move implementation (`CaptureControllerImpl`, registries) into `application` or `adapters` depending on responsibility.

2. **Remove Direct Storage Calls**
   - Wrap `AttachmentsStorage` interactions behind a port so capture domain logic stays storage-agnostic.

3. **Define Use Cases per Mode**
   - For each capture mode, add use cases that manage capture flow outcomes, returning DTOs for UI to render.  
   - Provide mock-based tests verifying onProcessing/prompt callbacks.

4. **UI Presenter Layer**
   - Create presenters/view models that consume use case outputs, keeping Flutter widgets simple.  
   - Add widget tests using fake use cases where beneficial.

---

## Phase 4 - Cross-Cutting Infrastructure
1. **Introduce Simple DI Container** *(defer until wiring pressure justifies it)*
   - Replace ad-hoc singleton instantiation with a lightweight dependency provider (manual or package-free) once current factory wiring becomes brittle.  
   - Document how to register adapters per platform (mobile vs web) when the container lands.

2. **Audit Core Utilities**
   - Ensure `lib/core/` only holds truly cross-cutting concerns that obey inward dependencies.  
   - Extract any feature-specific helpers back into feature modules.

3. **Review External Package Usage**
   - Confirm that packages like `google_drive_backup` expose ports instead of tightly coupling to framework details.  
   - Add tests or example adapters if necessary.

---

## Phase 5 - Testing & Automation *(re-evaluate after Phase 1 & 2 land)*
1. **Establish Testing Matrix**
   - Domain: invariants per entity/value object.  
   - Application: use case mocks verifying interactions.  
   - Adapters: contract/integration tests (Isar, storage, external gateways).  
   - UI: focused widget tests for critical screens (home, capture launcher).

2. **Set Up Test Suites**
   - Organise `test/` directory mirroring new layer structure (`features/<feature>/domain/...`).  
   - Add CI scripts to run subsets if feasible (respecting offline constraints).

3. **Update TESTING.md Template**
   - Provide checklist for future changes (which layer touched, corresponding test expectation).

---

## Phase 6 – Rollout & Hardening
1. **Incremental Migration Tracking**
   - Use this plan to tick off steps; keep changelog of completed tasks and any adjustments.  
   - Review after each phase to confirm no regressions and documentation stays current.

2. **Retrospective & Guide Refresh**
   - After major milestones (records, sync, capture), revisit `CLEAN_ARCHITECTURE_GUIDE.md` with lessons learned, example snippets, and updated pitfalls.  
   - Ensure `ARCHITECTURE.md` diagrams align with final structure.

3. **Training & Knowledge Share**
   - Host short write-ups or loom-style recordings highlighting the new workflow so contributors remain aligned.

---

## Quick Reference: First Three Concrete Tasks
1. Scaffold `domain/entities` and `adapters/storage` folders for records; copy existing entity code, strip annotations, and create Isar-specific model + mapper.  
2. Add records repository interface + use mocked unit test verifying `SaveRecordUseCase` writes through the port.  
3. Update UI to retrieve use cases via a temporary factory function while keeping behaviour unchanged; document manual verification in `TESTING.md`.

Execute each task separately, running `dart analyze` (or targeted tests) when touching code, and record outcomes before proceeding to the next item.
