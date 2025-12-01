import 'package:flutter/foundation.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

/// Represents a record with its relevance score for a specific query.
@immutable
class ScoredRecord implements Comparable<ScoredRecord> {
  const ScoredRecord({
    required this.record,
    required this.relevanceScore,
    required this.keywordMatchScore,
    required this.recencyScore,
  });

  /// The original record that was scored.
  final RecordEntity record;

  /// The overall relevance score (0.0-1.0), combining keyword match and recency.
  final double relevanceScore;

  /// The score based on keyword matching (0.0-1.0).
  final double keywordMatchScore;

  /// The score based on recency (0.0-1.0).
  final double recencyScore;

  /// Compares this ScoredRecord to another for sorting purposes.
  /// Sorts by relevanceScore in descending order (highest first).
  @override
  int compareTo(ScoredRecord other) {
    return other.relevanceScore.compareTo(relevanceScore);
  }

  /// Checks if this ScoredRecord has a higher relevance score than another.
  bool operator >(ScoredRecord other) {
    return relevanceScore > other.relevanceScore;
  }

  /// Checks if this ScoredRecord has a lower relevance score than another.
  bool operator <(ScoredRecord other) {
    return relevanceScore < other.relevanceScore;
  }

  /// Checks if this ScoredRecord has a higher or equal relevance score than another.
  bool operator >=(ScoredRecord other) {
    return relevanceScore >= other.relevanceScore;
  }

  /// Checks if this ScoredRecord has a lower or equal relevance score than another.
  bool operator <=(ScoredRecord other) {
    return relevanceScore <= other.relevanceScore;
  }

  ScoredRecord copyWith({
    RecordEntity? record,
    double? relevanceScore,
    double? keywordMatchScore,
    double? recencyScore,
  }) {
    return ScoredRecord(
      record: record ?? this.record,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      keywordMatchScore: keywordMatchScore ?? this.keywordMatchScore,
      recencyScore: recencyScore ?? this.recencyScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'relevanceScore': relevanceScore,
      'keywordMatchScore': keywordMatchScore,
      'recencyScore': recencyScore,
      'record': {
        'id': record.id,
        'spaceId': record.spaceId,
        'type': record.type,
        'date': record.date.toIso8601String(),
        'title': record.title,
        'text': record.text,
        'tags': record.tags,
        'createdAt': record.createdAt.toIso8601String(),
        'updatedAt': record.updatedAt.toIso8601String(),
        'deletedAt': record.deletedAt?.toIso8601String(),
        'viewCount': record.viewCount,
      },
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScoredRecord &&
        other.record.id == record.id &&
        other.relevanceScore == relevanceScore &&
        other.keywordMatchScore == keywordMatchScore &&
        other.recencyScore == recencyScore;
  }

  @override
  int get hashCode {
    return Object.hash(
      record.id,
      relevanceScore,
      keywordMatchScore,
      recencyScore,
    );
  }
}