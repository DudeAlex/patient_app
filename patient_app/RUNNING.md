# Running the App

This guide lists the exact commands to run the app on Web (Chrome) and Android emulator on Windows.

Prerequisites
- Flutter stable >= 3.32, Android Studio with SDKs/Emulator
- Windows: run an elevated PowerShell (Run as Administrator) OR enable Developer Mode (for symlink support)

Open a terminal (Administrator) and cd into the project:
- `cd "C:\Users\<YOU>\OneDrive\Desktop\AI Projects\Patient\patient_app"`

Web (Chrome)
- `flutter run -d chrome`
- Optional: Web Google Sign-In client ID
  - `flutter run -d chrome --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID`

Android Emulator
1) Create/start AVD (Android Studio → Device Manager) or:
   - `flutter emulators`
   - `flutter emulators --launch Pixel_9a`
   - `flutter devices` (note `emulator-5554` or similar)
2) Build and run:
   - `flutter clean`
   - `flutter pub get`
   - `dart run build_runner build --delete-conflicting-outputs`
   - `flutter run -d emulator-5554`

Google Sign-In (Android)
1) Google Cloud Console
   - Enable "Google Drive API"
   - OAuth consent screen (External)
   - OAuth Client ID → Android
     - Package: `com.example.patient_app`
     - Debug SHA-1: `keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore -storepass android -keypass android`
2) In app: Settings → Sign in → Backup/Restore

Notes
- NDK: `android/app/build.gradle.kts` pins `ndkVersion = "27.0.12077973"`
- Web build hides Drive backup (browser filesystem limitations)

PowerShell Helper (Android)
- From `patient_app/`: `.\u200brun_pixel.ps1 -EmulatorId Pixel`
- With Google Sign-In (Android server client id):
  - `.\u200brun_pixel.ps1 -EmulatorId Pixel -ServerClientId YOUR_WEB_CLIENT_ID`
- Flags:
  - `-SkipBuildRunner` to skip `build_runner` codegen (faster subsequent runs)

Debugging
- Emulator type: use a Google Play image (Device Manager shows Play badge). Add a Google account in Settings → Passwords & accounts.
- Android sign-in: google_sign_in v7 requires a server client ID (the Web client ID). Run with:
  - Do not wrap the client id in quotes when using PowerShell.
  - `flutter run -d <device> --dart-define=GOOGLE_ANDROID_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID`
  - Optional: `--dart-define=GOOGLE_AUTH_DEBUG=true` for verbose auth logs (default true)
  - Project quick command (PowerShell example):
    - `flutter run -d emulator-5554 --dart-define=GOOGLE_ANDROID_SERVER_CLIENT_ID=283237214247-8qs81ij8r4tg3n9upg2v6ikr4mrjhv0m.apps.googleusercontent.com`
- Logs: the app prints `[Auth] ...` logs during initialization, interactive sign-in, and header fetching. Look for messages like `serverClientId must be provided on Android`.
- In-app: Settings → Run Auth Diagnostics to exercise lightweight auth, interactive picker, and header requests; results are dialog + console logs.
- OAuth setup: ensure Drive API enabled, consent screen configured, Android client (package `com.example.patient_app`, correct debug SHA-1), and a Web client (used as server client ID).
- OneDrive locks: if builds fail or files are locked, pause OneDrive or move the project outside OneDrive.
- Reset state: uninstall the app on the emulator or clear app data; then rerun.

AI-Assisted Companion (Preview)
- The opt-in AI workflow uses Together AI (Llama 70B, Apriel) for text/image understanding.
- Keep the app in local-only mode unless the user provides informed consent.
- When integration lands, expect to supply a secret (e.g., `TOGETHER_API_KEY`) via secure storage or a proxy service; never commit keys to the repo.
- Offline behavior should fall back to manual entry; queued AI jobs will retry once connectivity returns.
- See `AI_ASSISTED_PATIENT_APP_PLAN.md` for the current integration roadmap.
