Status: LEGACY

# M4 - Auto Sync Plan (Completed 2025-11-09)

- Goal: background Drive backup with cadence presets and profile hub controls.
- Deliverables:
  - Dirty tracking + `AutoSyncStatus` domain entity; `SyncStateRepository` port + Isar adapter.
  - Use cases: toggle, record dirty change, mark success, promote routine changes, read/watch status.
  - UI: Settings profile hub with manual backup, cadence presets (6h/12h/daily/weekly/manual), toggle, display prefs, AI consent placeholder, key portability entry point.
  - Runner/coordinator/dirty tracker wired to use cases; Wi-Fi/ethernet gating; cadence spacing (min 6h); exponential backoff on failures.
- Follow-ups: conflict banner messaging (M4.1), key export/import (production blocker), AI consent wiring (M6).
