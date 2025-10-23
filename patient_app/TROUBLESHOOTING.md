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
- Web: pass `--dart-define=GOOGLE_WEB_CLIENT_ID=...` and add localhost origins in GCP

OneDrive Interference
- If file lock issues occur, pause OneDrive sync or move project outside OneDrive
