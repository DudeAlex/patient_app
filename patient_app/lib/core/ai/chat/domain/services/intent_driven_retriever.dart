import 'dart:math' as math;
import 'package:patient_app/core/ai/chat/domain/services/relevance_scorer.dart';
import 'package:patient_app/core/ai/chat/domain/services/privacy_filter.dart';
import 'package:patient_app/core/ai/chat/models/query_analysis.dart';
import 'package:patient_app/core/ai/chat/models/retrieval_result.dart';
import 'package:patient_app/core/ai/chat/models/retrieval_stats.dart';
import 'package:patient_app/core/ai/chat/models/intent_retrieval_config.dart';
import 'package:patient_app/core/ai/chat/models/scored_record.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

/// Retrieves records based on user intent and query analysis for Stage 6.
/// 
/// This service orchestrates the intent-driven retrieval process:
/// 1. Apply privacy filter first
/// 2. Score all remaining records by relevance
/// 3. Filter by relevance threshold (0.3)
/// 4. Sort by relevance score (descending)
/// 5. Apply tie-breaking (recency, then viewCount)
/// 6. Take top 15 results
/// 7. Create RetrievalStats
/// 8. Log retrieval results
class IntentDrivenRetriever {
  /// Creates an IntentDrivenRetriever with required dependencies.
  /// 
  /// [relevanceScorer] - Used to score records by relevance
  /// [privacyFilter] - Used to filter out private/deleted records
 /// [config] - Configuration for retrieval behavior
  IntentDrivenRetriever({
    required RelevanceScorer relevanceScorer,
    required PrivacyFilter privacyFilter,
    required IntentRetrievalConfig config,
  })  : _relevanceScorer = relevanceScorer,
        _privacyFilter = privacyFilter,
        _config = config;

  final RelevanceScorer _relevanceScorer;
  final PrivacyFilter _privacyFilter;
 final IntentRetrievalConfig _config;

  /// Retrieves relevant records based on query analysis.
  /// 
  /// [query] The analyzed query with keywords and intent
 /// [candidateRecords] The list of records to consider for retrieval
  /// [activeSpaceId] The current active space ID for space isolation
 /// 
  /// Returns a RetrievalResult containing scored records and statistics
 /// 
  /// Requirements: 3.1-3.5, 4.1-4.5, 6.1-6.5, 9.2, 9.4, 11.1, 11.2, 11.4, 11.5
  Future<RetrievalResult> retrieve({
    required QueryAnalysis query,
    required List<RecordEntity> candidateRecords,
    required String activeSpaceId,
  }) async {
    final startTime = DateTime.now();
    
    // Handle edge cases - very short query or no keywords
    if (query.keywords.length < _config.minQueryWords || query.keywords.isEmpty) {
      // Fallback to Stage 4 behavior (return all candidates)
      await _logFallback('short_query', query.keywords.length);
      return _createFallbackResult(candidateRecords, activeSpaceId, startTime);
    }
    
    try {
      // Step 1: Apply privacy filter first (Requirement 6.5)
      final privacyFilteredRecords = _privacyFilter.filter(candidateRecords, activeSpaceId);
      final privacyExclusions = candidateRecords.length - privacyFilteredRecords.length;
      
      // Step 2: Score all remaining records
      final scoredRecords = await _relevanceScorer.scoreRecords(
        records: privacyFilteredRecords,
        keywords: query.keywords,
        now: DateTime.now(),
      );
      
      // Step 3: Filter by relevance threshold (0.3)
      final thresholdFilteredRecords = scoredRecords
          .where((record) => record.relevanceScore >= _config.relevanceThreshold)
          .toList();
      final thresholdExclusions = scoredRecords.length - thresholdFilteredRecords.length;
      
      // Step 4: Sort by relevance score (descending), with tie-breaking
      thresholdFilteredRecords.sort((a, b) {
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
      
      // Step 5: Apply top-K limit (max 15 results)
      final finalRecords = thresholdFilteredRecords.length > _config.maxResults
          ? thresholdFilteredRecords.sublist(0, _config.maxResults)
          : thresholdFilteredRecords;
      
      // Step 6: Create RetrievalStats
      final retrievalTime = DateTime.now().difference(startTime);
      final stats = RetrievalStats(
        recordsConsidered: candidateRecords.length,
        recordsMatched: scoredRecords.length,
        recordsIncluded: finalRecords.length,
        recordsExcludedPrivacy: privacyExclusions,
        recordsExcludedThreshold: thresholdExclusions,
        retrievalTime: retrievalTime,
      );
      
      final result = RetrievalResult(
        records: finalRecords,
        stats: stats,
      );
      
      // Step 7: Log retrieval results
      await _logRetrieval(result, query, retrievalTime);
      
      return result;
    } catch (error, stackTrace) {
      // Handle errors gracefully - fallback to Stage 4 behavior
      await AppLogger.error(
        'Intent-driven retrieval failed, falling back to Stage 4',
        error: error,
        stackTrace: stackTrace,
        context: {
          'category': 'intent_retrieval',
          'event': 'retrieval_error',
          'originalQuery': query.originalQuery,
          'candidateCount': candidateRecords.length,
        },
      );
      
      // Return all candidates as fallback (Stage 4 behavior)
      return _createFallbackResult(candidateRecords, activeSpaceId, startTime);
    }
  }
  
  /// Creates a fallback result when intent retrieval fails or query is too short.
  /// This returns all candidate records that pass privacy filter (Stage 4 behavior).
  RetrievalResult _createFallbackResult(
    List<RecordEntity> candidateRecords,
    String activeSpaceId,
    DateTime startTime,
  ) {
    // Apply only privacy filter for fallback
    final privacyFilteredRecords = _privacyFilter.filter(candidateRecords, activeSpaceId);
    
    // Convert to ScoredRecord with neutral scores (1.0 for all)
    final scoredRecords = privacyFilteredRecords.map((record) => ScoredRecord(
      record: record,
      relevanceScore: 1.0,
      keywordMatchScore: 1.0,
      recencyScore: 1.0,
    )).toList();
    
    final retrievalTime = DateTime.now().difference(startTime);
    final stats = RetrievalStats(
      recordsConsidered: candidateRecords.length,
      recordsMatched: scoredRecords.length,
      recordsIncluded: scoredRecords.length,
      recordsExcludedPrivacy: candidateRecords.length - scoredRecords.length,
      recordsExcludedThreshold: 0, // No threshold filtering in fallback
      retrievalTime: retrievalTime,
    );
    
    return RetrievalResult(
      records: scoredRecords,
      stats: stats,
    );
  }
  
  /// Logs retrieval results for monitoring and debugging.
  Future<void> _logRetrieval(
    RetrievalResult result,
    QueryAnalysis query,
    Duration retrievalTime,
  ) async {
    await AppLogger.info(
      'Intent-driven retrieval complete',
      context: {
        'category': 'intent_retrieval',
        'event': 'retrieval_complete',
        'originalQuery': query.originalQuery,
        'queryIntent': query.intent.name,
        'queryIntentConfidence': query.intentConfidence,
        'queryKeywordCount': query.keywords.length,
        'queryKeywords': query.keywords,
        'recordsConsidered': result.stats.recordsConsidered,
        'recordsMatched': result.stats.recordsMatched,
        'recordsIncluded': result.stats.recordsIncluded,
        'recordsExcludedPrivacy': result.stats.recordsExcludedPrivacy,
        'recordsExcludedThreshold': result.stats.recordsExcludedThreshold,
        'topScores': result.records.take(10).map((sr) => {
          'recordId': sr.record.id,
          'title': sr.record.title,
          'relevanceScore': sr.relevanceScore.toStringAsFixed(3),
          'keywordMatchScore': sr.keywordMatchScore.toStringAsFixed(3),
          'recencyScore': sr.recencyScore.toStringAsFixed(3),
          'date': sr.record.date.toIso8601String(),
          'viewCount': sr.record.viewCount,
        }).toList(),
        'retrievalTimeMs': retrievalTime.inMilliseconds,
        'config': {
          'enabled': _config.enabled,
          'relevanceThreshold': _config.relevanceThreshold,
          'maxResults': _config.maxResults,
          'minQueryWords': _config.minQueryWords,
        },
      },
    );
  }
  
  /// Logs when retrieval falls back to Stage 4 behavior.
  Future<void> _logFallback(String reason, int keywordCount) async {
    await AppLogger.info(
      'Intent-driven retrieval fell back to Stage 4 behavior',
      context: {
        'category': 'intent_retrieval',
        'event': 'retrieval_fallback',
        'fallbackReason': reason,
        'keywordCount': keywordCount,
        'minQueryWords': _config.minQueryWords,
        'config': {
          'enabled': _config.enabled,
          'relevanceThreshold': _config.relevanceThreshold,
          'maxResults': _config.maxResults,
          'minQueryWords': _config.minQueryWords,
        },
      },
    );
  }
}