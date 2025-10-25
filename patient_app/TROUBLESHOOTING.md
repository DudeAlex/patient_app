# Troubleshooting

LLM Development Pace & Process
- Do not add lots of code at once; prefer small, verifiable updates.
- After each change, describe manual validation steps and check the app locally when possible.
- Add clear comments to any new or modified code so maintainers can understand intent.
- Always keep docs in sync: update README, RUNNING, ARCHITECTURE, SYNC, and TODO when behavior changes.
- See AGENTS.md for full guidelines used by this repo.

Windows Symlink / Plugins
- Symptom: "Building with plugins requires symlink support"
- Fix: Run terminal as Administrator OR enable Developer Mode (Settings → For developers)

Emulator Fails to Start
- Ensure CPU virtualization is enabled in BIOS
- Install Android Emulator Hypervisor Driver (SDK Manager → SDK Tools)
- Launch with safer GPU flags:
  - `"$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Pixel_9a -no-snapshot -no-boot-anim -gpu angle_indirect -verbose`

NDK Mismatch
- Symptom: plugins require a newer NDK (27.x)
- Fix: `android/app/build.gradle.kts` sets `ndkVersion = "27.0.12077973"`

"Namespace not specified" for isar_flutter_libs
- Cause: older plugin Gradle file
- Workaround applied during setup by patching plugin cache; re-run build if seen

Google Sign-In Errors
- Android: ensure OAuth client with package `com.example.patient_app` and correct debug SHA-1
- Error: `serverClientId must be provided on Android`
  - Cause: google_sign_in v7 requires a server client id on Android.
  - Fix: create a Web application OAuth client in GCP and run with:
    `flutter run -d <device_id> --dart-define=GOOGLE_ANDROID_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID`
- Error: `GoogleSignInExceptionCode.canceled, [16] Account reauth failed.`
  - Causes (common):
    - Emulator has no Google account signed in or Play services is outdated
    - OAuth consent screen in Testing and your account isn’t added as a Test user
    - Drive API disabled in the GCP project; tokens get rejected when requesting scopes
    - Missing Android OAuth client (package `com.example.patient_app`) with debug SHA-1/SHA-256 in the same project as the Web client
  - Fix checklist:
    - Add Google account on the device: Settings → Passwords & accounts → Add account → Google
    - Open Play Store once, update Google Play services, then reboot the device/emulator
    - Use an AVD with a Google Play system image (Play Store badge)
    - In Google Cloud console:
      - Consent screen: add your account as a Test user
      - Enable Google Drive API in the same project as the Web client ID
      - Create Android OAuth client with package `com.example.patient_app`; add debug SHA-1 and SHA-256
        - Get SHA report: `cd android; .\gradlew signingReport` (PowerShell)
    - If still stuck, clear data: Settings → Apps → Google Play services → Storage → Clear all data → Reboot
  - In-app help: Settings → Run Auth Diagnostics and review `[Auth] [Diag] ...` logs
- Web: pass `--dart-define=GOOGLE_WEB_CLIENT_ID=...` and add localhost origins in GCP

Emulator Performance (Windows)
- Symptom: slow UI, skipped frames, “feels like weak PC”
- Critical: make sure AVD Graphics = Hardware (or Automatic)
- Use a Google Play system image to get full Play Services
- RAM: 4096 MB; Cores: 4; Scale display to 0.5 if needed
- Hypervisor: enable Windows Hypervisor Platform; remove old HAXM
- Defender exclusions (build speed):
  - `C:\src\flutter`, `%LOCALAPPDATA%\Android\Sdk`, `%USERPROFILE%\.gradle`, `%LOCALAPPDATA%\Pub\Cache`, `%USERPROFILE%\.android\avd`, and the project folder

Back Gesture Warning
- Warning: `OnBackInvokedCallback is not enabled ...`
- Fix: add `android:enableOnBackInvokedCallback="true"` to `<application>` in AndroidManifest.xml

OneDrive Interference
- If file lock issues occur, pause OneDrive sync or move project outside OneDrive
