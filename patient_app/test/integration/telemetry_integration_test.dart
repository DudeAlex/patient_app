import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/models/context_stats.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';
import 'package:patient_app/core/ai/chat/services/error_classifier.dart';
import 'package:patient_app/core/ai/chat/services/error_recovery_strategy.dart';
import 'package:patient_app/core/ai/chat/services/fallback_service.dart';
import 'package:patient_app/core/ai/chat/services/resilient_ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/telemetry/services/telemetry_collector_impl.dart';
import 'package:patient_app/core/ai/chat/telemetry/services/telemetry_ingest_service.dart';
import 'package:patient_app/core/ai/chat/telemetry/services/metrics_aggregation_service_impl.dart';
import 'package:patient_app/core/ai/chat/telemetry/storage/metrics_store.dart';
import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';

class _TelemetryFakeAiService implements AiChatService {
  _TelemetryFakeAiService({
    this.latency = const Duration(milliseconds: 40),
    this.promptTokens = 60,
    this.completionTokens = 40,
  });

  final Duration latency;
  final int promptTokens;
  final int completionTokens;

  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    await Future<void>.delayed(latency);
    return ChatResponse.success(
      messageContent: 'ok',
      metadata: AiMessageMetadata(
        tokensUsed: promptTokens + completionTokens,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        latencyMs: latency.inMilliseconds,
        provider: 'fake',
      ),
    );
  }

  @override
  Stream<ChatResponseChunk> sendMessageStream(ChatRequest request) => const Stream.empty();

  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) async {
    return AiSummaryResult.success(summaryText: 'summary');
  }
}

class _TelemetryThrowingService implements AiChatService {
  _TelemetryThrowingService(this.exception);

  final AiServiceException exception;

  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    throw exception;
  }

  @override
  Stream<ChatResponseChunk> sendMessageStream(ChatRequest request) => const Stream.empty();

  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) async {
    return AiSummaryResult.success(summaryText: 'summary');
  }
}

ChatRequest _requestWithContext({String threadId = 'thread-1'}) {
  return ChatRequest(
    threadId: threadId,
    messageContent: 'hello',
    spaceContext: SpaceContext(
      spaceId: 'space-1',
      spaceName: 'Space',
      persona: SpacePersona.general,
      description: 'desc',
      stats: const ContextStats(
        recordsFiltered: 1,
        recordsIncluded: 1,
        tokensEstimated: 10,
        tokensAvailable: 100,
        compressionRatio: 0.5,
        assemblyTime: Duration(milliseconds: 25),
      ),
    ),
  );
}

void main() {
  group('Telemetry integration', () {
    late TelemetryCollectorImpl collector;
    late MetricsStore store;
    late TelemetryIngestService ingest;
    late MetricsAggregationServiceImpl metrics;

    setUp(() {
      collector = TelemetryCollectorImpl();
      store = MetricsStore();
      ingest = TelemetryIngestService(collector: collector, store: store);
      metrics = MetricsAggregationServiceImpl(store);
    });

    tearDown(() async {
      await collector.dispose();
      await ingest.dispose();
    });

    test('collects latency, tokens, cache, and request metrics', () async {
      final service = ResilientAiChatService(
        primaryService: _TelemetryFakeAiService(),
        errorClassifier: ErrorClassifier(),
        fallbackService: FallbackService(),
        recoveryStrategies: const <ErrorRecoveryStrategy>[],
        telemetryCollector: collector,
      );

      await service.sendMessage(_requestWithContext());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(metrics.getCurrentRequestRate(), 1);
      expect(metrics.getLatencyStats().average, isNot(equals(Duration.zero)));

      final tokenStats = metrics.getTokenUsage();
      expect(tokenStats.totalTokens, greaterThan(0));
      expect(metrics.getCacheHitRate(), 0.0);
    });

    test('records errors when requests fail', () async {
      final service = ResilientAiChatService(
        primaryService: _TelemetryThrowingService(
          ServerException(message: 'down'),
        ),
        errorClassifier: ErrorClassifier(),
        fallbackService: FallbackService(),
        recoveryStrategies: const <ErrorRecoveryStrategy>[],
        telemetryCollector: collector,
      );

      await service.sendMessage(_requestWithContext(threadId: 'thread-err'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final errorStats = metrics.getErrorStats();
      expect(errorStats.totalErrors, 1);
      expect(errorStats.totalRequests, greaterThanOrEqualTo(1));
    });
  });
}
