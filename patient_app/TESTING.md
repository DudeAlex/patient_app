# Manual Test Log

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
- **Result**
  - Passed. Detail view wiring renders seeded data as expected and provides a clear placeholder for upcoming attachments.
