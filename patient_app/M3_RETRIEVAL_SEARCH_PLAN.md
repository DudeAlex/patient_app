# M3 - Retrieval & Search Foundation Breakdown

This plan expands the M3 milestone into incremental slices so we can introduce structured search and retrieval with confidence.

## 1. Clarify Retrieval Requirements
- [x] Re-read TODO/M3 milestone notes: initial scope is structured filters (type/date/tag, keyword) with hooks for future OCR/indexing and saved views.
- [x] Inventory gaps: need Isar indexes on `type`, `date`, `tags`, `title`, `text`; attachments/OCR deferred to later phases. Open questions:
  - How to handle multi-tag queries (intersection vs union)?
  - Should free-text search cover both `title` and `text` immediately?
  - Pagination requirements once result sets grow?

## 2. Prepare Isar Indexing & Queries
- [ ] Add required Isar indexes (type/date/tag/title/text) and regenerate code.
- [ ] extend `RecordsRepository` with query builders for:
  - [ ] Type/date range filtering.
  - [ ] Text search (initial simple `contains`/`startsWith`) with pagination.
  - [ ] Tag intersection support.

## 3. Search State & Repository Abstractions
- [ ] Introduce `RecordsSearchState` (ChangeNotifier/Riverpod equivalent) that holds filters, executes queries, and exposes loading/error/results.
- [ ] Integrate with existing `RecordsHomeState` (shared repository) to reuse caching and listen for CRUD updates.

## 4. UI Exploration & Stubs
- [ ] Add search entry point to the home screen (search icon or persistent field).
- [ ] Create a temporary search sheet/page with inputs for text, type filter, and date range.
- [ ] Display search results list (reusing existing record tile) and empty/error placeholders.

## 5. Filter Chips & Query Persistence
- [ ] Surface active filters (chips or summary bar) with clear/remove affordances.
- [ ] Remember last-used filters during the session so navigating back and forth preserves state.

## 6. Testing & Performance
- [ ] Add manual scenarios to `TESTING.md` for type/date/tag searches and keyword matches.
- [ ] Validate query performance with seeded data (target sub-50ms per query on emulator).
- [ ] Document any limitations (e.g., text search scope) and plan follow-ups for full-text/OCR integration.

## 7. Documentation & Follow-ups
- [ ] Update README/TODO to reflect the delivered search capabilities and remaining M3 goals (attachment OCR, vector search).
- [ ] Note open questions for the next phase (e.g., attachment indexing, pagination UI, multi-filter UX polish).
