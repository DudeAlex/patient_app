# M3 - Retrieval & Search Foundation Breakdown

This plan expands the M3 milestone into incremental slices so we can introduce structured search and retrieval with confidence.

## 1. Clarify Retrieval Requirements
- [x] Re-read TODO/M3 milestone notes: initial scope is structured filters (type/date/tag, keyword) with hooks for future OCR/indexing and saved views.
- [x] Inventory gaps: need Isar indexes on `type`, `date`, `tags`, `title`, `text`; attachments/OCR deferred to later phases. Open questions:
  - How to handle multi-tag queries (intersection vs union)?
  - Should free-text search cover both `title` and `text` immediately?
  - Pagination requirements once result sets grow?

## 2. Prepare Isar Indexing & Queries
- [ ] Add/update indexes to support date ordering and case-insensitive text search across `title` + `text`.
- [ ] Extend `RecordsRepository` with:
  - [ ] Paged `recent` query (`offset` + `limit`) for load-more lists.
  - [ ] Simple text search (`contains` on title/notes) with pagination.

## 3. Search State & Repository Abstractions
- [ ] Enhance `RecordsHomeState` (or companion notifier) with search text, results list, and pagination state.
- [ ] Ensure CRUD operations invalidate/refresh search results when needed.

## 4. UI Adjustments
- [ ] Add a search field atop the home screen; executing search filters the list.
- [ ] Provide a “Load more records” button or auto-fetch when scrolled near the end (keeps vertical scrolling familiar).
- [ ] Show empty/error states for search results.

## 5. Testing & Performance
- [ ] Add manual scenarios to `TESTING.md` for:
  - Search by title/notes keyword (e.g., “blood test”).
  - Load-more behavior (multiple batches).
- [ ] Validate query performance with seeded data (target under ~50ms per fetch on emulator).
- [ ] Document limitations (no tag filters yet, attachments/OCR deferred) and list follow-ups for later milestones.

## 6. Documentation & Follow-ups
- [ ] Update README/TODO once search + pagination ship.
- [ ] Capture deferred tasks: multi-filter UI, attachment/OCR indexing, saved views.
