import 'package:flutter/foundation.dart';

import 'ai_error.dart';

/// Immutable value object describing the outcome of an AI summarization call.
@immutable
class AiSummaryResult {
  /// The generated summary text (<=120 words by spec).
  final String summaryText;

  /// Optional action hints that suggest follow-up steps.
  final List<String> actionHints;

  /// Token usage reported by the provider (0 if unknown).
  final int tokensUsed;

  /// End-to-end latency in milliseconds.
  final int latencyMs;

  /// Identifier for the provider backing the result (e.g. fake, together).
  final String provider;

  /// Confidence score between 0.0 and 1.0 (clamped inside constructor).
  final double confidence;

  /// Populated when the AI call failed or returned a degraded response.
  final AiError? error;

  AiSummaryResult({
    required this.summaryText,
    List<String> actionHints = const [],
    required this.tokensUsed,
    required this.latencyMs,
    required this.provider,
    double confidence = 0.0,
    this.error,
  })  : actionHints = List.unmodifiable(actionHints),
        confidence = _clampConfidence(confidence);

  /// Convenience factory for a successful AI response.
  factory AiSummaryResult.success({
    required String summaryText,
    List<String> actionHints = const [],
    int tokensUsed = 0,
    int latencyMs = 0,
    String provider = 'unknown',
    double confidence = 0.0,
  }) {
    return AiSummaryResult(
      summaryText: summaryText,
      actionHints: actionHints,
      tokensUsed: tokensUsed,
      latencyMs: latencyMs,
      provider: provider,
      confidence: confidence,
    );
  }

  /// Convenience factory for a failed AI response.
  factory AiSummaryResult.failure({
    required AiError error,
    int tokensUsed = 0,
    int latencyMs = 0,
    String provider = 'unknown',
    double confidence = 0.0,
  }) {
    return AiSummaryResult(
      summaryText: '',
      actionHints: const [],
      tokensUsed: tokensUsed,
      latencyMs: latencyMs,
      provider: provider,
      confidence: confidence,
      error: error,
    );
  }

  /// Returns true when the AI request completed without errors.
  bool get isSuccess => error == null;

  static double _clampConfidence(double value) {
    if (value.isNaN) return 0.0;
    if (value < 0.0) return 0.0;
    if (value > 1.0) return 1.0;
    return value;
  }
}
