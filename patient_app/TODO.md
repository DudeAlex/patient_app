# TODO / Milestones

M1: Core App + Settings (done)
- Scaffold Flutter app and base UI shell
- Add Settings screen with Google sign-in + Drive backup/restore buttons
- Wire Isar schemas and open helper

M2: Records CRUD UI (next)
- Home list of recent records
- Add/Edit Record (type, date, title, text, tags)
- Record detail screen
- Repository wiring + basic state management

M3: Auto Sync
- Track local dirty state (changes increment counter)
- On app resume/exit: export/encrypt/upload if dirty
- Conflict: last-write-wins with banner

M4: Multi-Modal Add Record & Accessibility
- Design modal with Photo, Voice Dictation, Keyboard (extensible slots)
- Implement large-button, step-by-step flow tuned for older users
- Ensure attachments folder covers photo imports + audio clips
- Add contextual follow-up prompts and unified review panel

M5: AI-Assisted Companion (opt-in)
- Build `AiProcessingService` with Together AI integration + consent flow
- Queue AI tasks offline, merge suggestions with patient confirmation
- Surface empathetic summaries, safety hints, and highlight uncertainty/confidence

M6: Support Network & Emergency Assist
- Add SupportContact model + management UI
- Emergency screen with large call/message/share actions and optional countdown
- Audit log for shared summaries + consent guardrails

M7: Security, Backup & Wellness UX
- Passcode/biometric lock
- Backup/restore progress + error handling improvements
- Wellness check-ins, compassionate notifications, and caregiver sharing (with consent)

Optional: Web JSON Backup
- Export/import Isar collections (records/tags/insights) as JSON (no attachments)
- Use distinct filename in Drive appData

Operational Follow-ups
- Add `android:enableOnBackInvokedCallback="true"` to AndroidManifest to silence warning
- Enhance `run_pixel.ps1` to prompt for missing `-ServerClientId` and suggest Google Play AVD if none detected
- Add Defender exclusions note to README and link to TROUBLESHOOTING
- Set up `flutter gen-l10n` workflow, glossary, and translation QA (English/Russian/Central Asian languages)
- Document Together AI API key management strategy (secure storage or proxy)
