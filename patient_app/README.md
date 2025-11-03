## Patient App (Flutter)

Local-first personal health records app. Mobile stores data on-device (Isar), with optional encrypted backup to Google Drive App Data. Web build runs in Chrome with limited backup (disabled by default).

-

- Features
- Local storage with Isar (encrypted backup archive, on-device DB not encrypted yet)
- Attachments folder for files (mobile only at this stage)
- Settings screen with Google sign-in and Drive backup/restore (mobile)
- Settings caches the signed-in account to avoid re-showing the Google sign-in sheet when reopening the screen
- Shared `google_drive_backup` package provides reusable Google auth + encrypted Drive backup helpers
- In-app Auth Diagnostics (runs sign-in and header checks; logs safe details)
- Web build boots the app and hides backup/restore (browser sandbox)
- Records list with search (title + notes) and load-more pagination (new in M3)
- Multi-modal "Add Record" flow (photo with on-device retake checks, baseline document scanning with enhanced previews + clarity prompts, voice dictation capture, keyboard, file upload, Gmail label import)
- Dual operating modes: local-only storage by default, opt-in AI-assisted companion (Together AI: Llama 70B text, Apriel image) for extraction, organization, and encouragement
- Compassionate companion experience with contextual follow-ups, safety hints, and morale support (design underway)
- Support network & emergency contacts for quick outreach (design underway)
- Planned phone-based vitals capture (camera-based pulse and connected-cuff blood pressure) with patient consent
- Multilingual UX with focus on English, Russian, and Central Asian languages (localization pipeline planned)

Tech Stack
- Flutter (Material 3)
- Isar + codegen
- Google Sign‑In (v7 API) + Google Drive v3
- AES‑GCM backup encryption

Project Layout
- `lib/ui/` app shell and screens
- `lib/core/` database/storage helpers shared across features
- `lib/features/records/` Isar models + repo (CRUD wiring to UI pending)
- `packages/google_drive_backup/` reusable Google Drive backup + auth library (consumed by the app)
- Contributors and AI agents: start every session with `AI_AGENT_START_HERE.md` to review the must-read guidance before making changes.
- Specs: see `SPEC.md` for detailed, living requirements
- Strategy & compassionate AI roadmap: see `AI_ASSISTED_PATIENT_APP_PLAN.md`

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
   - Prefer a Google Play system image so you can add a Google account (required for sign‑in)
   - Sign into a Google account inside the emulator (Settings → Passwords & accounts)
2) In elevated PowerShell:
   - `cd "C:\\Users\\<you>\\OneDrive\\Desktop\\AI Projects\\Patient\\patient_app"`
   - `flutter clean`
   - `flutter pub get`
   - `dart run build_runner build --delete-conflicting-outputs`
   - `flutter emulators --launch <emulator_id>` (e.g., `Pixel_9a`)
   - `flutter devices` (note device id, e.g., `emulator-5554`)
   - `flutter run -d emulator-5554`
   - For Google Sign‑In (Android): add your Web OAuth client id (no quotes in PowerShell):
     `flutter run -d emulator-5554 --dart-define=GOOGLE_ANDROID_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID`
   - Optional verbose auth logs:
     add `--dart-define=GOOGLE_AUTH_DEBUG=true` (default true; set false to reduce logs)

One‑command helper (PowerShell)
- From `patient_app/` you can use the helper script:
  - `./run_pixel.ps1 -EmulatorId "Pixel 6 Play" -ServerClientId YOUR_WEB_CLIENT_ID`
  - Re‑runs after first build: add `-SkipBuildRunner` for faster startup

Android Build Notes
- `android/app/build.gradle.kts` pins `ndkVersion = "27.0.12077973"` to satisfy plugin requirements.
- If you see a “namespace not specified” error for `isar_flutter_libs`, run the build again. The cache was patched during setup.

Google OAuth Setup (Android)
1) Google Cloud Console:
   - Enable “Google Drive API”
   - Configure OAuth consent screen (External)
   - Create OAuth Client IDs:
     - Android client (Package name: `com.example.patient_app`; Debug SHA‑1: `keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore -storepass android -keypass android`)
     - Web application client (this is used as the Android server client id)
2) Run on Android with the server client id (the Web client id):
   - `flutter run -d <device_id> --dart-define=GOOGLE_ANDROID_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID`
3) In app: Settings → Sign in → Backup/Restore

Auth Diagnostics
- In the app: Settings → Run Auth Diagnostics
- It exercises:
  - Lightweight auth (attempt without UI)
  - Interactive authenticate (account chooser)
  - Authorization headers for `email` and `drive.appdata`
- All output is safe (no tokens) and printed as `[Auth] [Diag] ...` in logs, plus shown in a dialog.

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
  - If you see `GoogleSignInExceptionCode.canceled, [16] Account reauth failed.`, see TROUBLESHOOTING.md for a full checklist (Play services/account, consent screen test users, Drive API enabled, Android client SHA‑1/256).

Notes
- Android manifest enables back gesture API (`android:enableOnBackInvokedCallback="true"`).
- The app sanitizes `GOOGLE_ANDROID_SERVER_CLIENT_ID` to avoid accidental surrounding quotes from shells.
- Manual test history is tracked in `TESTING.md`.

Development Scripts
- Update codegen after model changes:
  `dart run build_runner build --delete-conflicting-outputs`

 Status & Next Steps
- Immediate focus: Auto sync (M4) — add Wi-Fi-friendly backup triggers and patient feedback.
- Recently delivered: Records CRUD, search, and pagination (M2/M3).
- In discovery: multi-modal Add Record flow and opt-in AI companion (Together AI).
- Full roadmap (support network, localisation, wellness companion): see `TODO.md` for the living milestones.


Contributing & Process
- Please make small, incremental changes and validate manually after each step.
- Add clear comments to any new or modified code to explain intent.
- Keep docs in sync: update README, RUNNING, ARCHITECTURE, SYNC, TROUBLESHOOTING, and TODO with relevant changes.
- Stage all patient-facing strings for localisation (`gen_l10n` ready). Avoid hard-coded prose inside widgets or controllers.
- Highlight AI-extension points when adding features, and prefer interface-based hooks so AI services can plug in cleanly.
- See `AGENTS.md` for the full set of repo guidelines for LLMs and contributors.
