Status: ACTIVE

# Clean Architecture Agent Pack

## Mission
- Local-first, offline-first; backups encrypted (AES-GCM); AI strictly opt-in with consent.
- Ship incremental, testable changes with clear docs.

## Dependency Rule
- Inward-only: Frameworks & Drivers -> Interface Adapters -> Application (Use Cases) -> Domain (Entities/Value Objects).

## Layer Responsibilities
- **Domain**: invariants/rules only; no UI/HTTP/ORM/annotations.
- **Application**: orchestrate via Input/Output DTOs and ports; no business rules in adapters/UI.
- **Adapters**: map DTOs/entities to storage/transport; controllers/presenters translate request/response.
- **Frameworks**: Flutter UI, Isar, OAuth/HTTP; replaceable without touching inner layers.

## DTO vs Entity
- Use DTOs at boundaries; entities stay internal. No serialization/UI hooks inside entities; no Active Record.

## Data Flow
1. Controller builds RequestModel -> UseCase.InputDTO
2. Use case calls entities + ports
3. Adapters persist/communicate
4. Use case returns OutputDTO -> presenter/response

## Testing Pyramid
- Domain unit tests; use-case tests with mocked ports; adapter contract/integration tests.

## Agent Playbook
1. Define use case DTOs + ports; unit test interactions.
2. Encode entity invariants; pure unit tests.
3. Implement adapters; contract tests for mapping/persistence/HTTP payloads.
4. Update docs; run analyzers/tests; log validation in TESTING.md.

## Red Flags
- Entities importing UI/HTTP/ORM/annotations.
- Use cases holding business rules that belong in entities.
- Controllers/services bypassing ports to hit DB.
- Active Record patterns; cross-feature imports outside public APIs.
- Large untestable changes without verification.

## Project Layout
```
lib/features/<feature>/
  domain/
  application/
  adapters/
  ui/
```
Cross-cutting helpers in `lib/core/` only when they obey the dependency rule. Modules communicate via interfaces so features stay composable.
