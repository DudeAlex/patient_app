Status: ACTIVE

# Running the App

## Prereqs (Windows)
- Flutter >= 3.32, Android Studio + SDK/Emulator.
- Elevated PowerShell or Developer Mode for symlinks.
- `cd "C:\Users\<YOU>\OneDrive\Desktop\AI Projects\Patient\patient_app"` (adjust path).

## Web (Chrome)
- `flutter run -d chrome`
- Optional Google Sign-In: `flutter run -d chrome --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID` (backup hidden on web).

## Android Emulator
1) Create/launch AVD (Google Play image preferred):
   - `flutter emulators`
   - `flutter emulators --launch Pixel_9a`
   - `flutter devices`
2) Build/run:
   - `flutter clean`
   - `flutter pub get`
   - `dart run build_runner build --delete-conflicting-outputs`
   - `flutter run -d emulator-5554`

### Google Sign-In (Android)
- GCP: enable Drive API; consent screen; OAuth clients:
  - Android: package `com.example.patient_app`, debug SHA-1.
  - Web client (used as server client id).
- Run with server client id (no quotes):  
  `flutter run -d <device> --dart-define=GOOGLE_ANDROID_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID`
- Debug logs: `--dart-define=GOOGLE_AUTH_DEBUG=true` (default true).

## Helper Script (Android)
- From repo: `./tool/run_pixel.ps1 -EmulatorId "Pixel 6 Play" -ServerClientId YOUR_WEB_CLIENT_ID`
- Re-run faster: add `-SkipBuildRunner`.

## Notes / Debugging
- NDK pinned: `android/app/build.gradle.kts` uses `ndkVersion = "27.0.12077973"`.
- Use Google Play AVD with signed-in Google account.
- OneDrive file locks: pause OneDrive or move project outside.
- Reset state: uninstall app or clear data on emulator; rerun.
