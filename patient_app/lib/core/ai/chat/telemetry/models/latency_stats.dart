/// Aggregated latency statistics.
class LatencyStats {
  /// Average latency across the window.
  final Duration average;

  /// Median latency across the window.
  final Duration median;

  /// 95th percentile latency.
  final Duration p95;

  /// 99th percentile latency.
  final Duration p99;

  /// Minimum observed latency.
  final Duration min;

  /// Maximum observed latency.
  final Duration max;

  /// Creates a [LatencyStats] instance.
  LatencyStats({
    required this.average,
    required this.median,
    required this.p95,
    required this.p99,
    required this.min,
    required this.max,
  });
}
