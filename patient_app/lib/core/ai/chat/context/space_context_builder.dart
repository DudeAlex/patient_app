import 'package:patient_app/core/ai/chat/application/interfaces/space_context_builder.dart';
import 'package:patient_app/core/ai/chat/context/context_filter_engine.dart';
import 'package:patient_app/core/ai/chat/context/context_truncation_strategy.dart';
import 'package:patient_app/core/ai/chat/context/record_relevance_scorer.dart';
import 'package:patient_app/core/ai/chat/context/record_summary_formatter.dart';
import 'package:patient_app/core/ai/chat/domain/services/intent_driven_retriever.dart';
import 'package:patient_app/core/ai/chat/domain/services/query_analyzer.dart';
import 'package:patient_app/core/ai/chat/domain/services/relevance_scorer.dart';
import 'package:patient_app/core/ai/chat/domain/services/privacy_filter.dart';
import 'package:patient_app/core/ai/chat/domain/services/keyword_extractor.dart';
import 'package:patient_app/core/ai/chat/domain/services/intent_classifier.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/chat/models/context_filters.dart';
import 'package:patient_app/core/ai/chat/models/context_stats.dart';
import 'package:patient_app/core/ai/chat/models/date_range.dart';
import 'package:patient_app/core/ai/chat/models/intent_retrieval_config.dart';
import 'package:patient_app/core/ai/chat/models/token_allocation.dart';
import 'package:patient_app/core/ai/chat/context/token_budget_allocator.dart';
import 'package:patient_app/core/application/services/space_manager.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:patient_app/core/domain/entities/space.dart';
import 'package:patient_app/features/records/application/ports/records_repository.dart';
import 'package:patient_app/features/records/data/records_service.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

/// Builds SpaceContext using space metadata and recent records.
class SpaceContextBuilderImpl implements SpaceContextBuilder {
  SpaceContextBuilderImpl({
    required Future<RecordsService> recordsServiceFuture,
    RecordsRepository? recordsRepositoryOverride,
    required SpaceManager spaceManager,
    ContextFilterEngine? filterEngine,
    RecordRelevanceScorer? relevanceScorer,
    TokenBudgetAllocator? tokenBudgetAllocator,
    TokenAllocation? tokenAllocation,
    ContextTruncationStrategy? truncationStrategy,
    IntentDrivenRetriever? intentDrivenRetriever,
    QueryAnalyzer? queryAnalyzer,
    IntentRetrievalConfig intentRetrievalConfig = const IntentRetrievalConfig(),
    RecordSummaryFormatter? formatter,
    this.maxRecords = 20,
    DateRange? dateRange,
  })  : _recordsServiceFuture = recordsServiceFuture,
        _recordsRepositoryOverride = recordsRepositoryOverride,
        _spaceManager = spaceManager,
        _filterEngine = filterEngine ?? ContextFilterEngine(),
        _relevanceScorer = relevanceScorer ?? RecordRelevanceScorer(),
        _tokenBudgetAllocator = tokenBudgetAllocator ??
            (tokenAllocation != null
                ? TokenBudgetAllocator(
                    total: tokenAllocation.total,
                    system: tokenAllocation.system,
                    context: tokenAllocation.context,
                    history: tokenAllocation.history,
                    response: tokenAllocation.response,
                  )
                : const TokenBudgetAllocator()),
        _truncationStrategy = truncationStrategy ?? const ContextTruncationStrategy(),
        _intentDrivenRetriever = intentDrivenRetriever ??
            IntentDrivenRetriever(
              relevanceScorer: RelevanceScorer(),
              privacyFilter: PrivacyFilter(),
              config: intentRetrievalConfig,
            ),
        _queryAnalyzer = queryAnalyzer ??
            QueryAnalyzer(
              keywordExtractor: KeywordExtractor(),
              intentClassifier: IntentClassifier(),
            ),
        _intentRetrievalConfig = intentRetrievalConfig,
        _dateRange = dateRange ?? DateRange.last14Days(),
        _formatter = formatter ?? RecordSummaryFormatter();

  final Future<RecordsService> _recordsServiceFuture;
  final RecordsRepository? _recordsRepositoryOverride;
  final SpaceManager _spaceManager;
  final ContextFilterEngine _filterEngine;
  final RecordRelevanceScorer _relevanceScorer;
  final TokenBudgetAllocator _tokenBudgetAllocator;
  final ContextTruncationStrategy _truncationStrategy;
  final IntentDrivenRetriever _intentDrivenRetriever;
  final QueryAnalyzer _queryAnalyzer;
  final IntentRetrievalConfig _intentRetrievalConfig;
  final DateRange _dateRange;
  final RecordSummaryFormatter _formatter;

  /// Maximum records to include in the context payload.
  final int maxRecords;

  @override
  Future<SpaceContext> build(
    String spaceId, {
    DateRange? dateRange,
    String? userQuery,
  }) async {
    final opId = AppLogger.startOperation('space_context_build');
    final stopwatch = Stopwatch()..start();
    final effectiveDateRange = dateRange ?? _dateRange;
    
    await AppLogger.info(
      'Starting space context assembly',
      context: {
        'spaceId': spaceId,
        'maxRecords': maxRecords,
        'dateRangeStart': effectiveDateRange.start.toIso8601String(),
        'dateRangeEnd': effectiveDateRange.end.toIso8601String(),
        'userQueryProvided': userQuery != null,
        'stage': userQuery != null ? 'Stage 6 (Intent-Driven)' : 'Stage 4 (Date-Based)',
      },
      correlationId: opId,
    );
    
    final recordsRepository = _recordsRepositoryOverride ?? (await _recordsServiceFuture).records;
    final activeSpaces = await _spaceManager.getActiveSpaces();
    
    await AppLogger.info(
      'Resolving space for context',
      context: {
        'requestedSpaceId': spaceId,
        'activeSpacesCount': activeSpaces.length,
        'activeSpaceIds': activeSpaces.map((s) => s.id).toList(),
      },
      correlationId: opId,
    );
    
    Space? explicitSpace;
    try {
      explicitSpace = activeSpaces.firstWhere((s) => s.id == spaceId);
      await AppLogger.info(
        'Found requested space in active spaces',
        context: {
          'requestedSpaceId': spaceId,
          'foundSpaceId': explicitSpace.id,
          'foundSpaceName': explicitSpace.name,
        },
        correlationId: opId,
      );
    } catch (_) {
      explicitSpace = null;
      await AppLogger.warning(
        'Requested space not found in active spaces - will use fallback',
        context: {
          'requestedSpaceId': spaceId,
          'activeSpaceIds': activeSpaces.map((s) => s.id).toList(),
        },
        correlationId: opId,
      );
    }

    if (explicitSpace != null) {
      final context = await _buildFromSpace(
        explicitSpace,
        recordsRepository,
        correlationId: opId,
        stopwatch: stopwatch,
        dateRange: effectiveDateRange,
        userQuery: userQuery,
      );
      await AppLogger.endOperation(opId);
      return context;
    }

    // Fallback to current space if requested space is not active.
    final fallbackSpace = await _spaceManager.getCurrentSpace();
    await AppLogger.warning(
      'Using fallback space',
      context: {
        'requestedSpaceId': spaceId,
        'fallbackSpaceId': fallbackSpace.id,
        'fallbackSpaceName': fallbackSpace.name,
      },
      correlationId: opId,
    );
    final context = await _buildFromSpace(
      fallbackSpace,
      recordsRepository,
      correlationId: opId,
      stopwatch: stopwatch,
      dateRange: effectiveDateRange,
      userQuery: userQuery,
    );
    await AppLogger.endOperation(opId);
    return context;
  }

  Future<SpaceContext> _buildFromSpace(
    Space space,
    RecordsRepository recordsRepository, {
    String? correlationId,
    Stopwatch? stopwatch,
    required DateRange dateRange,
    String? userQuery,
  }) async {
    final allRecords = await _loadAllRecords(recordsRepository, space.id);
    
    await AppLogger.info(
      'Loaded all records for space',
      context: {
        'spaceId': space.id,
        'totalRecords': allRecords.length,
        'userQueryProvided': userQuery != null,
      },
      correlationId: correlationId,
    );

    List<RecordEntity> relevantRecords;
    List<RecordEntity> filteredRecords;
    int recordsFilteredCount;

    if (userQuery != null && userQuery.trim().isNotEmpty && _intentRetrievalConfig.enabled) {
      // Stage 6: Intent-Driven Retrieval
      await AppLogger.info(
        'Using intent-driven retrieval (Stage 6)',
        context: {
          'userQuery': userQuery,
          'spaceId': space.id,
          'intentRetrievalEnabled': _intentRetrievalConfig.enabled,
        },
        correlationId: correlationId,
      );

      // First apply date range filter (Stage 4 behavior)
      filteredRecords = await _filterEngine.filterRecords(
        allRecords,
        spaceId: space.id,
        dateRange: dateRange,
      );
      recordsFilteredCount = filteredRecords.length;

      // Analyze the query
      final queryAnalysis = await _queryAnalyzer.analyze(userQuery);

      // Use intent-driven retriever to get relevant records
      final retrievalResult = await _intentDrivenRetriever.retrieve(
        query: queryAnalysis,
        candidateRecords: filteredRecords,
        activeSpaceId: space.id,
      );

      // Extract the records from the retrieval result
      relevantRecords = retrievalResult.records.map((scoredRecord) => scoredRecord.record).toList();
      
      await AppLogger.info(
        'Intent-driven retrieval completed',
        context: {
          'userQuery': userQuery,
          'queryIntent': queryAnalysis.intent.name,
          'queryIntentConfidence': queryAnalysis.intentConfidence,
          'queryKeywords': queryAnalysis.keywords,
          'recordsConsidered': retrievalResult.stats.recordsConsidered,
          'recordsMatched': retrievalResult.stats.recordsMatched,
          'recordsIncluded': retrievalResult.stats.recordsIncluded,
          'recordsExcludedPrivacy': retrievalResult.stats.recordsExcludedPrivacy,
          'recordsExcludedThreshold': retrievalResult.stats.recordsExcludedThreshold,
          'stage': 'Stage 6',
        },
        correlationId: correlationId,
      );
    } else {
      // Stage 4: Date-based filtering with relevance scoring (traditional approach)
      // Or if intent retrieval is disabled
      await AppLogger.info(
        _intentRetrievalConfig.enabled
          ? 'Using date-based filtering (Stage 4 fallback)'
          : 'Using date-based filtering (Stage 4 - Intent retrieval disabled)',
        context: {
          'spaceId': space.id,
          'dateRangeStart': dateRange.start.toIso8601String(),
          'dateRangeEnd': dateRange.end.toIso8601String(),
          'userQueryProvided': userQuery != null,
          'intentRetrievalEnabled': _intentRetrievalConfig.enabled,
          'stage': 'Stage 4',
        },
        correlationId: correlationId,
      );

      filteredRecords = await _filterEngine.filterRecords(
        allRecords,
        spaceId: space.id,
        dateRange: dateRange,
      );
      recordsFilteredCount = filteredRecords.length;

      // Sort by relevance using traditional scoring
      relevantRecords = await _relevanceScorer.sortByRelevance(filteredRecords);
    }

    final filters = ContextFilters(
      dateRange: dateRange,
      spaceId: space.id,
      maxRecords: maxRecords,
    );
    
    final tokenAllocation = _tokenBudgetAllocator.allocate();
    
    // Format the records as summaries
    final summaries = _truncationStrategy.truncateToFit(
      relevantRecords,
      availableTokens: tokenAllocation.context,
      formatter: _formatter,
      maxRecords: maxRecords,
    );
    
    final estimatedTokens = summaries.fold<int>(
      0,
      (total, summary) => total + _formatter.estimateTokens(summary),
    );
    final assemblyTime = stopwatch?.elapsed ?? Duration.zero;
    
    // Log truncation events
    final dateRangeDays = dateRange.end.difference(dateRange.start).inDays;
    final truncatedCount = relevantRecords.length - summaries.length;
    if (truncatedCount > 0) {
      await AppLogger.info(
        'Context truncation applied',
        context: {
          'dateRangeDays': dateRangeDays,
          'stage': userQuery != null ? 'Stage 6' : 'Stage 4',
          'recordsAfterFiltering': relevantRecords.length,
          'recordsAfterTruncation': summaries.length,
          'truncatedCount': truncatedCount,
          'tokenBudget': tokenAllocation.context,
          'tokensUsed': estimatedTokens,
          'maxRecordsLimit': maxRecords,
          'truncationReason': truncatedCount > 0
              ? (relevantRecords.length > maxRecords ? 'maxRecords limit' : 'token budget')
              : 'none',
        },
        correlationId: correlationId,
      );
    } else if (dateRangeDays > 30) {
      // Log when large date ranges don't require truncation (informational)
      await AppLogger.info(
        'Large date range processed without truncation',
        context: {
          'dateRangeDays': dateRangeDays,
          'stage': userQuery != null ? 'Stage 6' : 'Stage 4',
          'recordsAfterFiltering': relevantRecords.length,
          'recordsIncluded': summaries.length,
          'tokenBudget': tokenAllocation.context,
          'tokensUsed': estimatedTokens,
        },
        correlationId: correlationId,
      );
    }

    final stats = ContextStats(
      recordsFiltered: recordsFilteredCount,
      recordsIncluded: summaries.length,
      tokensEstimated: estimatedTokens,
      tokensAvailable: tokenAllocation.context,
      compressionRatio: recordsFilteredCount == 0 ? 0 : summaries.length / recordsFilteredCount,
      assemblyTime: assemblyTime,
    );

    // Comprehensive final logging
    await AppLogger.info(
      'Built space context',
      context: {
        'spaceId': space.id,
        'spaceName': space.name,
        'dateRange': {
          'start': dateRange.start.toIso8601String(),
          'end': dateRange.end.toIso8601String(),
          'days': dateRange.end.difference(dateRange.start).inDays,
        },
        'records': {
          'total': allRecords.length,
          'afterFiltering': recordsFilteredCount,
          'included': summaries.length,
          'maxAllowed': maxRecords,
        },
        'tokenAllocation': {
          'total': tokenAllocation.total,
          'system': tokenAllocation.system,
          'context': tokenAllocation.context,
          'history': tokenAllocation.history,
          'response': tokenAllocation.response,
        },
        'tokenUsage': {
          'estimated': estimatedTokens,
          'available': tokenAllocation.context,
          'utilizationPercent': tokenAllocation.context > 0
              ? ((estimatedTokens / tokenAllocation.context) * 100).toStringAsFixed(1)
              : '0.0',
        },
        'compressionRatio': stats.compressionRatio.toStringAsFixed(3),
        'assemblyTimeMs': assemblyTime.inMilliseconds,
        'assemblyTimeSeconds': (assemblyTime.inMilliseconds / 1000).toStringAsFixed(3),
      },
      correlationId: correlationId,
    );

    return SpaceContext(
      spaceId: space.id,
      spaceName: space.name,
      description: space.description,
      categories: space.categories,
      persona: _personaFor(space.id),
      recentRecords: summaries,
      maxContextRecords: maxRecords,
      filters: filters,
      tokenAllocation: tokenAllocation,
      stats: stats,
    );
  }

  Future<List<RecordEntity>> _loadAllRecords(
    RecordsRepository recordsRepository,
    String spaceId, {
    int pageSize = 100,
  }) async {
    final records = <RecordEntity>[];
    var offset = 0;
    while (true) {
      final page = await recordsRepository.fetchPage(
        offset: offset,
        limit: pageSize,
        spaceId: spaceId,
      );
      records.addAll(page);
      if (page.length < pageSize) break;
      offset += pageSize;
    }
    return records;
  }

  SpacePersona _personaFor(String spaceId) {
    switch (spaceId.toLowerCase()) {
      case 'health':
        return SpacePersona.health;
      case 'education':
        return SpacePersona.education;
      case 'finance':
        return SpacePersona.finance;
      case 'travel':
        return SpacePersona.travel;
      default:
        return SpacePersona.general;
    }
  }
}
