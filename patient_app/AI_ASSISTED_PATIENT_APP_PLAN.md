# AI-Assisted Patient App Plan

Status: Living document - consolidates AI strategy across milestones
Last Updated: 2025-11-12

## Vision

Local-first personal health records app with **optional** AI assistance. Privacy and patient control are non-negotiable defaults.

- **Default Mode:** Local-only. All data stays on device. No AI processing.
- **Opt-In Mode:** AI-assisted companion using Together AI (Llama 70B text, Apriel vision) for extraction, organization, and wellness guidance.
- **Patient Control:** Explicit consent required before any PHI leaves device. Can disable at any time.

## Core Principles

1. **Privacy First:** No data leaves device without explicit consent
2. **Offline First:** Core functionality works without network
3. **Transparent:** Show when AI is processing, what data is sent, confidence levels
4. **Reversible:** Patient can disable AI and delete all AI-generated content
5. **Compassionate:** AI tone is supportive, not clinical or alarming

## AI Integration Points

### M6: AI-Assisted Companion (Planned)
**Purpose:** Help patients capture, organize, and understand health records

**Capabilities:**
- Photo/scan OCR and structured data extraction
- Voice transcription and note generation
- Contextual follow-up questions for missing details
- Tag suggestions and record categorization
- Empathetic summaries with safety hints
- Confidence scoring on all suggestions

**Technical:**
- Service: Together AI API (Llama 70B, Apriel vision)
- Queue: Local Isar storage for offline resilience
- Encryption: HTTPS transport, secure API key storage
- Fallback: Manual entry always available

**See:** SPEC.md sections 4.8, 4.10 for detailed requirements

### M7: Support Network & Emergency Assist (Planned)
**AI Role:**
- Suggest emergency contacts based on record patterns
- Draft summary messages for caregivers (patient approval required)
- Identify when to escalate (e.g., concerning vitals)

### M8: Wellness Companion & Check-Ins (Planned)
**AI Role:**
- Daily/weekly mood and energy prompts
- Compassionate encouragement and practical suggestions
- Curated resources (breathing exercises, sleep tips)
- Medication adherence reminders with context

**Advisor Personas:**
- Resident Medic (everyday guidance)
- Attending Physician (clinical context)
- Consulting Specialist (deep dives)

### M9: Phone-Based Vitals Capture (Planned)
**AI Role:**
- Analyze pulse/BP readings for trends
- Suggest when to contact doctor (non-diagnostic)
- Link vitals to symptoms and medications

### M11: Conversational Controls & Voice UX (Planned)
**AI Role:**
- Voice-first co-pilot with wake-word detection
- Screen narration and context-sensitive help
- Natural language commands ("Show my last blood test")
- Multilingual support (English, Russian, Central Asian languages)

## Consent & Privacy Model

### Consent Flow
1. **First Launch:** Default to Local-only mode
2. **Settings Toggle:** "Enable AI Assistance" with plain-language explanation
3. **Per-Request Banner:** Show when AI processes specific data
4. **Audit Log:** Track what was sent, when, and results (no PHI in logs)

### Data Handling
- **Sent to AI:** Photos, scans, voice recordings, text notes (only when consented)
- **Never Sent:** Encryption keys, device IDs, raw Isar database
- **Retention:** Together AI processes requests transiently (verify with provider)
- **Backup:** AI queue data included in encrypted Drive backups

### Privacy Guardrails
- API keys stored via `flutter_secure_storage`, never in code
- All requests over HTTPS
- Log only request IDs, durations, error codes (no PHI)
- Patient can export/delete all AI-generated content
- Offline queue persists locally; retries when online

**See:** SPEC.md section 7, SYNC.md "Consent & Privacy" for implementation details

## Implementation Status

| Milestone | Feature | Status | Notes |
|-----------|---------|--------|-------|
| M6 | AI Processing Service | Planned | Queue + Together AI integration |
| M6 | Consent Toggle | Planned | Settings UI + persistence |
| M6 | Photo/Scan Extraction | Planned | Apriel vision model |
| M6 | Voice Transcription | Planned | STT pipeline (provider TBD) |
| M7 | Support Network AI | Planned | Contact suggestions |
| M8 | Wellness Check-Ins | Planned | Mood prompts + encouragement |
| M8 | Advisor Personas | Planned | Resident/Attending/Specialist |
| M9 | Vitals Analysis | Planned | Trend detection, escalation hints |
| M11 | Voice Co-Pilot | Planned | Wake-word, narration, commands |
| M11 | Multilingual | Planned | English/Russian first |

## Technical Architecture

### Components
- `AiProcessingService` - Queue management, request orchestration
- `AiProcessingMode` enum - Local Only vs AI Assisted
- `TogetherAiClient` - HTTP client for Together AI API
- `AiTaskQueue` - Isar-backed offline queue
- `ConsentManager` - Track and enforce consent state
- `VoiceTranscriptionPipeline` - Pluggable STT provider
- `VoiceIntentRouter` - Route voice input (dictation vs commands vs conversation)

### Data Flow
1. Patient captures data (photo/voice/text)
2. If AI enabled: enqueue task with source artifacts
3. When online: send to Together AI
4. Receive structured response + confidence
5. Present suggestions to patient for approval
6. Save approved data to records
7. Original artifacts always preserved

### Error Handling
- Network failures: queue for retry with exponential backoff
- API errors: show friendly message, allow manual entry
- Low confidence: flag for patient review
- Timeout: cancel after 30s, keep original data

## Open Questions & Decisions Needed

### High Priority
1. **Together AI API Key Management**
   - Option A: Secure storage on device (current plan)
   - Option B: Proxy service (adds complexity, better security)
   - Decision: TBD before M6 implementation

2. **Voice Transcription Provider**
   - Options: Google Speech-to-Text, Whisper (local), Together AI
   - Criteria: Offline capability, accuracy, cost, privacy
   - Decision: TBD during M5 voice capture implementation

3. **On-Device LLM Fallback**
   - Should we bundle a small model for offline AI?
   - Trade-offs: App size vs offline capability
   - Decision: Defer to post-MVP

### Medium Priority
4. **AI Usage Limits**
   - Free tier limits on Together AI?
   - How to handle quota exhaustion?
   - Decision: Monitor during beta

5. **Multilingual Medical Terminology**
   - How to handle translation of medical terms?
   - Glossary ownership and maintenance?
   - Decision: Start with English/Russian, expand based on usage

6. **AI-Triggered Safety Escalations**
   - When should AI suggest calling doctor/emergency?
   - How to avoid false alarms vs missing real issues?
   - Decision: Conservative approach, always include disclaimers

### Low Priority
7. **Model Selection**
   - Llama 70B vs other models?
   - When to use vision vs text-only?
   - Decision: Start with Together AI defaults, optimize later

8. **Feedback Loop**
   - How to collect thumbs up/down on AI suggestions?
   - How to improve without sending PHI?
   - Decision: Defer to M10 (Privacy-Conscious Analytics)

## Testing Strategy

### Manual Test Scenarios (to be added to TESTING.md)
- AI-01: Enable AI mode, verify consent banner
- AI-02: Capture photo with AI enabled, review suggestions
- AI-03: Disable network, verify offline queue
- AI-04: Reject AI suggestion, verify original preserved
- AI-05: Disable AI mode, verify no data sent
- AI-06: Voice dictation with transcription
- AI-07: Low confidence response handling

### Automated Tests (future)
- Unit: AI service queue management
- Unit: Consent state transitions
- Integration: Together AI client (mocked)
- E2E: Full capture → AI → review → save flow

## References

- **Requirements:** SPEC.md sections 4.8, 4.10, 7
- **Architecture:** ARCHITECTURE.md "AI-First Design Principles"
- **Sync/Backup:** SYNC.md "AI Processing Queue", "Consent & Privacy"
- **UX Vision:** Health_Tracker_Advisor_UX_Documentation.md
- **Troubleshooting:** TROUBLESHOOTING.md "AI-Assisted Mode"
- **Milestones:** M6, M7, M8, M9, M11 plans in TODO.md

## For AI Agents

**When implementing AI features:**
1. Always check `AiProcessingMode` before sending data
2. Enqueue tasks, don't block UI
3. Preserve original artifacts before AI processing
4. Include confidence scores in all responses
5. Log only non-PHI telemetry
6. Test offline behavior
7. Update consent copy in Settings

**Key constraints:**
- Never send data without explicit consent
- Always provide manual fallback
- Offline-first: core features work without AI
- Compassionate tone: supportive, not alarming
