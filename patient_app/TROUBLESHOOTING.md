# Troubleshooting

LLM Development Pace & Process
- Do not add lots of code at once; prefer small, verifiable updates.
- After each change, describe manual validation steps and check the app locally when possible.
- Add clear comments to any new or modified code so maintainers can understand intent.
- Always keep docs in sync: update README, RUNNING, ARCHITECTURE, SYNC, and TODO when behavior changes.
- See AGENTS.md for full guidelines used by this repo.

Windows Symlink / Plugins
- Symptom: "Building with plugins requires symlink support"
- Fix: Run terminal as Administrator OR enable Developer Mode (Settings > For developers)

Emulator Fails to Start
- Ensure CPU virtualization is enabled in BIOS
- Install Android Emulator Hypervisor Driver (SDK Manager > SDK Tools)
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
    - OAuth consent screen in Testing and your account isn't added as a Test user
    - Drive API disabled in the GCP project; tokens get rejected when requesting scopes
    - Missing Android OAuth client (package `com.example.patient_app`) with debug SHA-1/SHA-256 in the same project as the Web client
  - Fix checklist:
    - Add Google account on the device: Settings > Passwords & accounts > Add account > Google
    - Open Play Store once, update Google Play services, then reboot the device/emulator
    - Use an AVD with a Google Play system image (Play Store badge)
    - In Google Cloud console:
      - Consent screen: add your account as a Test user
      - Enable Google Drive API in the same project as the Web client ID
      - Create Android OAuth client with package `com.example.patient_app`; add debug SHA-1 and SHA-256
        - Get SHA report: `cd android; .\gradlew signingReport` (PowerShell)
    - If still stuck, clear data: Settings > Apps > Google Play services > Storage > Clear all data > Reboot
  - In-app help: Settings > Run Auth Diagnostics and review `[Auth] [Diag] ...` logs
  - Once signed in, the app caches the email so reopening Settings should be instant; if the Google bottom sheet reappears repeatedly, sign out and sign back in to refresh the cache.
- Web: pass `--dart-define=GOOGLE_WEB_CLIENT_ID=...` and add localhost origins in GCP

Emulator Performance (Windows)
- Symptom: slow UI, skipped frames, "feels like weak PC"
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

AI-Assisted Mode (Planned Rollout)
- Symptom: AI toggle missing -> ensure feature flag enabled and `AiProcessingMode` persisted; default is Local Only.
- Consent banner not showing -> confirm the toggle was enabled after onboarding; reset consent via Settings > Privacy > Reset AI permissions.
- Requests never complete -> check network access; Together AI endpoints require HTTPS. Verify API key stored in secure storage or proxy.
- Error `AI_DISABLED` -> patient opted out or revoked consent; prompt them to re-enable under Settings if they wish.
- Combine AI logs with `[AI]` prefix so they're easy to filter without leaking PHI.

Together AI Connectivity
- HTTP 401/403 -> API key invalid/expired. Rotate credentials and avoid embedding keys in the app bundle.
- HTTP timeouts -> queue request locally, show "Processing will continue later". Retry with exponential backoff capped at ~10 minutes.
- Large payload errors -> compress images before upload; set max resolution for photo capture (e.g., 12MP) to keep token usage manageable.
- If Together AI is unreachable, keep patient in local-only flow and provide manual guidance instead of blocking save.

Voice Dictation & Accessibility
- Microphone permission denied -> show friendly dialog explaining why voice helps and how to enable it in system settings.
- Transcription inaccurate -> fall back to manual edit screen and tag the field as "Needs review".
- Screen reader issues -> verify semantics with `flutter_a11y` tooling; ensure large buttons have descriptive labels (e.g., "Add record: voice").

Localization Gaps
- Missing translations -> run `flutter gen-l10n` to regenerate ARB outputs; check that new keys were added to all locale files.
- Text truncation in Russian/Kazakh -> enable soft wrapping and allow buttons to expand; review with pseudo-localization builds.
- AI response in wrong language -> ensure prompts pass the patient's locale code (`lang=ru`, `lang=kk`, etc.) to Together AI.
