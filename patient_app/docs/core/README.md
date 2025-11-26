Status: ACTIVE

# Universal Life Companion (formerly Patient App)

Local-first personal information system with optional encrypted Drive backup and opt-in AI assistance. See `VISION.md` for full vision.

## Core Features
- Spaces system: default 8 spaces (Health, Education, Home & Life, Business, Finance, Travel, Family, Creative) + custom spaces with gradients/icons/categories; space-scoped records/search/stats; onboarding selects initial spaces.
- Records: Isar storage, attachments folder (mobile), records list with search + pagination.
- Settings/Profile hub: Google sign-in, manual "Backup now", auto backup cadence (6h/12h/daily/weekly/manual) with Wi-Fi/ethernet gating + backoff, appearance controls, AI consent placeholder, backup-key portability placeholder; caches signed-in account.
- Backup/Restore (mobile): AES-GCM archive to Drive App Data via `google_drive_backup`; web hides backup UI.
- Multi-modal add: photo (retake checks), document scan (clarity prompts), voice dictation, keyboard, file upload, Gmail label import; space-specific categories.
- Attachments: photos/scans/audio/uploads with metadata (size/duration/timestamps/page count/MIME).
- Modes: local-only by default; AI-assisted (Together AI text/image) optional; AI summaries v1 (≤120 words + ≤3 hints) via fake provider default, remote placeholder pending backend.
- Upcoming: support network/emergency, vitals capture, localization pipeline.

## Tech Stack
- Flutter (Material 3) + gradient design system; Isar + codegen; Google Sign-In v7 + Drive v3; AES-GCM backup.

## Project Layout
- `lib/ui/`: app shell/screens.
- `lib/core/`: shared DB/storage/services/DI.
- `lib/features/records/`: models + repo.
- `packages/google_drive_backup/`: reusable backup/auth.
- Specs: `.kiro/specs/`; steering: `.kiro/steering/`.
- Backend (stage 1 echo): `server/` (`npm start`, http://localhost:3030/api/v1/chat/echo).

## Working rules for agents
- First reads: `docs/core/AI_AGENT_START_HERE.md` and `docs/core/PROJECT_WORKING_RULES.md`.
- Active plans and task lists live under `.kiro/`; read `.kiro/specs/*/tasks.md` at the beginning of each work session to know the current stage.
- Do not modify `.kiro` unless explicitly instructed.

## Prereqs
- Flutter >= 3.32; Android Studio + emulator; Windows: elevated PowerShell or Developer Mode (symlinks).

## Run (Web)
- `flutter run -d chrome`
- Optional: `--dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID` (backup hidden).

## Run (Android Emulator)
1) Create/launch Play AVD; sign into Google account.  
2) `flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs`  
3) `flutter run -d <emulator>` with `--dart-define=GOOGLE_ANDROID_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID` (no quotes).  
4) Debug auth: `--dart-define=GOOGLE_AUTH_DEBUG=true` (default true).

Helper: `./tool/run_pixel.ps1 -EmulatorId "<Play AVD>" -ServerClientId YOUR_WEB_CLIENT_ID` (`-SkipBuildRunner` for reruns).

## Notes
- Android build pins NDK `27.0.12077973`.
- OneDrive locks: pause sync or move project outside OneDrive.
- AI copy: keep strings localizable; prefer interface-based hooks for AI.
- DI via `AppContainer` (`lib/core/di`); register new services there.
- Manual test history in `TESTING.md`.
