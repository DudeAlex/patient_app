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
- ✅ UI Performance Optimization (RecordsHomeModern) - See `.kiro/specs/ui-performance-optimization/`
  - Removed expensive animations and simplified card decorations
  - Implemented 3-line compact layout with reduced spacing
  - Added RepaintBoundary for scroll optimization
  - Comprehensive performance logging (render time, scroll, memory)
  - Target metrics: <500ms render, <5 frame drops, <10MB memory increase
- ⏳ File upload capability (PDF/images)
- ⏳ Gmail-based email import with OAuth
- ⏳ Keyboard form enhancements
- ⏳ Accessibility audit and localization prep

M6: Universal AI Companion (opt-in)
- Build `AiProcessingService` with flexible provider integration + consent flow
- Queue AI tasks offline, merge suggestions with user confirmation
- Surface empathetic summaries, safety hints, and highlight uncertainty/confidence
- Define advisor personas (Life Coach, Financial Advisor, Academic Tutor, etc.) and surface current persona in UI
- Ship on-device lightweight LLM fallback for offline interactions with shared prompt schema
- Integrate retrieval service (RAG) to ground answers in local records and attachments
- Add voice-first co-pilot that narrates screens, announces persona shifts, and responds to context-sensitive help requests

M7: Smart Sharing & Collaboration
- Add Contact model + management UI
- Sharing screen with granular permissions (view/edit) per space
- Audit log for shared summaries + consent guardrails

M8: Security, Backup & Life Companion UX
- Passcode/biometric lock
- Backup/restore progress + error handling improvements
- Daily briefings, compassionate notifications, and goal tracking
- Domain-specific hubs: Budget tracking, Study schedules, Travel itineraries
- Personalized plans with weekly goals and explainable insights tied to advisor output
- Build capability-aware feature toggles (install/uninstall heavy modules, explain requirements in text + voice)

M9: Intelligent Data Capture
- Prototype camera-based capture for domain specific data (Receipts, Whiteboards, Vitals)
- Integrate optional specialized capture flows (e.g. blood pressure or receipt scanning), persisting readings as structured records
- Link captured data to records, backups, and AI insights
- Extend tracking dashboards with domain-specific metrics and escalation triggers when trends drift

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
