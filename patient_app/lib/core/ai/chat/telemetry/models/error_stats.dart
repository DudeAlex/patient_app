/// Aggregated error metrics.
class ErrorStats {
  /// Total error rate as a percentage (0.0 - 100.0).
  final double totalErrorRate;

  /// Error rate by type.
  final Map<String, double> errorRateByType;

  /// Error counts by type.
  final Map<String, int> errorCountByType;

  /// Total error count observed.
  final int totalErrors;

  /// Total requests observed.
  final int totalRequests;

  /// Creates an [ErrorStats] instance.
  ErrorStats({
    required this.totalErrorRate,
    Map<String, double>? errorRateByType,
    Map<String, int>? errorCountByType,
    required this.totalErrors,
    required this.totalRequests,
  })  : errorRateByType = errorRateByType ?? const {},
        errorCountByType = errorCountByType ?? const {};
}
