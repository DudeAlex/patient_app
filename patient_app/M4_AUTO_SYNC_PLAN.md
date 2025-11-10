# M4 - Auto Sync Plan

Auto sync ensures local changes are backed up to Google Drive App Data automatically, while keeping patients in control and mindful of data usage. Work is split into a minimal MVP and future enhancements.

## MVP Scope (Release Now)

### 1. Requirements & Constraints
- [x] Review README/TODO/SPEC backup sections to confirm expectations (auto sync runs only when signed in, reuses the encrypted Drive backup flow, and surfaces SnackBar errors when failures occur).
  - Notes: default to Wi-Fi, honor patient consent toggles, queue retries on recoverable failures.
- [x] Default to Wi-Fi-only auto sync; defer when on cellular unless the patient opts in.
- [x] Define a lightweight "critical vs routine" rule so only critical changes trigger auto sync; queue routine notes until a critical change or manual request.
  - Critical triggers: saving or deleting a record of type `visit`, `lab`, or `med`, any attachment add/remove, or a manual "backup now" request.
  - Routine backlog: `note`-only edits accumulate until a critical trigger fires or the patient runs a manual backup.
- [x] Document clearly that patients can disable auto sync entirely from Settings when they prefer manual backups only.
- [x] Flesh out a minimal patient profile/settings hub so patients can see account status, tap “Backup now,” adjust cadence presets (6h/12h/daily/weekly/manual), choose display preferences (light/dark/auto theme plus small/medium/large text), and manage backup-key portability (patient passphrase/mnemonic, offline QR/file export, or platform secure backup) before production. (Cadence + portability still store intent only until scheduler/key workflows land.)

### 2. Track Dirty State
- [x] Extend repository/state to flag dirty changes whenever records mutate.
  - `AutoSyncDirtyTracker` now wraps the record save/delete flows and manual backup success clears counters via `MarkAutoSyncSuccessUseCase`.
- [x] Persist dirty metadata in Isar (`SyncState`) so the flag survives restarts.

### 3. Sync Trigger Mechanics
- [x] Hook into app lifecycle (resume/exit) to check dirty state and launch backup when Wi-Fi + consent conditions are met.
  - [x] Introduced `AutoSyncCoordinator` to watch lifecycle resume events and emit pending-change diagnostics (backup invocation still TODO).
  - [x] Connected resume trigger to an `AutoSyncRunner` that performs background Drive backups when auto sync is enabled and critical dirty changes exist (now gated by `ConnectivityAutoSyncNetworkInfo` to require Wi-Fi/ethernet).
  - [x] Added a minimum interval throttle so background backups run at most once every six hours, batching critical text edits without resending the full archive repeatedly.
  - [x] Shift default cadence to weekly background backups with patient-configurable overrides (requires refactoring the current resume-trigger model).
    - Cadence selections are now persisted in `SyncState`, Settings writes through `SetAutoSyncCadenceUseCase`, manual mode disables automatic runs entirely, and the runner uses the selected interval instead of the fixed six-hour throttle.
- [x] Prevent overlapping runs and honour manual toggles (backup enabled + signed in).

### 4. Backup Orchestration
- [x] Wrap the existing manual backup call in a service capable of silent execution and reporting status back to UI/state (see `AutoSyncBackupService`, now shared by Settings + runner).
- [x] Handle failures gracefully (network/auth) and schedule a retry with basic exponential backoff (runner records failures and delays retries 5m→2h while logging context).

### 5. Patient Feedback
- [x] Surface gentle status cues (snackbar/toast/log) when auto sync succeeds or fails (manual “Backup now” shows success/failure snackbars; auto runner logs successes and backoff schedules).
- [x] Add a Settings switch to enable/disable auto sync and display the last successful sync timestamp.

### 6. Testing & Documentation
- [x] Add manual scenarios to `TESTING.md` (dirty change + resume, failure then retry, manual toggle).
- [x] Update README/TODO after shipping the MVP noting limitations (Wi-Fi only, triggers on critical changes, batch routine notes).

## Deferred Enhancements (Future Releases)
- Advanced safety nets: expose a “Recently Deleted” view using `deletedAt`, retain the previous backup file (`patient-backup-v1-prev.enc`) for rollback, and document recovery flows.
- Smarter scheduling: battery/network awareness, true incremental uploads, background isolates.
- Explicit queue management for routine changes (e.g., patient can “sync now” or see queued items).
- Cellular auto-sync opt-in (with data usage warnings) once the MVP proves reliable.
