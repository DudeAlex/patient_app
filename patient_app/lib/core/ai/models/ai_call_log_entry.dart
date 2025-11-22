import 'package:flutter/foundation.dart';

@immutable
class AiCallLogEntry {
  const AiCallLogEntry({
    required this.timestamp,
    required this.spaceId,
    required this.domainId,
    required this.provider,
    required this.latencyMs,
    required this.tokensUsed,
    required this.success,
    this.confidence = 0,
    this.errorMessage,
  });

  final DateTime timestamp;
  final String spaceId;
  final String domainId;
  final String provider;
  final int latencyMs;
  final int tokensUsed;
  final bool success;
  final double confidence;
  final String? errorMessage;
}
