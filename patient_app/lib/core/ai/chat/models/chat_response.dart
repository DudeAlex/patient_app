import 'package:flutter/foundation.dart';

import '../../models/ai_error.dart';
import 'context_stats.dart';

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
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.latencyMs = 0,
    this.provider = 'unknown',
    this.confidence = 0.0,
    this.finishReason,
    this.modelVersion,
    this.contextStats,
  });

  /// Token usage reported by the provider.
  final int tokensUsed;

  /// Prompt-side tokens reported by the provider.
  final int promptTokens;

  /// Completion-side tokens reported by the provider.
  final int completionTokens;

  /// End-to-end latency in milliseconds.
  final int latencyMs;

  /// Identifier for the backing provider (fake, remote, etc.).
  final String provider;

  /// Confidence score between 0.0 and 1.0.
  final double confidence;

  /// Provider finish reason (stop, length, etc.) when available.
  final String? finishReason;

  /// Model version identifier when provided by the backend.
  final String? modelVersion;

  /// Context assembly statistics (Stage 4).
  final ContextStats? contextStats;

  AiMessageMetadata copyWith({
    int? tokensUsed,
    int? promptTokens,
    int? completionTokens,
    int? latencyMs,
    String? provider,
    double? confidence,
    String? finishReason,
    String? modelVersion,
    ContextStats? contextStats,
  }) {
    return AiMessageMetadata(
      tokensUsed: tokensUsed ?? this.tokensUsed,
      promptTokens: promptTokens ?? this.promptTokens,
      completionTokens: completionTokens ?? this.completionTokens,
      latencyMs: latencyMs ?? this.latencyMs,
      provider: provider ?? this.provider,
      confidence: confidence ?? this.confidence,
      finishReason: finishReason ?? this.finishReason,
      modelVersion: modelVersion ?? this.modelVersion,
      contextStats: contextStats ?? this.contextStats,
    );
  }

  factory AiMessageMetadata({
    int tokensUsed = 0,
    int promptTokens = 0,
    int completionTokens = 0,
    int latencyMs = 0,
    String provider = 'unknown',
    double confidence = 0.0,
    String? finishReason,
    String? modelVersion,
    ContextStats? contextStats,
  }) {
    return AiMessageMetadata._raw(
      tokensUsed: tokensUsed,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      latencyMs: latencyMs,
      provider: provider,
      confidence: _clampConfidence(confidence),
      finishReason: finishReason,
      modelVersion: modelVersion,
      contextStats: contextStats,
    );
  }

  factory AiMessageMetadata.fromJson(Map<String, dynamic> json) {
    ContextStats? stats;
    if (json['contextStats'] != null) {
      final statsJson = json['contextStats'] as Map<String, dynamic>;
      stats = ContextStats(
        recordsFiltered: statsJson['recordsFiltered'] as int? ?? 0,
        recordsIncluded: statsJson['recordsIncluded'] as int? ?? 0,
        tokensEstimated: statsJson['tokensEstimated'] as int? ?? 0,
        tokensAvailable: statsJson['tokensAvailable'] as int? ?? 0,
        compressionRatio: (statsJson['compressionRatio'] as num?)?.toDouble() ?? 0.0,
        assemblyTime: Duration(milliseconds: statsJson['assemblyTimeMs'] as int? ?? 0),
      );
    }

    int promptTokens = 0;
    int completionTokens = 0;
    final tokenUsage = json['tokenUsage'] as Map<String, dynamic>?;
    if (tokenUsage != null) {
      promptTokens = tokenUsage['prompt'] as int? ?? 0;
      completionTokens = tokenUsage['completion'] as int? ?? 0;
    }

    return AiMessageMetadata(
      tokensUsed: json['tokensUsed'] as int? ?? (tokenUsage?['total'] as int? ?? 0),
      promptTokens: json['promptTokens'] as int? ?? promptTokens,
      completionTokens: json['completionTokens'] as int? ?? completionTokens,
      latencyMs: json['latencyMs'] as int? ?? 0,
      provider: json['provider'] as String? ?? 'unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      finishReason: json['finishReason'] as String?,
      modelVersion: json['modelVersion'] as String?,
      contextStats: stats,
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
