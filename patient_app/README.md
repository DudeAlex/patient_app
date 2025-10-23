## Patient App (Flutter)

Local-first personal health records app. Mobile stores data on-device (Isar), with optional encrypted backup to Google Drive App Data. Web build runs in Chrome with limited backup (disabled by default).

-

Features
- Local storage with Isar (encrypted backup archive, on‑device DB not encrypted yet)
- Attachments folder for files (mobile only at this stage)
- Settings screen with Google sign‑in and Drive backup/restore (mobile)
- Web build boots the app and hides backup/restore (browser sandbox)

Tech Stack
- Flutter (Material 3)
- Isar + codegen
- Google Sign‑In (v7 API) + Google Drive v3
- AES‑GCM backup encryption

Project Layout
- `lib/ui/` app shell and screens
- `lib/core/` auth, crypto, backup, sync, db helpers
- `lib/features/records/` Isar models + repo (CRUD wiring to UI pending)
- Specs: see `SPEC.md` for detailed, living requirements

Prerequisites
- Flutter stable ≥ 3.32
- Android Studio (SDKs, Platform Tools, Emulator)
- Windows: symlink support required for plugins
  - EITHER use an elevated PowerShell/terminal (Run as Administrator)
  - OR enable Developer Mode: `start ms-settings:developers`

First Run (Web)
1) From project root:
   - `cd patient_app`
   - `flutter run -d chrome`

First Run (Android Emulator)
1) Create/start an emulator in Android Studio (Pixel, API 34/35 x86_64)
2) In elevated PowerShell:
   - `cd "C:\\Users\\<you>\\OneDrive\\Desktop\\AI Projects\\Patient\\patient_app"`
   - `flutter clean`
   - `flutter pub get`
   - `dart run build_runner build --delete-conflicting-outputs`
   - `flutter emulators --launch <emulator_id>` (e.g., `Pixel_9a`)
   - `flutter devices` (note device id, e.g., `emulator-5554`)
   - `flutter run -d emulator-5554`

Android Build Notes
- `android/app/build.gradle.kts` pins `ndkVersion = "27.0.12077973"` to satisfy plugin requirements.
- If you see a “namespace not specified” error for `isar_flutter_libs`, run the build again. The cache was patched during setup.

Google OAuth Setup (Android)
1) Google Cloud Console:
   - Enable “Google Drive API”
   - Configure OAuth consent screen (External)
   - Create OAuth Client ID → Android
     - Package name: `com.example.patient_app`
     - Debug SHA‑1: run
       `keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore -storepass android -keypass android`
2) Build and run; use Settings → Sign in → Backup/Restore

Google OAuth Setup (Web)
- Create OAuth Client ID → Web application
- Add Authorized JavaScript origins for localhost (Flutter dev server)
- Run with web client id:
  `flutter run -d chrome --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID`
  (Backup/restore is hidden on web by default.)

Backup/Restore
- Mobile (Android/iOS):
  - Exports the entire app documents directory as ZIP, encrypts with AES‑GCM, uploads to Drive App Data as `patient-backup-v1.enc`.
  - Restore decrypts and replaces the local directory contents.
- Web: currently disabled. Can be extended to JSON export/import of records only.

Common Issues
- Symlink/Plugin errors on Windows: use elevated terminal or enable Developer Mode.
- Emulator fails to boot: ensure virtualization + Emulator Hypervisor Driver are enabled; try `-gpu angle_indirect`.
- Google sign‑in errors: verify Android OAuth client (package + SHA‑1) or web client id; ensure internet on emulator.

Development Scripts
- Update codegen after model changes:
  `dart run build_runner build --delete-conflicting-outputs`

Status & Next Steps
- Implement Records CRUD UI (Home/Add/Detail) and wire Isar repo
- Add auto-sync hooks (on resume/exit) using current backup format
- Optional: web JSON backup/restore to Drive appData


Contributing & Process
- Please make small, incremental changes and validate manually after each step.
- Add clear comments to any new or modified code to explain intent.
- Keep docs in sync: update README, RUNNING, ARCHITECTURE, SYNC, TROUBLESHOOTING, and TODO with relevant changes.
- See `AGENTS.md` for the full set of repo guidelines for LLMs and contributors.
