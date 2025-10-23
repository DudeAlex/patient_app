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

Debugging
- Emulator type: use a Google Play image (Device Manager shows Play badge). Add a Google account in Settings → Passwords & accounts.
- Android sign-in: google_sign_in v7 requires a server client ID (the Web client ID). Run with:
  - `flutter run -d <device> --dart-define=GOOGLE_ANDROID_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID`
- Logs: the app prints `[Auth] ...` logs during initialization, interactive sign-in, and header fetching. Look for messages like `serverClientId must be provided on Android`.
- OAuth setup: ensure Drive API enabled, consent screen configured, Android client (package `com.example.patient_app`, correct debug SHA‑1), and a Web client (used as server client ID).
- OneDrive locks: if builds fail or files are locked, pause OneDrive or move the project outside OneDrive.
- Reset state: uninstall the app on the emulator or clear app data; then rerun.
