import 'package:flutter/foundation.dart';

/// Statistics about a retrieval operation.
@immutable
class RetrievalStats {
  const RetrievalStats({
    required this.recordsConsidered,
    required this.recordsMatched,
    required this.recordsIncluded,
    required this.recordsExcludedPrivacy,
    required this.recordsExcludedThreshold,
    required this.retrievalTime,
  });

  /// Total number of records considered during retrieval.
  final int recordsConsidered;

  /// Number of records that matched the query criteria.
  final int recordsMatched;

  /// Number of records ultimately included in the result.
  final int recordsIncluded;

  /// Number of records excluded due to privacy filters.
  final int recordsExcludedPrivacy;

  /// Number of records excluded due to relevance threshold.
  final int recordsExcludedThreshold;

  /// Time taken to complete the retrieval operation.
  final Duration retrievalTime;

  RetrievalStats copyWith({
    int? recordsConsidered,
    int? recordsMatched,
    int? recordsIncluded,
    int? recordsExcludedPrivacy,
    int? recordsExcludedThreshold,
    Duration? retrievalTime,
  }) {
    return RetrievalStats(
      recordsConsidered: recordsConsidered ?? this.recordsConsidered,
      recordsMatched: recordsMatched ?? this.recordsMatched,
      recordsIncluded: recordsIncluded ?? this.recordsIncluded,
      recordsExcludedPrivacy: recordsExcludedPrivacy ?? this.recordsExcludedPrivacy,
      recordsExcludedThreshold: recordsExcludedThreshold ?? this.recordsExcludedThreshold,
      retrievalTime: retrievalTime ?? this.retrievalTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recordsConsidered': recordsConsidered,
      'recordsMatched': recordsMatched,
      'recordsIncluded': recordsIncluded,
      'recordsExcludedPrivacy': recordsExcludedPrivacy,
      'recordsExcludedThreshold': recordsExcludedThreshold,
      'retrievalTimeMs': retrievalTime.inMilliseconds,
    };
  }

 @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RetrievalStats &&
        other.recordsConsidered == recordsConsidered &&
        other.recordsMatched == recordsMatched &&
        other.recordsIncluded == recordsIncluded &&
        other.recordsExcludedPrivacy == recordsExcludedPrivacy &&
        other.recordsExcludedThreshold == recordsExcludedThreshold &&
        other.retrievalTime == retrievalTime;
 }

  @override
  int get hashCode {
    return Object.hash(
      recordsConsidered,
      recordsMatched,
      recordsIncluded,
      recordsExcludedPrivacy,
      recordsExcludedThreshold,
      retrievalTime,
    );
  }
}