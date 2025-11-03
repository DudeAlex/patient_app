# Capture Mode: Voice (Planned)

Responsibilities
- Provide a patient-friendly voice dictation flow with clear consent, large controls, and offline-first storage.
- Persist raw audio attachments alongside metadata (duration, sample rate, waveform stats) so other modules can reuse recordings.
- Invoke an injectable `VoiceTranscriptionPipeline` to generate suggested notes/tags for the capture review screen.
- Expose a shared audio stream that the AI companion can use for conversational queries and voice commands.

Planned Public API
- `VoiceCaptureModule` – registers the capture mode and supporting services with `capture_core`.
- `VoiceCaptureService` – records audio, writes session files via `AttachmentsStorage`, and emits `CaptureResult` objects.
- `VoiceTranscriptionPipeline` – interface for STT/LLM transcription providers (stub implementation ships first).
- `VoiceAssistantBridge` – optional helper that routes short utterances to the AI assistant or command router.

Dependencies
- Microphone permission handling (Android/iOS APIs).
- Audio recorder plugin (candidate: `record`, `flutter_sound`, or platform channels).
- `AttachmentsStorage` for managing session files.
- Optional STT/TTS providers injected behind the pipeline interfaces.

Extension Points
- Swap the recorder implementation (e.g., on-device vs platform-specific) without impacting the capture UI.
- Inject alternative transcription services (cloud, offline, multilingual) via `VoiceTranscriptionPipeline`.
- Plug custom intent routers so assistant commands map cleanly to new features.
- Replace the assistant bridge with a streaming solution for real-time AI dialogue.

Status
- Design in progress; implementation begins once the capture contracts and privacy copy are finalised.
