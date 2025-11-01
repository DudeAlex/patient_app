# M2 — Records CRUD UI Breakdown

This stage expands milestone M2 into actionable steps so implementation can progress in small, verifiable increments.

## 1. Finalize Data Contracts
- [x] Review existing `Record` fields and confirm required data from `SPEC.md`.
- [x] Publish shared record type constants (`RecordTypes`) and validation helper.
- [x] Note baseline validation rules (required fields, tag/text limits) for use in the form implementation.

## 2. Wire Isar Access in the App Layer
- [x] Expose an async initialization pathway (provider/service) that opens `IsarDatabase`.
- [x] Instantiate `RecordsRepository` and make it available to UI state objects (initial FutureBuilder hook in `PatientApp`).

## 3. Home List Scaffolding
- [x] Introduce temporary `RecordsHomePlaceholder` widget that fetches recent records and shows empty/error states.
- [x] Create minimal `RecordsHomeState` notifier to load recent records via `RecordsRepository.recent`.
- [x] Build the list UI with date/type/title presentation plus an empty-state placeholder.
- [x] Add manual refresh hook (pull-to-refresh plus retry button for errors).

## 4. Record Detail Screen
- [x] Define navigation from the home list into a detail route (stub detail screen loads with selected record).
- [x] Display full text, tags, timestamps, and attachment placeholders.
- [x] Wire a delete/archive action to `RecordsRepository.delete` with confirmation dialog.

## 5. Add/Edit Record Flow
- [x] Route from home FAB to a stub add screen.
- [x] Design the add form layout (type picker, date selector, title, text, tags).
- [x] Implement validation and add-path to Isar (insert with timestamps).
- [x] Support editing: pre-fill form fields, persist updates, and refresh upstream state.

## 6. State Management Pattern
- Choose a state management approach aligned with existing conventions.
- Ensure list/detail screens react to CRUD events without requiring manual reloads.

## 7. Attachments Placeholder
- [x] Surface stub UI elements indicating attachment support is coming.
- [x] Keep save logic ready for attachment integration (avoid schema/UI churn later).

## 8. Testing & Documentation
- Add new manual scenarios to `TESTING.md` (create, edit, delete flows).
- Update README/SPEC/TODO with the delivered Records UI behavior and any new steps.

## 9. Accessibility & Localization Prep
- Verify large-font and screen-reader behavior for new screens.
- Keep copy centralized for future localization (keys/constants where practical).

## 10. QA Checklist Before Closing M2
- Smoke test CRUD flows on emulator/devices and confirm list refresh.
- Validate timestamps populate correctly in Isar.
- Capture follow-up gaps feeding into M3 (search, filters, indexing adjustments).
