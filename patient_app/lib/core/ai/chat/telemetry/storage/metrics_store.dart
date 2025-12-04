import 'package:patient_app/core/ai/chat/telemetry/storage/time_series_buffer.dart';

/// Central in-memory store for telemetry metrics with simple capacity controls.
class MetricsStore {
  /// Maximum allowed bytes for all telemetry buffers combined.
  final int totalMemoryBudgetBytes;

  /// Estimated bytes consumed per data point (timestamp + value + metadata).
  final int bytesPerPointEstimate;

  /// Effective capacity used for all buffers (derived from budget).
  final int bufferCapacity;

  final TimeSeriesBuffer requestsPerMinute;
  final TimeSeriesBuffer requestsPerHour;
  final TimeSeriesBuffer requestsPerDay;

  final TimeSeriesBuffer totalLatency;
  final TimeSeriesBuffer contextLatency;
  final TimeSeriesBuffer llmLatency;

  final TimeSeriesBuffer promptTokens;
  final TimeSeriesBuffer completionTokens;

  final TimeSeriesBuffer cacheHits;
  final TimeSeriesBuffer cacheMisses;

  final Map<String, TimeSeriesBuffer> errorsByType;

  MetricsStore({
    this.totalMemoryBudgetBytes = 50 * 1024 * 1024, // 50MB
    this.bytesPerPointEstimate = 128,
    int maxDataPointsPerBuffer = 5000,
    Duration minuteWindow = const Duration(minutes: 1),
    Duration hourWindow = const Duration(hours: 1),
    Duration dayWindow = const Duration(days: 1),
    Duration latencyWindow = const Duration(hours: 1),
    List<String> errorTypes = const ['network', 'timeout', 'rateLimit', 'server', 'validation', 'unknown'],
  })  : bufferCapacity = _deriveCapacity(
          totalMemoryBudgetBytes: totalMemoryBudgetBytes,
          bytesPerPointEstimate: bytesPerPointEstimate,
          maxDataPointsPerBuffer: maxDataPointsPerBuffer,
          errorTypeCount: errorTypes.length,
        ),
        requestsPerMinute = TimeSeriesBuffer(windowSize: minuteWindow, maxDataPoints: maxDataPointsPerBuffer),
        requestsPerHour = TimeSeriesBuffer(windowSize: hourWindow, maxDataPoints: maxDataPointsPerBuffer),
        requestsPerDay = TimeSeriesBuffer(windowSize: dayWindow, maxDataPoints: maxDataPointsPerBuffer),
        totalLatency = TimeSeriesBuffer(windowSize: latencyWindow, maxDataPoints: maxDataPointsPerBuffer),
        contextLatency = TimeSeriesBuffer(windowSize: latencyWindow, maxDataPoints: maxDataPointsPerBuffer),
        llmLatency = TimeSeriesBuffer(windowSize: latencyWindow, maxDataPoints: maxDataPointsPerBuffer),
        promptTokens = TimeSeriesBuffer(windowSize: dayWindow, maxDataPoints: maxDataPointsPerBuffer),
        completionTokens = TimeSeriesBuffer(windowSize: dayWindow, maxDataPoints: maxDataPointsPerBuffer),
        cacheHits = TimeSeriesBuffer(windowSize: dayWindow, maxDataPoints: maxDataPointsPerBuffer),
        cacheMisses = TimeSeriesBuffer(windowSize: dayWindow, maxDataPoints: maxDataPointsPerBuffer),
        errorsByType = {
          for (final type in errorTypes)
            type: TimeSeriesBuffer(windowSize: latencyWindow, maxDataPoints: maxDataPointsPerBuffer),
        };

  /// Removes expired entries across all buffers.
  void cleanupAll() {
    for (final buffer in _allBuffers()) {
      buffer.cleanup();
    }
  }

  /// Returns all buffers for iteration.
  Iterable<TimeSeriesBuffer> _allBuffers() sync* {
    yield requestsPerMinute;
    yield requestsPerHour;
    yield requestsPerDay;
    yield totalLatency;
    yield contextLatency;
    yield llmLatency;
    yield promptTokens;
    yield completionTokens;
    yield cacheHits;
    yield cacheMisses;
    yield* errorsByType.values;
  }

  static int _deriveCapacity({
    required int totalMemoryBudgetBytes,
    required int bytesPerPointEstimate,
    required int maxDataPointsPerBuffer,
    required int errorTypeCount,
  }) {
    // Number of buffers we create in this store:
    // requests (3) + latency (3) + tokens (2) + cache (2) + errors (N)
    final bufferCount = 10 + errorTypeCount;
    final allowedPerBuffer = totalMemoryBudgetBytes ~/ (bytesPerPointEstimate * bufferCount);
    final safeCapacity = allowedPerBuffer == 0 ? 1 : allowedPerBuffer;
    return safeCapacity < maxDataPointsPerBuffer ? safeCapacity : maxDataPointsPerBuffer;
  }
}
