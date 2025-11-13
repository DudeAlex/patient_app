# TODO / Milestones

M1: Core App + Settings (done)
- Scaffold Flutter app and base UI shell
- Add Settings screen with Google sign-in + Drive backup/restore buttons
- Wire Isar schemas and open helper

M2: Records CRUD UI (done)
- See `M2_RECORDS_CRUD_PLAN.md` for the delivered breakdown.
- CRUD flows (add/edit/delete) implemented with shared provider refreshing list/detail automatically.
- Attachments remain placeholder stubs; follow-up to wire real attachment capture in a future milestone.

M3: Retrieval & Search Foundation (done)
- See `M3_RETRIEVAL_SEARCH_PLAN.md` for the detailed breakdown.
- Delivered: date-sorted pagination, title/notes search, shared state refresh.
- Deferred for later phases: tag filters, attachment/OCR search, saved views, semantic retrieval.

M4: Auto Sync (Completed 2025-11-09)
- See `M4_AUTO_SYNC_PLAN.md` for the breakdown.
- ✅ Track local dirty state (changes increment counter)
- ✅ On app resume/exit: export/encrypt/upload if dirty
- ✅ Auto backup toggle available in Settings
- ✅ Background backups run on resume when pending changes exist, Wi-Fi/ethernet is available, and the selected cadence interval (6h/12h/daily/weekly/manual) has elapsed
- ✅ Profile hub card surfaces manual "Backup now," cadence presets (persisted + scheduler-backed), display preferences, AI consent toggle, and backup-key portability entry point
- ⏳ Follow-up: Surface conflict banner messaging during Drive merges (deferred to M4.1)
- ⏳ Follow-up: Wire the AI consent toggle into companion flows (M6)
- ⏳ Follow-up: Ship backup-key export/import experience (production blocker, target M4.1)

M5: Multi-Modal Capture & Accessibility (In Progress - 56% complete)
- See `M5_MULTI_MODAL_PLAN.md` for detailed breakdown
- ✅ Photo capture with clarity checks and retake prompts
- ✅ Document scanning with multi-page support and enhancement
- ✅ Voice dictation with transcription pipeline
- ✅ Editable review screen with form validation
- ✅ Attachments saved and linked to records
- ✅ Attachments displayed in record detail with metadata
- ⏳ File upload capability (PDF/images)
- ⏳ Gmail-based email import with OAuth
- ⏳ Keyboard form enhancements
- ⏳ Accessibility audit and localization prep

M6: AI-Assisted Companion (opt-in)
- Build `AiProcessingService` with Together AI integration + consent flow
- Queue AI tasks offline, merge suggestions with patient confirmation
- Surface empathetic summaries, safety hints, and highlight uncertainty/confidence
- Define advisor personas (Resident Medic, Attending Physician, Consulting Specialist) and surface current persona in UI
- Ship on-device lightweight LLM fallback for offline interactions with shared prompt schema
- Integrate retrieval service (RAG) to ground answers in local records, vitals, and attachments
- Add voice-first co-pilot that narrates screens, announces persona shifts, and responds to context-sensitive help requests

M7: Support Network & Emergency Assist
- Add SupportContact model + management UI
- Emergency screen with large call/message/share actions and optional countdown
- Audit log for shared summaries + consent guardrails

M8: Security, Backup & Wellness UX
- Passcode/biometric lock
- Backup/restore progress + error handling improvements
- Wellness check-ins, compassionate notifications, and caregiver sharing (with consent)
- Medication & adherence hub: schedules, reminders, refill tracking, interaction warnings
- Condition-specific plans with weekly goals and explainable insights tied to advisor output
- Build capability-aware feature toggles (install/uninstall heavy modules, explain requirements in text + voice)

M9: Phone-Based Vitals Capture
- Prototype camera-based pulse measurement (PPG) with signal quality checks and safety messaging
- Integrate optional blood pressure capture (camera-assisted or connected cuff), persisting readings as structured records
- Link vitals to records, backups, and AI insights; document calibration and device compatibility
- Extend tracking dashboards with symptom journals, activity adherence, and escalation triggers when readings drift

M10: Privacy-Conscious Analytics
- Opt-in telemetry toggle with plain-language consent and data catalog
- Aggregate on-device usage metrics (feature counts, errors) before encrypted upload
- Build analytics pipeline/dashboard to monitor app health without PHI leakage
- Add feedback loops for AI suggestions (thumbs up/down, survey prompts) without associating with PHI
- Evaluate model performance offline vs cloud and adjust switching heuristics

M11: Conversational Controls & Voice UX
- Implement wake-word / name invocation for the co-pilot with on-device detection
- Support voice commands for “stop,” “pause,” “resume,” “louder,” and “softer,” with confirmation prompts
- Provide settings for narration preferences (always on, on demand, muted) and language selection
- Cache multilingual pre-recorded explanations for critical flows and fall back to synthesized voice when needed

Optional: Web JSON Backup
- Export/import Isar collections (records/tags/insights) as JSON (no attachments)
- Use distinct filename in Drive appData

Operational Follow-ups
- Add `android:enableOnBackInvokedCallback="true"` to AndroidManifest to silence warning
- Enhance `run_pixel.ps1` to prompt for missing `-ServerClientId` and suggest Google Play AVD if none detected
- Add Defender exclusions note to README and link to TROUBLESHOOTING
- Set up `flutter gen-l10n` workflow, glossary, and translation QA (English/Russian/Central Asian languages)
- Document Together AI API key management strategy (secure storage or proxy)
