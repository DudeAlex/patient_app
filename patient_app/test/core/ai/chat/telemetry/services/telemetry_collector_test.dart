import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/telemetry_event.dart';
import 'package:patient_app/core/ai/chat/telemetry/services/telemetry_collector_impl.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('TelemetryCollectorImpl', () {
    late StreamController<TelemetryEvent> controller;
    late TelemetryCollectorImpl collector;
    late StreamQueue<TelemetryEvent> queue;

    setUp(() {
      controller = StreamController<TelemetryEvent>.broadcast();
      collector = TelemetryCollectorImpl(uuid: const Uuid(), controller: controller);
      queue = StreamQueue<TelemetryEvent>(collector.events);
    });

    tearDown(() async {
      await queue.cancel();
      await collector.dispose();
    });

    test('startRequest returns id and emits start event asynchronously', () async {
      final requestId = collector.startRequest(
        userId: 'user-1',
        spaceId: 'space-1',
        messageId: 'msg-1',
      );

      expect(requestId, isNotEmpty);

      final event = await queue.next;
      expect(event.type, 'start');
      expect(event.requestId, requestId);
      expect(event.payload['userId'], 'user-1');
      expect(event.payload['spaceId'], 'space-1');
      expect(event.payload['messageId'], 'msg-1');
    });

    test('completeRequest emits completion event with metrics', () async {
      final requestId = collector.startRequest(
        userId: 'user-1',
        spaceId: 'space-1',
        messageId: 'msg-1',
      );
      await queue.next; // consume start event

      await collector.completeRequest(
        requestId: requestId,
        totalLatency: const Duration(milliseconds: 120),
        contextAssemblyTime: const Duration(milliseconds: 30),
        llmCallTime: const Duration(milliseconds: 90),
        promptTokens: 50,
        completionTokens: 75,
        fromCache: true,
      );

      final event = await queue.next;
      expect(event.type, 'complete');
      expect(event.requestId, requestId);
      expect(event.payload['totalLatencyMs'], 120);
      expect(event.payload['contextAssemblyMs'], 30);
      expect(event.payload['llmCallMs'], 90);
      expect(event.payload['promptTokens'], 50);
      expect(event.payload['completionTokens'], 75);
      expect(event.payload['fromCache'], isTrue);
    });

    test('recordError emits error event with classification', () async {
      final requestId = collector.startRequest(
        userId: 'user-2',
        spaceId: 'space-2',
        messageId: 'msg-2',
      );
      await queue.next; // consume start event

      await collector.recordError(
        requestId: requestId,
        errorType: 'network',
        errorMessage: 'Network unreachable',
      );

      final event = await queue.next;
      expect(event.type, 'error');
      expect(event.requestId, requestId);
      expect(event.payload['errorType'], 'network');
      expect(event.payload['errorMessage'], 'Network unreachable');
    });
  });
}
