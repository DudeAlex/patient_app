Status: ACTIVE

# Vision: Universal Life Companion

## Core Idea
- Evolve from health app to universal personal information system spanning any life area.

## Principles
- Flexibility over prescription; user chooses domains and structure.
- Reuse existing code/data; smooth migration, no rewrites.
- Unified core, domain-specific experiences; AI assists with organization/discovery/insight.
- Simple base UX with progressive capability; privacy and user control first.

## Architecture Implications
- Domain-agnostic core: items, relationships, search, AI layer, sync/storage.
- Pluggable domains (health, notes, projects, contacts, finance, learning, etc.).
- Shift: records -> flexible items; medical categories -> user-defined spaces; backup -> personal data platform.
- Foundations reused: Isar, attachments, search, sync, capture, design system, auth.

## AI Strategy
- Input processing (voice/text/image -> structure), organization/search, insights, adaptive UI.
- Consent-gated; offline-first with queued work when offline.

## UX Vision
- Personal space for capturing/organizing any info; connections visible; context-aware insights.
- Progressive onboarding: pick spaces, capture naturally, AI suggests structure, expand over time.
- Cross-domain intelligence: connections, context, patterns, reminders, insights.

## Migration Path
- Phase 1: generalize data models, categories, AI layer for multi-domain.
- Phase 2: add domain templates; enable/disable per user.
- Phase 3: personalization with user-defined domains/fields; AI learns preferences.
- Phase 4: mature platform with ecosystem/templates and advanced AI.

## Success Criteria
- Works for any person; smooth transition for existing users.
- New domains added without rewrites; AI understands cross-domain context.
- Feels adaptive, private, and simple while powerful.
