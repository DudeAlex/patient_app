import '../../ai/ai_config.dart';

/// Persists high-level AI configuration flags (enabled/mode/urls).
abstract class AiConfigRepository {
  /// Latest config cached in memory. Call [loadConfig] first.
  AiConfig get current;

  /// Emits new config snapshots whenever settings change.
  Stream<AiConfig> get stream;

  /// Loads configuration from storage and updates [current].
  Future<AiConfig> loadConfig();

  Future<void> setEnabled(bool enabled);
  Future<void> setMode(AiMode mode);
}
