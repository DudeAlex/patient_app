import 'package:flutter/foundation.dart';
import 'query_intent.dart';

/// Represents the analysis of a user query including extracted keywords, entities, and intent.
@immutable
class QueryAnalysis {
  const QueryAnalysis({
    required this.originalQuery,
    required this.keywords,
    required this.intent,
    required this.intentConfidence,
  });

  /// The original query text provided by the user.
  final String originalQuery;

  /// Keywords extracted from the query for matching against records.
  final List<String> keywords;

  /// The classified intent of the query (question, command, statement, greeting).
  final QueryIntent intent;

  /// Confidence score for the intent classification (0.0-1.0).
  final double intentConfidence;

  QueryAnalysis copyWith({
    String? originalQuery,
    List<String>? keywords,
    QueryIntent? intent,
    double? intentConfidence,
  }) {
    return QueryAnalysis(
      originalQuery: originalQuery ?? this.originalQuery,
      keywords: keywords ?? this.keywords,
      intent: intent ?? this.intent,
      intentConfidence: intentConfidence ?? this.intentConfidence,
    );
  }

 Map<String, dynamic> toJson() {
    return {
      'originalQuery': originalQuery,
      'keywords': keywords,
      'intent': intent.name,
      'intentConfidence': intentConfidence,
    };
  }

  factory QueryAnalysis.fromJson(Map<String, dynamic> json) {
    return QueryAnalysis(
      originalQuery: json['originalQuery'] as String,
      keywords: List<String>.from(json['keywords'] as List),
      intent: QueryIntent.values.firstWhere(
        (e) => e.name == json['intent'],
        orElse: () => QueryIntent.question,
      ),
      intentConfidence: json['intentConfidence']?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QueryAnalysis &&
        other.originalQuery == originalQuery &&
        listEquals(other.keywords, keywords) &&
        other.intent == intent &&
        other.intentConfidence == intentConfidence;
  }

  @override
  int get hashCode {
    return Object.hash(
      originalQuery,
      Object.hashAll(keywords),
      intent,
      intentConfidence,
    );
  }
}