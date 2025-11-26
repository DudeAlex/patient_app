Status: ACTIVE

# Performance Tracking Summary

## Approach
- Instrument critical flows with `AppLogger.startOperation/endOperation`; warn when duration > threshold (default 1000ms).
- Use DevTools for rebuild counts/flame charts when lag observed.

## What to Track
- App startup/init sequences.
- Screen loads (Onboarding, RecordsHome, Settings, capture flows).
- Backup/restore/auto-sync runs.
- Capture flows (photo/scan/voice/file/email) and review steps.

## Logging Tips
- Name operations clearly (`load_records`, `backup_run`, `capture_photo`).
- Include context: counts, durations, device type, space/record ids.
- Avoid logging in build methods; prefer init/presenter/use-case layers.

## Actions on Findings
- If operations exceed thresholds, identify synchronous hotspots; move work off build/UI thread; cache data.
- Reduce rebuilds with smaller widgets/selectors; prefer lazy lists.

## Testing
- Profile on emulator and real device for confirmation; keep logs for regressions; add targeted benchmarks where feasible.
