import 'dart:async';

import 'package:patient_app/core/ai/chat/telemetry/interfaces/telemetry_collector.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/metric_data_point.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/telemetry_event.dart';
import 'package:patient_app/core/ai/chat/telemetry/storage/metrics_store.dart';
import 'package:patient_app/core/ai/chat/telemetry/storage/time_series_buffer.dart';

/// Listens to telemetry events and pushes them into the in-memory metrics store.
class TelemetryIngestService {
  TelemetryIngestService({
    required TelemetryCollector collector,
    required MetricsStore store,
  }) : _store = store {
    _subscription = collector.events.listen(_handleEvent);
  }

  final MetricsStore _store;
  late final StreamSubscription<TelemetryEvent> _subscription;

  Future<void> dispose() async {
    await _subscription.cancel();
  }

  void _handleEvent(TelemetryEvent event) {
    switch (event.type) {
      case 'start':
        _recordStart(event);
        break;
      case 'complete':
        _recordCompletion(event);
        break;
      case 'error':
        _recordError(event);
        break;
    }
  }

  void _recordStart(TelemetryEvent event) {
    final metadata = _baseMetadata(event.payload);
    final point = MetricDataPoint(timestamp: event.timestamp, value: 1, metadata: metadata);
    _store.requestsPerMinute.add(point);
    _store.requestsPerHour.add(point);
    _store.requestsPerDay.add(point);
  }

  void _recordCompletion(TelemetryEvent event) {
    final payload = event.payload;
    final metadata = _baseMetadata(payload);

    final totalLatency = (payload['totalLatencyMs'] as num?)?.toDouble() ?? 0;
    final contextLatency = (payload['contextAssemblyMs'] as num?)?.toDouble() ?? 0;
    final llmLatency = (payload['llmCallMs'] as num?)?.toDouble() ?? 0;
    final promptTokens = (payload['promptTokens'] as num?)?.toDouble() ?? 0;
    final completionTokens = (payload['completionTokens'] as num?)?.toDouble() ?? 0;
    final fromCache = payload['fromCache'] == true;

    _store.totalLatency.add(
      MetricDataPoint(timestamp: event.timestamp, value: totalLatency, metadata: metadata),
    );
    _store.contextLatency.add(
      MetricDataPoint(timestamp: event.timestamp, value: contextLatency, metadata: metadata),
    );
    _store.llmLatency.add(
      MetricDataPoint(timestamp: event.timestamp, value: llmLatency, metadata: metadata),
    );

    _store.promptTokens.add(
      MetricDataPoint(timestamp: event.timestamp, value: promptTokens, metadata: metadata),
    );
    _store.completionTokens.add(
      MetricDataPoint(timestamp: event.timestamp, value: completionTokens, metadata: metadata),
    );

    final cacheBuffer = fromCache ? _store.cacheHits : _store.cacheMisses;
    cacheBuffer.add(
      MetricDataPoint(timestamp: event.timestamp, value: 1, metadata: metadata),
    );
  }

  void _recordError(TelemetryEvent event) {
    final payload = event.payload;
    final metadata = _baseMetadata(payload);
    final errorType = (payload['errorType'] as String?) ?? 'unknown';

    final buffer = _ensureErrorBuffer(errorType);
    buffer.add(
      MetricDataPoint(timestamp: event.timestamp, value: 1, metadata: metadata),
    );
  }

  Map<String, dynamic> _baseMetadata(Map<String, dynamic> payload) {
    final metadata = <String, dynamic>{};
    final userId = payload['userId'] as String?;
    final spaceId = payload['spaceId'] as String?;
    final messageId = payload['messageId'] as String?;
    if (userId != null) metadata['userId'] = userId;
    if (spaceId != null) metadata['spaceId'] = spaceId;
    if (messageId != null) metadata['messageId'] = messageId;
    return metadata;
  }

  TimeSeriesBuffer _ensureErrorBuffer(String errorType) {
    final existing = _store.errorsByType[errorType];
    if (existing != null) return existing;
    // Use a conservative 1 hour window for ad-hoc error types.
    final buffer = TimeSeriesBuffer(
      windowSize: const Duration(hours: 1),
      maxDataPoints: _store.bufferCapacity,
    );
    _store.errorsByType[errorType] = buffer;
    return buffer;
  }
}
