import 'dart:math' as math;
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';
import 'package:patient_app/core/ai/chat/models/scored_record.dart';

/// Scores records based on keyword match and recency for intent-driven retrieval.
/// 
/// This service implements the relevance scoring algorithm for Stage 6 intent-driven retrieval:
/// - Calculates keyword match score by searching for query keywords in record fields
/// - Calculates recency score based on how recent the record is
/// - Combines scores using 60% keyword match + 40% recency weighting
/// - Supports case-insensitive matching for multiple languages
class RelevanceScorer {
  /// Scores a record based on keyword match and recency.
  ///
  /// [record] The record to score
 /// [keywords] The keywords to match against the record
  /// [now] The current time for recency calculation (defaults to DateTime.now())
  ///
  /// Returns a relevance score between 0.0 and 1.0
  ///
 /// Requirements: 3.1, 3.2, 3.3, 4.1
  double score({
    required RecordEntity record,
    required List<String> keywords,
    DateTime? now,
  }) {
    final stopwatch = Stopwatch()..start();
    
    if (keywords.isEmpty) {
      stopwatch.stop();
      // Log scoring time
      AppLogger.info(
        'Relevance scoring completed',
        context: {
          'category': 'intent_retrieval',
          'event': 'relevance_scoring',
          'recordId': record.id,
          'recordTitle': record.title,
          'keywordCount': keywords.length,
          'scoringTimeMs': stopwatch.elapsedMilliseconds,
        },
      );
      
      // Log warning if slow
      if (stopwatch.elapsedMilliseconds > 100) {
        AppLogger.warning(
          'Relevance scoring slow',
          context: {
            'category': 'intent_retrieval',
            'event': 'relevance_scoring_slow',
            'recordId': record.id,
            'recordTitle': record.title,
            'keywordCount': keywords.length,
            'scoringTimeMs': stopwatch.elapsedMilliseconds,
            'thresholdMs': 100,
          },
        );
      }
      
      return 0.0;
    }

    now ??= DateTime.now();
    
    final keywordScore = keywordMatchScore(record, keywords);
    final recencyScoreValue = recencyScore(record, now);
    
    // Combine scores with 60% keyword match + 40% recency weighting
    final relevanceScore = (keywordScore * 0.6) + (recencyScoreValue * 0.4);
    
    stopwatch.stop();
    
    // Log scoring time
    AppLogger.info(
      'Relevance scoring completed',
      context: {
        'category': 'intent_retrieval',
        'event': 'relevance_scoring',
        'recordId': record.id,
        'recordTitle': record.title,
        'keywordCount': keywords.length,
        'scoringTimeMs': stopwatch.elapsedMilliseconds,
        'relevanceScore': relevanceScore,
      },
    );
    
    // Log warning if slow
    if (stopwatch.elapsedMilliseconds > 100) {
      AppLogger.warning(
        'Relevance scoring slow',
        context: {
          'category': 'intent_retrieval',
          'event': 'relevance_scoring_slow',
          'recordId': record.id,
          'recordTitle': record.title,
          'keywordCount': keywords.length,
          'scoringTimeMs': stopwatch.elapsedMilliseconds,
          'thresholdMs': 100,
          'relevanceScore': relevanceScore,
        },
      );
    }
    
    return relevanceScore;
  }

  /// Calculates the keyword match score for a record.
  /// 
  /// Searches for keywords in record title, category, and notes fields.
  /// Uses case-insensitive matching.
  /// 
  /// Returns a score between 0.0 and 1.0 based on matched keywords / total keywords
  /// 
  /// Requirements: 3.1, 3.2, 3.3
  double keywordMatchScore(RecordEntity record, List<String> keywords) {
    if (keywords.isEmpty) {
      return 0.0;
    }

    int matchedKeywords = 0;
    
    // Search in title, type (category), and text (notes)
    final searchFields = [
      record.title.toLowerCase(),
      record.type.toLowerCase(),
      record.text?.toLowerCase() ?? '',
    ];

    for (final keyword in keywords) {
      bool keywordFound = false;
      
      for (final field in searchFields) {
        if (containsKeyword(field, keyword)) {
          keywordFound = true;
          break;
        }
      }
      
      if (keywordFound) {
        matchedKeywords++;
      }
    }

    // Calculate score as matched keywords / total keywords
    final score = matchedKeywords / keywords.length;
    return math.min(1.0, score); // Ensure score is between 0.0 and 1.0
  }

  /// Calculates the recency score for a record.
  /// 
 /// Uses the record's date field to calculate how recent it is.
  /// More recent records get higher scores.
  /// 
  /// Returns a score between 0.0 and 1.0
  /// 
 /// Requirements: 4.1
  double recencyScore(RecordEntity record, DateTime now) {
    final daysSinceCreated = now.difference(record.createdAt).inDays;
    
    // Calculate score based on days since creation
    // 0 days = 1.0 (most recent), 90+ days = 0.0 (oldest)
    // For future dates (negative days), return 1.0 as most relevant
    if (daysSinceCreated < 0) {
      return 1.0; // Future dates get maximum score
    }
    
    final score = math.max(0.0, 1.0 - (daysSinceCreated / 90.0));
    
    return score;
  }

  /// Helper method to check if text contains a keyword (case-insensitive).
  /// 
 /// Requirements: 3.3
 bool containsKeyword(String text, String keyword) {
    if (text.isEmpty) {
      return false;
    }
    
    if (keyword.isEmpty) {
      return true; // Empty keyword is considered found in any text
    }
    
    return text.toLowerCase().contains(keyword.toLowerCase());
  }

  /// Scores multiple records and returns them as ScoredRecord objects sorted by relevance.
  ///
  /// Requirements: 4.1, 4.2, 4.3
  Future<List<ScoredRecord>> scoreRecords({
    required List<RecordEntity> records,
    required List<String> keywords,
    DateTime? now,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    now ??= DateTime.now();
    
    final scoredRecords = <ScoredRecord>[];
    
    for (final record in records) {
      final keywordScore = keywordMatchScore(record, keywords);
      final recencyScoreValue = recencyScore(record, now);
      final relevanceScore = (keywordScore * 0.6) + (recencyScoreValue * 0.4);
      
      scoredRecords.add(
        ScoredRecord(
          record: record,
          relevanceScore: relevanceScore,
          keywordMatchScore: keywordScore,
          recencyScore: recencyScoreValue,
        ),
      );
    }
    
    // Sort by relevance score (descending), with tie-breaking by recency then viewCount
    scoredRecords.sort((a, b) {
      // Primary sort: relevance score (descending)
      final relevanceComparison = b.relevanceScore.compareTo(a.relevanceScore);
      if (relevanceComparison != 0) {
        return relevanceComparison;
      }
      
      // Secondary sort: recency score (descending)
      final recencyComparison = b.recencyScore.compareTo(a.recencyScore);
      if (recencyComparison != 0) {
        return recencyComparison;
      }
      
      // Tertiary sort: view count (descending) - higher view count first
      return b.record.viewCount.compareTo(a.record.viewCount);
    });
    
    stopwatch.stop();
    
    // Log scoring time
    await AppLogger.info(
      'Relevance scoring completed',
      context: {
        'category': 'intent_retrieval',
        'event': 'relevance_scoring',
        'recordsScored': records.length,
        'keywordCount': keywords.length,
        'scoringTimeMs': stopwatch.elapsedMilliseconds,
      },
    );
    
    // Log warning if slow
    if (stopwatch.elapsedMilliseconds > 100) {
      await AppLogger.warning(
        'Relevance scoring slow',
        context: {
          'category': 'intent_retrieval',
          'event': 'relevance_scoring_slow',
          'recordsScored': records.length,
          'keywordCount': keywords.length,
          'scoringTimeMs': stopwatch.elapsedMilliseconds,
          'thresholdMs': 100,
        },
      );
    }
    
    // Log scoring results for debugging
    await _logScoringResults(scoredRecords, keywords);
    
    return scoredRecords;
  }

  /// Logs scoring results for debugging and monitoring.
  Future<void> _logScoringResults(
    List<ScoredRecord> scoredRecords, 
    List<String> keywords,
  ) async {
    if (scoredRecords.isEmpty) {
      await AppLogger.info(
        'Relevance scoring complete - no records scored',
        context: {
          'category': 'intent_retrieval',
          'event': 'relevance_scoring',
          'keywordCount': keywords.length,
          'keywords': keywords,
          'recordsScored': 0,
        },
      );
      return;
    }

    // Get top 10 scores for logging
    final topScores = scoredRecords
        .take(10)
        .map((sr) => {
          'recordId': sr.record.id,
          'title': sr.record.title,
          'relevanceScore': sr.relevanceScore.toStringAsFixed(3),
          'keywordMatchScore': sr.keywordMatchScore.toStringAsFixed(3),
          'recencyScore': sr.recencyScore.toStringAsFixed(3),
          'date': sr.record.date.toIso8601String(),
          'viewCount': sr.record.viewCount,
        })
        .toList();

    // Calculate statistics
    final scores = scoredRecords.map((sr) => sr.relevanceScore).toList();
    final avgScore = scores.reduce((a, b) => a + b) / scores.length;
    final minScore = scores.reduce((a, b) => a < b ? a : b);
    final maxScore = scores.reduce((a, b) => a > b ? a : b);

    await AppLogger.info(
      'Relevance scoring complete',
      context: {
        'category': 'intent_retrieval',
        'event': 'relevance_scoring',
        'keywordCount': keywords.length,
        'keywords': keywords,
        'recordsScored': scoredRecords.length,
        'topScores': topScores,
        'avgScore': avgScore.toStringAsFixed(3),
        'minScore': minScore.toStringAsFixed(3),
        'maxScore': maxScore.toStringAsFixed(3),
        'scoreDistribution': {
          'high': scoredRecords.where((sr) => sr.relevanceScore >= 0.7).length,
          'medium': scoredRecords.where((sr) => sr.relevanceScore >= 0.3 && sr.relevanceScore < 0.7).length,
          'low': scoredRecords.where((sr) => sr.relevanceScore < 0.3).length,
        },
      },
    );
  }
}