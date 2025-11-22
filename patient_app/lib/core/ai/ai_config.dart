/// Simple configuration flags for AI features.
///
/// These values default to disabled/fake until configuration repositories and
/// settings UI wire real user preferences. See `.kiro/specs/ai-summarization`.
class AiConfig {
  const AiConfig({
    this.enabled = false,
    this.mode = AiMode.fake,
    this.remoteUrl = '',
  });

  final bool enabled;
  final AiMode mode;
  final String remoteUrl;

  AiConfig copyWith({
    bool? enabled,
    AiMode? mode,
    String? remoteUrl,
  }) {
    return AiConfig(
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      remoteUrl: remoteUrl ?? this.remoteUrl,
    );
  }
}

enum AiMode { fake, remote }
