Status: ACTIVE

# Project Working Rules

- Use docs/core for must-read guidance, docs/modules for feature-specific references, and docs/legacy for historical context; prefer updating existing docs.
- Active plans and task lists live under `.kiro/`; read `.kiro/specs/*/tasks.md` at the beginning of each work session to know the current stage; do not modify `.kiro` unless explicitly instructed.
- Follow clean architecture rules and respect module boundaries; keep entities free of framework code and route orchestration through use cases.
- Before large refactors or architecture-impacting changes, propose a plan and validate incrementally.
