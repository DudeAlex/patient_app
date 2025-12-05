import 'dart:async';

import 'package:patient_app/core/ai/chat/security/interfaces/security_monitor.dart';
import 'package:patient_app/core/ai/chat/security/models/security_event.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';

typedef SecurityEventSink = FutureOr<void> Function(SecurityEvent event);

/// In-memory security monitor with basic suspicious activity detection.
class SecurityMonitorImpl implements SecurityMonitor {
  SecurityMonitorImpl({
    Duration? retention,
    DateTime Function()? clock,
    this.telemetrySink,
  })  : _retention = retention ?? const Duration(hours: 24),
        _clock = clock ?? DateTime.now;

  final Duration _retention;
  final DateTime Function() _clock;
  final SecurityEventSink? telemetrySink;
  final List<SecurityEvent> _events = [];

  @override
  Future<void> logEvent({
    required SecurityEventType type,
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    _prune();
    final event = SecurityEvent(
      type: type,
      userId: userId,
      timestamp: _clock(),
      metadata: metadata ?? const {},
    );
    _events.add(event);

    // Forward to telemetry pipeline if available.
    if (telemetrySink != null) {
      await telemetrySink!(event);
    }

    // Emit to logger to aid investigations (message kept concise).
    await AppLogger.info(
      'Security event recorded: ${event.type}',
      context: {
        if (event.userId != null) 'userId': event.userId,
        'timestamp': event.timestamp.toIso8601String(),
        if (event.metadata.isNotEmpty) 'metadata': event.metadata,
      },
    );
  }

  @override
  Future<List<SecurityEvent>> getRecentEvents({
    Duration window = const Duration(hours: 24),
  }) async {
    _prune();
    final cutoff = _clock().subtract(window);
    return _events.where((e) => e.timestamp.isAfter(cutoff) || e.timestamp.isAtSameMomentAs(cutoff)).toList();
  }

  @override
  Future<bool> isSuspiciousActivity({required String userId}) async {
    _prune();
    final now = _clock();
    final userEvents = _events.where((e) => e.userId == userId).toList();

    bool exceeds(SecurityEventType type, Duration window, int threshold) {
      final count = _countWithin(userEvents, type, now, window);
      return count >= threshold;
    }

    final authBursts = exceeds(SecurityEventType.authenticationFailure, const Duration(minutes: 10), 3);
    final validationBursts = exceeds(SecurityEventType.inputValidationFailure, const Duration(minutes: 5), 3);
    final rateLimitBursts = exceeds(SecurityEventType.rateLimitViolation, const Duration(minutes: 10), 3);
    final mixedBursts = _hasMixedBurst(userEvents, now);

    return authBursts || validationBursts || rateLimitBursts || mixedBursts;
  }

  int _countWithin(
    List<SecurityEvent> events,
    SecurityEventType type,
    DateTime now,
    Duration window,
  ) {
    final cutoff = now.subtract(window);
    return events
        .where((e) => e.type == type && (e.timestamp.isAfter(cutoff) || e.timestamp.isAtSameMomentAs(cutoff)))
        .length;
  }

  bool _hasMixedBurst(List<SecurityEvent> events, DateTime now) {
    final cutoff = now.subtract(const Duration(hours: 1));
    final recent = events.where((e) => e.timestamp.isAfter(cutoff)).toList();
    if (recent.length < 5) return false;
    final distinctTypes = recent.map((e) => e.type).toSet().length;
    return distinctTypes >= 3;
  }

  void _prune() {
    final cutoff = _clock().subtract(_retention);
    _events.removeWhere((e) => e.timestamp.isBefore(cutoff));
  }
}
