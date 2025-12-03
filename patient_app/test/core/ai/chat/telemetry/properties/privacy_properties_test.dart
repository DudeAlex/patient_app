import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/telemetry/services/telemetry_collector_impl.dart';
import 'package:patient_app/core/ai/chat/telemetry/models/telemetry_event.dart';

void main() {
  group('Telemetry Property 12: Privacy preservation', () {
    test('no message content or raw PII in telemetry payloads', () async {
      final collector = TelemetryCollectorImpl();
      final queue = StreamQueue<TelemetryEvent>(collector.events);

      final requestId = collector.startRequest(
        userId: 'user-sensitive-123',
        spaceId: 'space-1',
        messageId: 'msg-1',
      );

      final startEvent = await queue.next;
      expect(startEvent.payload.containsKey('message'), isFalse);
      expect(startEvent.payload.containsKey('messageContent'), isFalse);
      expect(startEvent.payload['userId'], isNot('user-sensitive-123'));

      await collector.recordError(
        requestId: requestId,
        errorType: 'network',
        errorMessage: 'offline',
      );

      final errorEvent = await queue.next;
      final payloadValues = errorEvent.payload.values.join(' ');
      expect(payloadValues.contains('user-sensitive-123'), isFalse);

      await queue.cancel();
      await collector.dispose();
    });
  });
}
