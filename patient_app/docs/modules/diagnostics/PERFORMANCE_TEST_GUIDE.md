Status: ACTIVE

# Performance Test Guide

## Goals
- Detect jank and slow operations early; keep UI smooth and backups unobtrusive.

## When to Test
- Before/after major UI or capture changes; after sync/backup modifications; when logs show long operations.

## Scenarios
- App startup to RecordsHome.
- Scroll RecordsHome with large list.
- Backup/restore run with sample data/attachments.
- Auto-sync resume trigger with dirty data.
- Capture flows: photo/scan/voice/file/email with review.
- Onboarding page switches and completion.

## Tools & Commands
- Run with performance overlay: `flutter run --profile`.
- DevTools: rebuild counts, timeline flame chart, CPU profile.
- Logs: ensure `startOperation/endOperation` around tested flows.

## Metrics
- Frame time <16ms target; spikes >32ms visible jank.
- Build times for onboarding/screens; backup duration; capture flow latency.

## What to Record
- Device/emulator, build mode, scenario, observed lag, log timestamps, operation ids.
- Note mitigations (cached data, reduced rebuilds) and rerun to confirm.
