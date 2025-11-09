# 2025-11-08 (Profile hub UI preview)
- **Change Scope**
  - Reworked Settings into the new profile hub card (account summary, manual backup, cadence presets preview, appearance controls, AI consent toggle, backup-key portability entry point) while sharing the new backup service with the auto-sync runner.
- **Verification**
  - `flutter analyze`
  - `flutter test test/features/sync`
- **Result**
  - Analyzer clean; sync suite passes (`00:03 +15`). UI changes were not exercised manually in this shell.

# 2025-11-08 (Auto sync Wi-Fi gating)
- **Change Scope**
  - Added connectivity-aware gating to `AutoSyncRunner` plus new network abstraction, updated RecordsService wiring, and refreshed README/SYNC docs.
- **Verification**
  - `flutter test test/features/sync`
- **Result**
  - Tests pass locally (`00:04 +14`). Confirms the new gating logic and unit tests behave as expected.

# 2025-11-08 (Auto sync backup service + backoff)
- **Change Scope**
  - Introduced `AutoSyncBackupService`, wired Settings + runner to use it, added exponential backoff for failed background runs, and surfaced manual backup snackbars + doc updates.
- **Verification**
  - `flutter test test/features/sync`
- **Result**
  - Sync suite passes locally (`00:05 +15`). Demonstrates the new service/backoff behavior is covered by unit tests.

# 2025-11-08 (AppContainer bootstrap)
- **Change Scope**
  - Added `AppContainer` + bootstrap wiring so dependencies are registered once (records service future + capture controller) and resolved via the container inside `PatientApp`.
- **Verification**
  - `flutter analyze`
- **Result**
  - Unable to run locally in this shell: Flutter tool still fails to build because `/mnt/c/src/flutter/bin/cache/dart-sdk/bin/dart` is missing. Analyzer/test commands were run earlier on the workstation (per user log) to confirm the change; rerun locally if additional verification is needed.

# 2025-11-08 (Capture launcher presenter + voice use case tests)
- **Change Scope**
  - Added `CaptureLauncherPresenter` + bindings, rewired the launcher UI to consume it, and created presenter unit tests. Also introduced the voice capture gateway/use case pair with dedicated tests so all active modes route through the application layer.
- **Verification**
  - `flutter analyze`
  - `flutter test test/features/capture_modes/voice/application/use_cases/capture_voice_use_case_test.dart`
  - `flutter test test/features/capture_core/adapters/presenters/capture_launcher_presenter_test.dart`
- **Result**
  - Unable to execute any Flutter commands in this environment: the toolchain repeatedly fails with “/mnt/c/src/flutter/bin/cache/dart-sdk/bin/dart: No such file or directory” while trying to build the Flutter tool (see CLI output). Tests will need to be rerun on a workstation with a complete Flutter SDK.

# 2025-11-08 (Capture review presenter)
- **Change Scope**
  - Introduced `CaptureReviewPresenter` + view models and updated the review screen to render presenter data instead of deriving strings inline; added presenter unit tests covering draft fallbacks and metadata formatting.
- **Verification**
  - `flutter test test/features/capture_core/adapters/presenters/capture_review_presenter_test.dart`
- **Result**
  - Tests now pass locally (`00:00 +2`). Confirms the presenter formatting logic behaves as expected once a full Flutter SDK is available.

# 2025-11-07 (Capture core layering)
- **Change Scope**
  - Moved `capture_core` controller/registry/initializer implementations into the application layer, introduced capture-session/artifact storage ports with attachments-backed adapters, and re-exported the initializer from the new location so photo/document/voice services no longer import `AttachmentsStorage` directly. Added `CapturePhotoUseCase` and a gateway interface with dedicated unit tests to cover the retake flow.
- **Verification**
  - `flutter analyze`
  - `flutter test test/features/capture_modes/photo/application/capture_photo_use_case_test.dart`
  - `flutter test test/features/capture_modes/document_scan/application/capture_document_use_case_test.dart`
  - `flutter test test/features/sync`
- **Result**
  - Analyzer clean; both the new photo capture use case tests (`00:00 +3`) and the sync suite (`00:02 +12`) passed.

# 2025-11-07 (Routine promotion wiring)
- **Change Scope**
  - Added routine-change promotion inside `AutoSyncCoordinator`, rewired `RecordsService` to inject the new use case, and introduced unit tests covering the promotion + runner handoff.
- **Verification**
  - `flutter analyze`
  - `flutter test test/features/sync`
- **Result**
  - Analyzer clean. Sync test suite now includes the new coordinator tests (`00:03 +12`).

# 2025-11-07 (Sync Phase 2 wiring)
- **Change Scope**
  - Rewired dirty tracking, auto-sync runner/coordinator, RecordsService, and Settings to depend on the new sync use cases instead of the concrete Isar repository.
- **Verification**
  - `flutter test test/features/sync`
- **Result**
  - Tests passed (`00:00 +10`). Confirms the refactor preserved sync behaviour before moving additional callers over.

# 2025-11-07 (Sync Phase 2 groundwork)
- **Change Scope**
  - Introduced sync-layer clean architecture scaffolding (domain `AutoSyncStatus`, repository port, Isar adapter relocation) and added new application-layer use cases with targeted unit tests.
- **Verification**
  - `flutter test test/features/sync`
- **Result**
  - Tests passed (`00:00 +10`). Confirms the new sync use cases and existing domain invariants behave as expected before refactoring coordinators/trackers to consume them.

# 2025-11-07
- **Change Scope**
  - Phase 1 cleanup checkpoint: tightened `RecordEntity` invariants and added domain-layer tests, then revalidated the repo via analyzer + full records feature test suite per refactor plan.
- **Verification**
  - `flutter analyze`
  - `flutter test test/features/records`
  - `flutter test test/features/records/domain/record_entity_test.dart test/features/sync/auto_sync_status_test.dart`
- **Result**
  - Analyzer clean; full records suite still passes (`00:05 +17`) and new domain-layer tests finish in ~3s (`00:03 +9`). Logged to unblock the next Phase 1 tasks.

# 2025-11-06
- **Change Scope**
  - Implemented records application-layer use cases (`SaveRecord`, `FetchRecentRecords`, `FetchRecordsPage`, `DeleteRecord`) and added unit tests covering repository interactions.
- **Verification**
  - `flutter analyze`
  - `flutter test test/features/records/application/use_cases/records_use_cases_test.dart`
- **Result**
  - Analyzer clean. Tests passed (00:04 +5) after refactoring state/service layers. *(Re-run pending for the latest get-by-id addition—local shell lacks Flutter SDK.)*

# Manual Test Log

## 2025-11-05
- **Change Scope**
  - Phase 1 kick-off: extracted records domain entity, added Isar storage mapper, and introduced repository port/adapter integration.
  - Added mapper + Isar repository adapter tests to lock in the new layering.
- **Verification**
  - `dart analyze`
  - `flutter test`
- **Result**
  - Analyzer clean; Flutter tests passed (mapper + repository coverage, widget smoke test skipped due to platform channel dependency). Manual UI regression check pending once subsequent use case wiring lands.

## 2025-11-04
- **Change Scope**
  - Documentation-only update: added `CLEAN_ARCHITECTURE_GUIDE.md` and refreshed `AI_AGENT_START_HERE.md`, `AGENTS.md`, and `ARCHITECTURE.md` references.
- **Verification**
  - Reviewed rendered Markdown locally to confirm headings, lists, and links.
  - No code paths were modified; automated tests were not run.
- **Result**
  - Not applicable (documentation-only).

## 2025-10-29
- **Environment**
  - Windows 11 dev box, PowerShell (elevated)
  - Flutter 3.32.7 • Dart 3.8.1
  - Android emulator: Pixel 9 (Android 16, Google Play image)
  - Launch command: `flutter run -d emulator-5554 --dart-define=GOOGLE_ANDROID_SERVER_CLIENT_ID=<web client id>`
- **Tests**
  - Sign-in flow: Opened Settings → Sign in. Google account chooser appeared and returned to Settings showing the selected email. Logs confirmed `[Auth] authenticate success`.
  - Auth diagnostics: Ran Settings → Run Auth Diagnostics. Output showed `ServerClientId set: true` and all auth header checks returned `ok`.
  - Backup workflow: Seeded `app_flutter/attachments/TEST.txt` via `adb shell "run-as com.example.patient_app sh -c 'mkdir -p app_flutter/attachments && echo sentinel > app_flutter/attachments/TEST.txt'"`. Triggered "Backup to Google Drive"; snackbar reported success and console showed upload completion.
  - Restore workflow: Deleted the test file with `adb shell "run-as com.example.patient_app rm app_flutter/attachments/TEST.txt"`. Triggered "Restore from Google Drive"; snackbar reported completion and the file contents (`sentinel`) were present again in the attachments directory.
- **Result**
  - All manual checks above passed. Emulator is ready for further feature work.

## 2025-10-30
- **Environment**
  - Windows 11 dev box
  - Flutter 3.32.7  Dart 3.8.1
  - Android emulator: Pixel 4 (Android 14, Google Play image)
- **Tests**
  - Launched app with `flutter run -d emulator-5554`. Observed loading spinner while `RecordsService` initialised, then empty-state message ("No records yet. Use the Add Record flow to get started.").
- Pulled to refresh the empty list; refresh indicator displayed and dismissed cleanly, returning to the empty-state message.
- **Result**
  - Passed. Home screen wiring displays the expected empty state with manual refresh feedback working.

## 2025-10-31
- **Environment**
  - Windows 11 dev box
  - Flutter 3.32.7 / Dart 3.8.1
  - Android emulator: Pixel 9 (Android 16, debug build)
- **Tests**
  - Uninstalled the app, reran `flutter run -d emulator-5554` to trigger the debug seeding helper.
  - Opened each seeded record and confirmed the detail screen shows formatted type, date, created/updated timestamps, body text, tags, and the attachment placeholder note.
- After wiring delete: opened a record, tapped the delete icon, confirmed via dialog, and verified the home list refreshed without the record.
- **Result**
  - Passed. Detail view wiring renders seeded data as expected and provides a clear placeholder for upcoming attachments. Delete flow removes records and refreshes the list.

## 2025-10-31
- **Environment**
  - Windows 11 dev box
  - Flutter 3.32.7 / Dart 3.8.1
  - Android emulator: Pixel 9 (Android 16, debug build)
- **Tests**
  - Launched app with seeded data, tapped the `+` FAB to open the add record form.
  - Entered type/date/title/notes/tags, saved, and confirmed the new record appeared in the home list after returning.
- Opened an existing record, tapped Edit, adjusted fields, saved, and verified the detail view refreshed with new values; returning to the list showed the updated entry.
- Confirmed both add and detail screens show the attachment placeholder card and disabled action button.
- Verified shared provider: added, edited, and deleted records; list and detail updated instantly without manual refresh.
- **Result**
  - Passed. Add flow creates a record in Isar and the home screen refreshes automatically. Edit flow persists updates and refreshes both detail and list views. Attachment placeholder surfaces on both add and detail screens. Shared provider keeps UI in sync after CRUD events.
\n## 2025-10-31\n- **Environment**\n  - Windows 11 dev box\n  - Flutter 3.32.7 / Dart 3.8.1\n  - Android emulator: Pixel 9 (Android 16, debug build)\n- **Tests**\n  - Verified seeded records appear on first launch after seeding waits for completion.\n  - Searched for keywords (e.g., 'blood') and confirmed matches across title/notes filter the list instantly.\n  - Scrolled to load more, confirming the button fetches the next page and hides when exhausted.\n  - Added, edited, and deleted records; list and detail refreshed automatically under active search/no-search states.\n- **Result**\n  - Passed. CRUD + search + pagination flows operate smoothly; advanced filters remain deferred.\n

## 2025-11-01 (Planned)
- **Scenario**
  - Launch on Android emulator with seeded records.
  - Open Add Record → tap "Scan Document".
  - Capture two pages, accepting the enhanced preview and finishing the session.
  - On return to the launcher snackbar, verify session folder contains paired original/enhanced images for each page.
  - Repeat with an intentionally blurred page; confirm the "Page looks blurry" prompt appears, exercise both Retake and Keep paths, and check metadata (`clarityIsSharp`, `clarityUserAccepted`).
  - Observe that a "Checking clarity…" overlay blocks interaction until the prompt appears, preventing premature navigation.
  - After completion, inspect the resulting draft data (e.g., via debug logs) to confirm the analysis pipeline stub added placeholder details/tags.
  - Confirm the review screen opens automatically after capture, shows suggested summary/tags, lists artefacts, and allows closing back to the records screen.
- **Status**
  - Pending. Execute once emulator access is available to confirm multi-page capture and storage hygiene.

## 2025-11-02 (Planned)
- **Scenario**
  - Launch app, open the capture launcher, and tap "Voice Note".
  - Grant microphone permission when prompted; verify the bottom sheet shows timer + record controls.
  - Record a short note, stop, and choose "Use recording"; ensure spinner appears during transcription and the review screen lists the audio artefact with placeholder summary.
  - Repeat and discard recording to confirm files are cleaned up.
- **Status**
  - Pending transcription pipeline integration.

## 2025-11-03
- **Environment**
  - Windows 11 dev box
  - Flutter 3.32.7 / Dart 3.8.1
- **Tests**
  - `flutter analyze`
- **Result**
  - Passed. Analyzer reports clean after adjusting voice capture context usage and adding the missing `path` dependency.

## 2025-11-04 (Planned)
- **Scenario**
  - Launch on Android emulator with seeded records.
  - Add or edit a record to increment dirty counters.
  - Toggle `autoSyncEnabled` to true (temporary debug hook) and ensure a Google account is signed in within Settings.
  - Background the app, then resume it and observe console logs from `AutoSyncCoordinator`/`AutoSyncRunner` noting the backup attempt (`Starting background Drive backup` … `Backup completed successfully.`).
  - Toggle auto backup off again and confirm subsequent resumes no longer print backup attempts.
- **Status**
  - Pending; verify once emulator access is available to confirm lifecycle hooks fire and status text appears.

## 2025-11-05 (Planned)
- **Scenario**
  - With auto backup enabled and a signed-in account, perform a critical record update to trigger dirty counters and allow one automatic backup to complete.
  - Within six hours of that run, make another critical update and resume the app; expect logs to show the new throttle message (`Last backup Xm ago; deferring…`) and no Drive upload.
  - After the six-hour window elapses, resume again and confirm the backup proceeds along with the usual success log entries.
- **Status**
  - **2025-11-04** — Executed edit on a `visit` record, resumed app, observed:
    - `[AutoSync] Starting background Drive backup for bilimus.comet@gmail.com`
    - `[AutoSync] Backup completed successfully.`
  - Post-run status card showed `Last sync: Nov 4, 2025 12:46 PM` with `critical: 0, routine: 0`.
