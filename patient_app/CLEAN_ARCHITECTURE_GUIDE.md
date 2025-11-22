# Clean Architecture Agent Pack

This guide distills the clean architecture guardrails we follow when building the local-first Patient App. Treat it as the companion to `ARCHITECTURE.md` and keep it in sync whenever we adjust layering, data flow, or testing practices.

## Mission
- Deliver a local-first experience that works fully offline. Cloud backup remains optional, end-to-end encrypted with AES-GCM, and never transports plaintext.
- Any AI or LLM assistance is strictly opt-in. The patient must grant explicit consent before we transmit sensitive artefacts or derived data.
- Ship incremental, testable changes with clear documentation so future contributors can reason about the system safely.

## Dependency Rule
All dependencies point inward:
`Frameworks & Drivers -> Interface Adapters -> Application (Use Cases) -> Domain (Entities/Value Objects)`.
Closer to the center means higher stability. Never import outward across layers.

## Layer Responsibilities
- **Domain / Entities**
  - Own business rules, invariants, and rich behaviour.
  - Remain free of UI, HTTP, persistence, annotations, or serialization helpers.
  - Change only when business rules change.
- Example: `RecordEntity` now validates non-empty type/title fields and chronological timestamps via constructor checks with dedicated unit tests; `AutoSyncStatus` similarly guards against negative dirty counters or empty device identifiers.
- **Application / Use Cases (Interactors)**
  - Orchestrate scenarios using InputDTO and OutputDTO contracts.
  - Depend only on ports such as repositories or gateways.
  - Contain no business rules; they coordinate entities and collaborate through interfaces.
  - Example: the auto-sync stack now routes Settings toggles, dirty tracking, and lifecycle triggers through `SetAutoSyncEnabled`, `RecordAutoSyncChange`, `MarkAutoSyncSuccess`, and `WatchAutoSyncStatus` use cases so UI widgets never import the Isar repository directly.
  - Example: capture modes now use dedicated gateways (`PhotoCaptureGateway`, `DocumentScanGateway`) plus use cases (`CapturePhotoUseCase`, `CaptureDocumentUseCase`) so prompts, artifact tagging, and draft merging live outside the Flutter widgets.
- **Interface Adapters**
  - Map and translate: controllers/presenters convert Request <-> DTO <-> Response.
  - Repository adapters convert Entities <-> Storage models.
  - Gateways communicate with external services.
- **Frameworks & Drivers**
  - Contain infrastructure details (Flutter UI, Isar persistence, OAuth, HTTP, etc.).
  - Must be replaceable without touching inner layers.

## DTO vs Entity Boundaries
- Default to DTOs for public boundaries (UI, APIs, cross-service contracts) so we can evolve interfaces safely.
- Returning Domain Entities is allowed only for fully internal paths where the team agrees presentation concerns will never leak and performance demands it.
- Hard bans:
  - No annotations, serialization helpers, or UI hooks inside Entities.
  - No Active Record patterns such as `entity.save()`. Always go through repository interfaces and adapters.

## Data Flow
Requests always move through these translation boundaries:
1. UI/HTTP request enters a controller that validates input and builds a RequestModel.
2. The controller maps data into a `UseCase.InputDTO`.
3. The use case executes, invoking Domain Entities to enforce rules and calling ports (repositories/gateways) via interfaces.
4. Adapters map Entities to storage models before persisting them.
5. The use case returns an `OutputDTO`.
6. Presenters/controllers map the `OutputDTO` into a ResponseModel for the caller.

## Testing Expectations
Follow the clean architecture testing pyramid:
- **Domain / Entities**: pure unit tests that cover invariants and rules without I/O.
- **Use Cases**: unit tests with mocked ports. Verify orchestration, entity interactions, and side-effects.
- **Interface Adapters**: contract or integration tests that confirm mapping logic and I/O behaviour.
Avoid pushing business logic into adapter tests; keep rules inside the domain layer.

## Agent Implementation Playbook
Use this workflow when adding features or refactoring:
1. **Use Case**
   - Define InputDTO/OutputDTO and declare required ports.
   - Implement the interactor using only interfaces.
   - Write a unit test with mocks to assert port interactions and outputs.
2. **Domain Entity**
   - Document invariants and encode them as methods or value objects.
   - Keep the implementation free of infrastructure concerns.
   - Add pure unit tests that cover rule enforcement.
3. **Adapter / Repository**
   - Implement adapters that satisfy the ports, mapping between Entities and storage/transport models.
   - Verify the mapping with contract tests (serialization/deserialization, DB persistence, HTTP payloads).
4. **Documentation & Hygiene**
   - Update architecture and process docs with any new behaviours.
   - Run analyzers/tests (with approval when required) and log manual or automated checks in `TESTING.md`.

## Red Flags
Pause the work and realign if you notice:
- Domain Entities importing UI, HTTP, ORM, or annotation packages.
- Use Cases holding business rules that belong to Entities.
- Controllers or services bypassing ports to talk directly to the database.
- Active Record patterns or storage logic leaking into Entities.
- Cross-feature imports that skip public module APIs.
- Large untestable changes without clear verification steps.

## Project Layout Alignment
Our repository mirrors the layers under each feature:
```
lib/features/<feature>/
  domain/        # entities, value objects, repository interfaces
  application/   # use cases, ports
  adapters/      # controllers, presenters, repo impls, mappers
  ui/            # Flutter widgets/screens (framework layer)
```
Cross-cutting helpers belong in `lib/core/` only when they serve multiple features without breaking the dependency rule. Keep module APIs minimal and communicate via interfaces so features stay composable.
