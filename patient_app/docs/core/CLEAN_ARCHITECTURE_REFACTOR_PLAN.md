Status: ACTIVE

# Clean Architecture Refactor Plan (2025-11-04)

Purpose: apply clean architecture layering/testing in small, validated steps.

## Prioritization
- Focus Phase 1 (records) and Phase 2 (sync) to de-risk M4.
- Phase 3 (capture) after UX stabilizes; Phase 4 DI only if wiring pain emerges.
- Phase 5 testing matrix after early phases.

## Progress Log (highlights)
- 2025-11-05/06: Records entity/storage split; repo port + Isar adapter; use cases (`SaveRecord`, `FetchRecentRecords`, `FetchRecordsPage`, `DeleteRecord`, `GetRecordById`); UI shifted to use cases; invariants enforced; tests logged.
- 2025-11-07: Sync domain `AutoSyncStatus`; `SyncStateRepository` port + Isar adapter; use cases (toggle/change/success/promote/read/watch); dirty tracker/runner/coordinator/settings wired to use cases.
- 2025-11-08: `AppContainer` bootstrap registering capture controller + records service.

## Phase 1 - Records (done)
- Separate domain entity from storage; add repository port + Isar adapter.
- Add use cases; map UI/services to use cases; keep adapters tested (mappers/Isar).

## Phase 2 - Sync (done)
- `AutoSyncStatus` invariants; `SyncStateRepository` port + Isar adapter.
- Use cases for toggle/dirty/success/promote/read/watch; wire dirty tracker, runner, coordinator, settings to them.

## Phase 3 - Capture (stretch)
- Build `CaptureControllerImpl` + registry + storage ports; adapters isolate filesystem.
- Mode use cases (photo/doc/voice/file/email upcoming) keep widgets dumb; mock-based tests for prompts/retakes.
- Presenters own orchestration/state; add widget tests once persistence stabilizes.

## Phase 4 - Cross-Cutting
- Simple DI (`AppContainer`) now registers capture/records; extend as needed.
- Audit `lib/core/` for truly cross-cutting utilities; move feature-specific helpers back.
- Ensure packages like `google_drive_backup` stay port-based; add examples/tests if needed.

## Phase 5 - Testing Matrix (later)
- Domain invariants; application mocks; adapter contract/integration; targeted widget tests.
- Mirror `test/` to layer structure; add CI subsets if possible.
- Refresh TESTING.md checklist.

## Phase 6 - Rollout
- Track incremental migrations; update docs (Guide + Architecture) with lessons.
- Share quick training/recordings for contributors.

## Quick Start Tasks
1) Scaffold `domain/entities` + `adapters/storage` for records; Isar model + mapper.  
2) Add repository interface + mocked unit test for `SaveRecordUseCase`.  
3) UI resolves use cases via factories/container; log manual verification in TESTING.md.  
Run analyzer/tests after each step and record outcomes.
