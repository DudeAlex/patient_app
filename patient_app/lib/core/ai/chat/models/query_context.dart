import 'package:flutter/foundation.dart';

/// Represents the context of a query, including conversation history and resolved references.
@immutable
class QueryContext {
  const QueryContext({
    required this.conversationHistory,
    this.resolvedReferences = const {},
  });

  /// The list of previous messages in the conversation.
  final List<String> conversationHistory;

  /// Map of resolved references (e.g., "it" -> "blood pressure").
  final Map<String, String> resolvedReferences;

  QueryContext copyWith({
    List<String>? conversationHistory,
    Map<String, String>? resolvedReferences,
  }) {
    return QueryContext(
      conversationHistory: conversationHistory ?? this.conversationHistory,
      resolvedReferences: resolvedReferences ?? this.resolvedReferences,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationHistory': conversationHistory,
      'resolvedReferences': resolvedReferences,
    };
  }

  factory QueryContext.fromJson(Map<String, dynamic> json) {
    return QueryContext(
      conversationHistory: List<String>.from(json['conversationHistory'] ?? []),
      resolvedReferences: Map<String, String>.from(json['resolvedReferences'] ?? {}),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QueryContext &&
        listEquals(other.conversationHistory, conversationHistory) &&
        mapEquals(other.resolvedReferences, resolvedReferences);
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(conversationHistory),
      Object.hashAll(resolvedReferences.keys),
      Object.hashAll(resolvedReferences.values),
    );
  }
}
