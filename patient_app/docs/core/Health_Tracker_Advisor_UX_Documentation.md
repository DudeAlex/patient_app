Status: ACTIVE

# Health Tracker & Advisor UX

## Design Principles
- Modern, calm, high-contrast; gradient blue accent; off-white background.
- Typography: Inter; large touch targets (≥48pt); clear hierarchy.
- Accessibility and simplicity for all ages.

## Core Screens
- **Dashboard**: title + profile; 2x3 metric grid (steps, heart rate, sleep, water, calories, stress) with value/subtext; tap for detail; bottom nav (Dashboard/Records/Advisor); floating Add Record; quick actions for pulse/BP.
- **Records**: large title + search; easy-to-read list (icon, title, date); "+ Add Record" FAB hides on scroll.
- **Add Record Modal**: 2x3 options (photo, scan, voice, type, upload, email); photo/scan include clarity/retake/rescan tips; email uses read-only Gmail label with source headers; cancel or swipe down.
- **Health Advisor (AI chat)**: header/subtitle; chat bubbles (user blue right, advisor outlined left); summaries may include charts/suggestions; input bar with text/mic/send; optional chips (e.g., summarize/remind); AI reads stored records and responds calmly.
- **Vitals Quick Actions**: pulse via camera PPG with quality meter/disclaimer and saved readings; blood pressure via BT cuff or camera estimate (with calibration guidance); store method metadata, timestamps, confidence; show trends/alerts on dashboard.

## AI & LLM Integration (concept)
- Pipeline: OCR (scans) -> ASR (voice) -> Gmail label ingest + headers -> normalize vitals/dates/providers -> LLM summarization (insights + recommendations) -> store structured JSON + originals.

## Accessibility & Safety
- WCAG AA contrast; clear active states.
- Prefer on-device processing; transparent camera/mic/storage permissions.
- Disclaimers for vitals (not medical diagnosis).
