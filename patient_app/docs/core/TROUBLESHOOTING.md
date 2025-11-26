Status: ACTIVE

# Troubleshooting

## Process Guardrails
- Small, verifiable changes; document/manual checks; keep README/RUNNING/ARCHITECTURE/SYNC/TODO updated.

## Common Issues
- **Windows symlink/plugins**: run elevated PowerShell or enable Developer Mode.
- **Emulator won't start**: enable virtualization; install Emulator Hypervisor Driver; launch with `-gpu angle_indirect`.
- **NDK mismatch**: use pinned `ndkVersion = "27.0.12077973"` in `android/app/build.gradle.kts`.
- **isar_flutter_libs namespace**: rerun build (patched cache).

## Google Sign-In Errors (Android)
- Ensure Google account on device (Play image), Drive API enabled, consent test users added.
- OAuth clients: Android (package `com.example.patient_app`, debug SHA-1/256) + Web client id.
- Run with server client id: `flutter run -d <device> --dart-define=GOOGLE_ANDROID_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID`.
- Clear Play Services data if reauth fails.

## Performance (Emulator)
- Use Google Play image, hardware graphics, 4GB RAM/4 cores; scale display to 0.5 if needed.
- Enable Windows Hypervisor Platform; remove HAXM.
- Defender exclusions: Flutter SDK, Android SDK, gradle cache, pub cache, AVD dir, project dir.

## Back Gesture Warning
- Add `android:enableOnBackInvokedCallback="true"` to `<application>` in AndroidManifest.

## OneDrive Locks
- Pause OneDrive or move project outside OneDrive if files lock during build.

## AI-Assisted Mode
- Toggle missing: ensure feature flag + `AiProcessingMode` persisted.
- Consent/banner issues: reset via Settings > Privacy; toggle AI off/on.
- Requests fail: check network, API key (secure storage/proxy), Together AI reachable; log with `[AI]`.
- Respect opt-out (`AI_DISABLED`); keep local-only fallback.

## Together AI Connectivity
- 401/403: invalid key; rotate.
- Timeouts: queue with backoff (~10m cap).
- Large payload: compress/limit resolution.
- If unreachable: keep patient in local-only flow with manual guidance.

## Auto Backup
- Not running: ensure toggle on, signed in, pending record changes, cadence elapsed, Wi-Fi/ethernet available.
- Check `[AutoSync]` logs for skip reasons.

## Voice/Accessibility
- Mic denied: explain need and how to enable in system settings.
- Poor transcription: fall back to manual edit; tag as "Needs review".
- Screen reader: verify semantics; large touch targets.

## Localization
- Add keys then `flutter gen-l10n`; ensure long strings wrap.
- AI responses: pass locale (`lang=ru` etc.).
