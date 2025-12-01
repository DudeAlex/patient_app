import 'package:flutter/foundation.dart';

/// Configuration for intent-driven retrieval system.
@immutable
class IntentRetrievalConfig {
  const IntentRetrievalConfig({
    this.enabled = true,
    this.relevanceThreshold = 0.3,
    this.maxResults = 15,
    this.minQueryWords = 3,
    this.maxKeywords = 10,
    this.contextLookback = 2,
    this.allowCrossSpace = true,
  });

  /// Whether intent-driven retrieval is enabled.
  final bool enabled;

  /// Minimum relevance score for a record to be included (0.0-1.0).
  final double relevanceThreshold;

  /// Maximum number of results to return.
  final int maxResults;

  /// Minimum number of words in a query before using intent-driven retrieval.
  final int minQueryWords;

  /// Maximum number of keywords to extract from a query.
  final int maxKeywords;

  /// Number of previous messages to consider for context.
  final int contextLookback;

  /// Whether to allow cross-space retrieval when explicitly mentioned.
  final bool allowCrossSpace;

  IntentRetrievalConfig copyWith({
    bool? enabled,
    double? relevanceThreshold,
    int? maxResults,
    int? minQueryWords,
    int? maxKeywords,
    int? contextLookback,
    bool? allowCrossSpace,
  }) {
    return IntentRetrievalConfig(
      enabled: enabled ?? this.enabled,
      relevanceThreshold: relevanceThreshold ?? this.relevanceThreshold,
      maxResults: maxResults ?? this.maxResults,
      minQueryWords: minQueryWords ?? this.minQueryWords,
      maxKeywords: maxKeywords ?? this.maxKeywords,
      contextLookback: contextLookback ?? this.contextLookback,
      allowCrossSpace: allowCrossSpace ?? this.allowCrossSpace,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'relevanceThreshold': relevanceThreshold,
      'maxResults': maxResults,
      'minQueryWords': minQueryWords,
      'maxKeywords': maxKeywords,
      'contextLookback': contextLookback,
      'allowCrossSpace': allowCrossSpace,
    };
  }

  factory IntentRetrievalConfig.fromJson(Map<String, dynamic> json) {
    return IntentRetrievalConfig(
      enabled: json['enabled'] ?? true,
      relevanceThreshold: (json['relevanceThreshold'] as num?)?.toDouble() ?? 0.3,
      maxResults: json['maxResults'] ?? 15,
      minQueryWords: json['minQueryWords'] ?? 3,
      maxKeywords: json['maxKeywords'] ?? 10,
      contextLookback: json['contextLookback'] ?? 2,
      allowCrossSpace: json['allowCrossSpace'] ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IntentRetrievalConfig &&
        other.enabled == enabled &&
        other.relevanceThreshold == relevanceThreshold &&
        other.maxResults == maxResults &&
        other.minQueryWords == minQueryWords &&
        other.maxKeywords == maxKeywords &&
        other.contextLookback == contextLookback &&
        other.allowCrossSpace == allowCrossSpace;
  }

  @override
  int get hashCode {
    return Object.hash(
      enabled,
      relevanceThreshold,
      maxResults,
      minQueryWords,
      maxKeywords,
      contextLookback,
      allowCrossSpace,
    );
  }
}