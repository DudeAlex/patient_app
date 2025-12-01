import 'package:flutter/foundation.dart';
import 'scored_record.dart';
import 'retrieval_stats.dart';

/// Represents the result of an intent-driven retrieval operation.
@immutable
class RetrievalResult {
  const RetrievalResult({
    required this.records,
    required this.stats,
  });

  /// The scored records that match the query, sorted by relevance.
  final List<ScoredRecord> records;

  /// Statistics about the retrieval operation.
  final RetrievalStats stats;

 RetrievalResult copyWith({
    List<ScoredRecord>? records,
    RetrievalStats? stats,
  }) {
    return RetrievalResult(
      records: records ?? this.records,
      stats: stats ?? this.stats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'records': records.map((record) => record.toJson()).toList(),
      'stats': stats.toJson(),
    };
 }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RetrievalResult &&
        listEquals(other.records, records) &&
        other.stats == stats;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(records),
      stats,
    );
 }
}