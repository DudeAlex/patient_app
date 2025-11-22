## Universal Life Companion (formerly Patient App)

> **Vision**: A universal personal information system that helps you collect, organize, and understand the important information in your life—from health and finance to education and creative projects. See [VISION.md](./VISION.md) for the complete vision.

Local-first personal information system. Mobile stores data on-device (Isar), with optional encrypted backup to Google Drive App Data. Web build runs in Chrome with limited backup (disabled by default).

-

- Features
- **Universal Spaces System**: Organize different life areas (Health, Education, Home & Life, Business, Finance, Travel, Family, Creative) in separate spaces with distinct visual identities, categories, and records. Create custom spaces for unique needs. Switch between spaces seamlessly with space-specific filtering, search, and statistics.
- Local storage with Isar (encrypted backup archive, on-device DB not encrypted yet)
- Attachments folder for files (mobile only at this stage)
- Settings screen with a profile hub (account status, manual “Backup now”, Wi-Fi/ethernet cadence presets, appearance controls, AI consent preview, backup-key portability placeholder) plus Google sign-in, Drive backup/restore, and auto backup toggle (mobile — background backups now respect the selected cadence preset: 6h/12h/daily/weekly/manual, always gated to Wi-Fi/ethernet connections, with exponential backoff on failures and the ability to disable auto sync entirely from Settings)
- Planned refinements to the profile hub include wiring the AI consent toggle end-to-end and adding backup-key export/import options (passphrase/QR) so patients manage essentials without extra navigation
- Settings caches the signed-in account to avoid re-showing the Google sign-in sheet when reopening the screen
- Shared `google_drive_backup` package provides reusable Google auth + encrypted Drive backup helpers
- In-app Auth Diagnostics (runs sign-in and header checks; logs safe details)
- Web build boots the app and hides backup/restore (browser sandbox)
- Records list with search (title + notes) and load-more pagination, filtered by current space
- Multi-modal "Add Record" flow (photo with on-device retake checks, baseline document scanning with enhanced previews + clarity prompts, voice dictation capture, keyboard entry, file upload from device storage, Gmail label import) with space-specific categories
- Attachments saved and displayed: photos, scans, audio, uploaded files (PDF/images) with metadata (file size, duration, timestamps, page counts, MIME types)
- Dual operating modes: local-only storage by default, opt-in AI-assisted companion (Together AI: Llama 70B text, Apriel image) for extraction, organization, and encouragement
- Compassionate companion experience with contextual follow-ups, safety hints, and morale support (design underway)
- AI summaries (v1): optional, consent-gated summaries for Information Items. Fake provider enabled by default; remote provider placeholder present but requires backend wiring. Summaries are short (≤120 words) with up to 3 action hints.
- Support network & emergency contacts for quick outreach (design underway)
- Planned phone-based vitals capture (camera-based pulse and connected-cuff blood pressure) with patient consent
- Multilingual UX with focus on English, Russian, and Central Asian languages (localization pipeline planned)

### Universal Information Concept

The app has evolved from a health-focused tool into a flexible personal information system. Instead of being limited to health records, you can now organize any area of your life:

- **Spaces**: Each space represents a distinct life area (e.g., Health, Education, Business) with its own icon, color gradient, and categories
- **Default Spaces**: Choose from 8 pre-configured spaces covering common life areas, each with relevant categories
- **Custom Spaces**: Create your own spaces for unique needs with personalized icons, colors, and categories
- **Space Switching**: Easily switch between active spaces to view different areas of your life
- **Space-Specific Data**: Records, categories, search, and statistics are all scoped to the current space
- **Onboarding**: First-time users select their initial spaces through a guided 3-step onboarding flow
- **Backward Compatibility**: All existing health records continue to work seamlessly in the Health space

Tech Stack
- Flutter (Material 3) with custom gradient-based design system
- Isar + codegen
- Google Sign‑In (v7 API) + Google Drive v3
- AES‑GCM backup encryption

Design System
- Modern gradient-based UI (blue → purple → pink)
- Reusable components (gradient headers, buttons, category badges)
- 3D card effects with touch animations
- Category-specific color schemes for health records
- Optimized RecordsHomeModern with performance-first design:
  - Removed expensive animations for smooth 60fps scrolling
  - 3-line compact card layout with reduced spacing
  - RepaintBoundary optimization for list rendering
  - Comprehensive performance monitoring (render time, scroll, memory)
- See `docs/DESIGN_SYSTEM.md` for complete documentation
- View in app: Settings → View Design Showcase

Project Layout
- `lib/ui/` app shell and screens
- `lib/core/` database/storage helpers shared across features
- `lib/features/records/` Isar models + repo (CRUD wiring to UI pending)
- `packages/google_drive_backup/` reusable Google Drive backup + auth library (consumed by the app)
- Contributors and AI agents: start every session with `AI_AGENT_START_HERE.md` to review the must-read guidance before making changes.
- Specs: see `SPEC.md` for detailed, living requirements
- Strategy & compassionate AI roadmap: see `AI_ASSISTED_LIFE_COMPANION_PLAN.md`
- Canonical terminology: see `GLOSSARY.md`

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
  - `./tool/run_pixel.ps1 -EmulatorId "Pixel 6 Play" -ServerClientId YOUR_WEB_CLIENT_ID`
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
- Current focus: Multi-modal capture (M5) — photo, scan, voice, file, email input with accessibility-first UX.
- Recently delivered: Auto sync (M4) with Wi-Fi gating, cadence presets, and profile hub; Records CRUD, search, and pagination (M2/M3).
- In discovery: AI companion integration (M6) with Together AI for extraction and wellness guidance.
- Full roadmap (support network, localization, wellness companion): see `TODO.md` for the living milestones.


Contributing & Process
- Please make small, incremental changes and validate manually after each step.
- Add clear comments to any new or modified code to explain intent.
- Keep docs in sync: update README, RUNNING, ARCHITECTURE, SYNC, TROUBLESHOOTING, and TODO with relevant changes.
- Stage all patient-facing strings for localisation (`gen_l10n` ready). Avoid hard-coded prose inside widgets or controllers.
- Highlight AI-extension points when adding features, and prefer interface-based hooks so AI services can plug in cleanly.
- See `AGENTS.md` for the full set of repo guidelines for LLMs and contributors.
- Write code with Clean Code principles in mind: descriptive names, single-purpose functions, and straightforward control flow.
- Balance OOP and functional techniques: keep module APIs encapsulated, apply SOLID where it clarifies responsibilities, and prefer immutable data/pure helpers for state transformations when practical.
- When drafting a new milestone or feature brief, copy `docs/templates/milestone_plan_template.md` so the “Must-Read References” (clean architecture guide + refactor plan) stay linked in every plan.
- App boot now resolves dependencies via the lightweight `AppContainer` (`lib/core/di`); register new services there instead of creating ad-hoc singletons.
