/// Aggregated token usage metrics.
class TokenUsageStats {
  /// Total tokens used (prompt + completion).
  final int totalTokens;

  /// Total prompt tokens used.
  final int promptTokens;

  /// Total completion tokens used.
  final int completionTokens;

  /// Token usage aggregated by user (hashed/anonymized).
  final Map<String, int> byUser;

  /// Token usage aggregated by space.
  final Map<String, int> bySpace;

  /// Average tokens per request.
  final double averagePerRequest;

  /// Creates a [TokenUsageStats] instance.
  TokenUsageStats({
    required this.totalTokens,
    required this.promptTokens,
    required this.completionTokens,
    Map<String, int>? byUser,
    Map<String, int>? bySpace,
    required this.averagePerRequest,
  })  : byUser = byUser ?? const {},
        bySpace = bySpace ?? const {};
}
