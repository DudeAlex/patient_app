import '../../../capture_core/api/capture_draft.dart';

class VoiceTranscriptionRequest {
  const VoiceTranscriptionRequest({
    required this.sessionId,
    required this.localeTag,
    required this.relativePath,
    required this.durationMs,
  });

  final String sessionId;
  final String localeTag;
  final String relativePath;
  final int durationMs;
}

class VoiceTranscriptionResult {
  const VoiceTranscriptionResult({
    this.draft,
    this.metadata = const <String, Object?>{},
  });

  final CaptureDraft? draft;
  final Map<String, Object?> metadata;
}

abstract class VoiceTranscriptionPipeline {
  Future<VoiceTranscriptionResult> transcribe(VoiceTranscriptionRequest request);
}

class StubVoiceTranscriptionPipeline implements VoiceTranscriptionPipeline {
  const StubVoiceTranscriptionPipeline();

  @override
  Future<VoiceTranscriptionResult> transcribe(
    VoiceTranscriptionRequest request,
  ) async {
    final seconds = (request.durationMs / 1000).toStringAsFixed(1);
    final draft = CaptureDraft(
      suggestedDetails:
          'Voice note placeholder. Duration: $seconds seconds. Transcript coming soon.',
      suggestedTags: {'voice', 'transcription'},
    );
    return VoiceTranscriptionResult(
      draft: draft,
      metadata: {
        'transcription': 'stub',
        'durationMs': request.durationMs,
      },
    );
  }
}
