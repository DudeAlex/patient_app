import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/telemetry/services/telemetry_collector_impl.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/telemetry_event.dart';

void main() {
  group('Telemetry Property 11: Metric collection timing', () {
    test('collector emits asynchronously in under 10ms', () async {
      final collector = TelemetryCollectorImpl();
      final queue = StreamQueue<TelemetryEvent>(collector.events);
      final stopwatch = Stopwatch()..start();

      collector.startRequest(
        userId: 'user-1',
        spaceId: 'space-1',
        messageId: 'msg-1',
      );

      final event = await queue.next;
      stopwatch.stop();

      expect(event.type, 'start');
      expect(stopwatch.elapsedMilliseconds, lessThan(10));

      await queue.cancel();
      await collector.dispose();
    });
  });
}
