# AI-Assisted Patient App Experience Plan

Status: draft (concept validation in progress)

## Purpose
- Capture the combined vision for a compassionate health-record companion that works in both local-only and cloud-assisted modes.
- Provide implementation guardrails for multi-modal data capture, Together AI integration, accessibility for older users, and multilingual support (including Central Asian languages).
- Identify privacy, consent, and safety considerations before coding begins.

## Operating Modes
- **Local Storage Only**
  - Stores structured records, attachments, and tags on-device via Isar.
  - Offers manual organization helpers (templates, tagging, search) without calling external AI services.
  - Default for privacy-sensitive users or offline environments.
- **AI-Assisted (Opt-In)**
  - Explicit consent toggles enable requests to Together AI (Llama 70B for text, Apriel for images).
  - AI performs extraction, summarization, safety hints, and compassionate messaging.
  - Always saves the raw input locally first; AI suggestions arrive asynchronously and require patient confirmation before overwriting fields.
- **Hybrid Flexibility**
  - Patients can switch modes in Settings. Queue pending AI jobs when connectivity is lost and retry later.
  - Maintain an `AiProcessingMode` setting (`local_only`, `ai_assisted`, `queued_ai`) that downstream features can query.

## Multi-Modal Add Record Flow
- **Entry Point**
  - Single, high-contrast "Add Record" button on home screen.
  - Opens a friendly modal with large buttons: Photo/Image, Document Scan, Dictate, Keyboard/Text, Upload File, Import from Email.
- **Photo/Image**
  - Capture or import images; upload (if AI-enabled) to Apriel for text extraction and classification.
  - Provide local OCR fallback for users in local-only mode.
  - Run immediate clarity/OCR checks and prompt patients to retake if text or key fields are unreadable before advancing.
- **Document Scan**
  - Auto-detect edges, correct perspective, and reduce glare for paper records.
  - Run on-device OCR; send enhanced captures to AI (if enabled) for structured extraction.
  - Offer guided rescan when glare/blur lowers confidence, with manual cropping as a fallback.
- **Voice Dictation**
  - Simple record/stop UI with live transcription where possible.
  - AI parses transcripts to fill structured fields, highlight uncertainties, and request clarifications.
- **Keyboard/Text**
  - Guided forms with big inputs, templates per record type, and optional freeform note area.
- **Upload File**
  - Accept PDFs and common medical image formats; preserve originals as attachments with metadata (source, upload date).
  - Offer inline previews and prompt for tagging before save.
- **Import from Email**
  - Allow patients to connect a read-only Gmail label (Gmail API, restricted scope) or forwarding address dedicated to health records.
  - Parse medical summaries, keep original message headers, and highlight extracted fields for confirmation.
- **Contextual Follow-Up**
  - AI and rule-based prompts ask for missing details ("When did the prescription start?").
  - Allow skip/defer; unresolved prompts surface in the review panel.
- **Review & Edit Panel**
  - Combines photo, transcript, and manual edits.
  - Shows AI confidence badges and keeps original artifacts for reference.
  - Large "Save" confirmation with voice narration option.

## Phone-Based Vitals Capture
- Provide quick actions for pulse and blood pressure checks from the dashboard or Add Record flow.
- Support camera-based photoplethysmography (finger over camera/flash) with real-time signal quality feedback and safety disclaimers.
- Allow pairing with compatible cuffs/sensors for blood pressure; store calibration info and confidence scoring.
- Save vitals as structured entries linked to records, and surface trends or alerts via the AI companion when enabled.

## AI Service Integration (Together AI)
- **Abstraction**
  - Add `AiProcessingService` to encapsulate payload packaging, API calls, retries, and schema validation.
  - Use structured prompts enforcing response JSON with record fields, tags, insights, confidence, follow-up questions, and empathy text.
- **Security**
  - Store API key outside the app bundle (secure storage or proxy). Transmit via HTTPS only.
  - Log non-PII telemetry (request id, duration, failure reason).
- **Consent & Transparency**
  - On first opt-in, explain what data leaves the device and link to privacy policy.
  - Provide per-request banners ("This photo will be analyzed securely in the cloud") with cancel option.
- **Offline Handling**
  - Queue requests; notify user when AI processing is pending and when results arrive.
  - Offer manual completion so records are not blocked by connectivity.
- **Uncertainty & Safety**
  - Capture AI confidence per field, surface "Needs review" flags.
  - Run medication/symptom heuristics and add disclaimers encouraging professional consultation.

## Accessibility for Older, Less Tech-Savvy Users
- Large typography, high contrast, and intuitive icons (with text).
- Step-by-step flows with progress indicators and optional voice narration.
- Minimal typing: defaults to voice/photo capture, big custom keyboards when required.
- Forgiving UX: auto-save drafts, undo support, calm confirmations (e.g., display "Record saved" in the patient's language).
- Optional caregiver assist mode that simplifies navigation even further.

## Multilingual Strategy
- Adopt Flutter `gen-l10n` with ARB files; keep keys semantic.
- Ship English + Russian at launch; schedule translations for Kazakh, Uzbek, Kyrgyz, and others via the same pipeline.
- Localize copy, AI prompts, safety messages, date/number formatting, and measurement units per locale.
- Provide voice instructions and text-to-speech where available; ensure AI responses request the patient's language explicitly.
- Maintain a medical terminology glossary and run native-speaker QA for each language.

## Support Network & Emergency Assistance
- Extend the schema with a "Support Network" collection (contacts, relationship, preferred channels, priority).
- Home screen widget with quick access to top contacts; emergency screen with large "Call / Message / Share summary" buttons and optional auto-call countdown.
- Allow AI to suggest contacting trusted people when records indicate serious concerns--always requiring explicit confirmation.
- Keep detailed consent controls: per-contact sharing permissions, share history log, and easy revoke options.

## Compassionate Companion Experience
- Daily or weekly wellness check-ins (voice or text) capturing mood, energy, and concerns.
- AI-generated encouragement and practical advice referencing recent records.
- Curated content library (breathing exercises, educational articles) tailored to conditions and language.
- Carefully phrased notifications ("You're doing great!") that can be snoozed or muted.

## Privacy, Compliance, and Documentation
- Update README, SPEC, ARCHITECTURE, SYNC, and TROUBLESHOOTING before implementation to reflect AI data flow and consent mechanics.
- Document PHI handling, storage locations, and retention policies for audio/images/transcripts.
- Evaluate Together AI SLA, rate limits, and costs; set server-side throttles and budgeting alerts.
- Plan incident response: local logs for errors, user-visible status messages, and support contact info.

## Next Steps
1. Validate requirements with stakeholders and finalize consent copy in all launch languages.
2. Prototype the multi-modal Add Record UI (local mode) and gather usability feedback from older users.
3. Implement `AiProcessingService` interface and stubs; integrate Together AI behind feature flag.
4. Extend Settings with mode toggle, language selector, and support network management.
5. Pilot AI-assisted workflow with anonymized data, measure accuracy, refine prompts, then roll out gradually.
