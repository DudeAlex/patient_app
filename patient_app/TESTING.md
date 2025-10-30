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
