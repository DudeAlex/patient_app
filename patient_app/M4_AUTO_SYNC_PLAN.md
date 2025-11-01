# M4 - Auto Sync Breakdown

Auto sync ensures local changes are backed up to Google Drive App Data automatically, while keeping users informed. We'll deliver this in incremental, testable steps.

## 1. Requirements & Constraints
- [ ] Review README/TODO/SPEC sections touching backup/restore to collect expectations for auto sync (when to trigger, error handling, consent).
- [ ] Capture any open questions: frequency limits, battery/network constraints, and UI messaging.
- [x] Default to Wi-Fi-only auto sync; defer when on cellular unless user opts in (note copy for Settings).
- [ ] Define what counts as a “critical” change (e.g., attachments, visits) vs routine notes and only auto-sync on critical events; queue routine changes until threshold/manual request.
- [ ] Plan for safety nets: keep soft-deleted records (`deletedAt`), retain previous backup file on Drive for rollback, and surface recovery guidance in docs/UI.

## 2. Track Dirty State
- [ ] Extend `RecordsHomeState`/repository to flag when local data changes (add/edit/delete) and expose a simple dirty counter.
- [ ] Persist dirty metadata in Isar (e.g., update `SyncState` model) so state survives restarts.

## 3. Sync Trigger Mechanics
- [ ] Add an app lifecycle hook (resume/exit) to check dirty state and kick off backup if conditions are met.
- [ ] Ensure triggers respect user consent (backup enabled + signed in) and avoid overlapping sync runs.

## 4. Backup Orchestration Enhancements
- [ ] Wrap the existing manual backup call in a reusable service that can run silently, report status, and provide callbacks for UI.
- [ ] Handle failure scenarios gracefully (network, auth) and schedule retry with exponential backoff.

## 5. User Feedback
- [ ] Surface non-intrusive status cues (snackbar/toast/log) when auto sync runs or fails.
- [ ] Provide a settings switch to enable/disable auto sync and a way to review last sync timestamp.

## 6. Testing & Documentation
- [ ] Add manual scenarios to `TESTING.md` (dirty change + app resume, failure -> retry).
- [ ] Update README/TODO once auto sync MVP ships, noting limitations (e.g., only on resume, not background daemon).
- [ ] Record follow-ups for advanced scheduling (battery/network awareness, background isolates).
