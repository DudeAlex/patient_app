import 'package:flutter/foundation.dart';

import '../../models/ai_error.dart';

/// Structured AI response for chat interactions.
@immutable
class ChatResponse {
  ChatResponse({
    required this.messageContent,
    List<String> actionHints = const [],
    required this.metadata,
    this.error,
  }) : actionHints = List.unmodifiable(actionHints);

  /// AI-generated message text.
  final String messageContent;

  /// Optional follow-up suggestions from the AI.
  final List<String> actionHints;

  /// Provider metadata (tokens, latency, provider id, confidence).
  final AiMessageMetadata metadata;

  /// Populated when the AI call failed or returned a degraded response.
  final AiError? error;

  bool get isSuccess => error == null;

  factory ChatResponse.success({
    required String messageContent,
    List<String> actionHints = const [],
    AiMessageMetadata metadata = AiMessageMetadata.empty,
  }) {
    return ChatResponse(
      messageContent: messageContent,
      actionHints: actionHints,
      metadata: metadata,
    );
  }

  factory ChatResponse.failure({
    required AiError error,
    String messageContent = '',
    List<String> actionHints = const [],
    AiMessageMetadata metadata = AiMessageMetadata.empty,
  }) {
    return ChatResponse(
      messageContent: messageContent,
      actionHints: actionHints,
      metadata: metadata,
      error: error,
    );
  }
}

/// Provider metadata attached to AI messages.
@immutable
class AiMessageMetadata {
  const AiMessageMetadata._raw({
    this.tokensUsed = 0,
    this.latencyMs = 0,
    this.provider = 'unknown',
    this.confidence = 0.0,
    this.finishReason,
  });

  /// Token usage reported by the provider.
  final int tokensUsed;

  /// End-to-end latency in milliseconds.
  final int latencyMs;

  /// Identifier for the backing provider (fake, remote, etc.).
  final String provider;

  /// Confidence score between 0.0 and 1.0.
  final double confidence;

  /// Provider finish reason (stop, length, etc.) when available.
  final String? finishReason;

  AiMessageMetadata copyWith({
    int? tokensUsed,
    int? latencyMs,
    String? provider,
    double? confidence,
    String? finishReason,
  }) {
    return AiMessageMetadata(
      tokensUsed: tokensUsed ?? this.tokensUsed,
      latencyMs: latencyMs ?? this.latencyMs,
      provider: provider ?? this.provider,
      confidence: confidence ?? this.confidence,
      finishReason: finishReason ?? this.finishReason,
    );
  }

  factory AiMessageMetadata({
    int tokensUsed = 0,
    int latencyMs = 0,
    String provider = 'unknown',
    double confidence = 0.0,
    String? finishReason,
  }) {
    return AiMessageMetadata._raw(
      tokensUsed: tokensUsed,
      latencyMs: latencyMs,
      provider: provider,
      confidence: _clampConfidence(confidence),
      finishReason: finishReason,
    );
  }

  static const empty = AiMessageMetadata._raw();

  static double _clampConfidence(double value) {
    if (value.isNaN) return 0.0;
    if (value < 0.0) return 0.0;
    if (value > 1.0) return 1.0;
    return value;
  }
}

/// Chunked response for streaming APIs.
@immutable
class ChatResponseChunk {
  const ChatResponseChunk({
    required this.content,
    required this.isComplete,
  });

  /// Partial or complete response text accumulated so far.
  final String content;

  /// Marks the final chunk in the stream.
  final bool isComplete;
}
