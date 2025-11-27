import 'package:patient_app/core/ai/chat/application/interfaces/space_context_builder.dart';
import 'package:patient_app/core/ai/chat/context/context_filter_engine.dart';
import 'package:patient_app/core/ai/chat/context/context_truncation_strategy.dart';
import 'package:patient_app/core/ai/chat/context/record_relevance_scorer.dart';
import 'package:patient_app/core/ai/chat/context/record_summary_formatter.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/chat/models/context_filters.dart';
import 'package:patient_app/core/ai/chat/models/context_stats.dart';
import 'package:patient_app/core/ai/chat/models/date_range.dart';
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
    required ContextFilterEngine filterEngine,
    required RecordRelevanceScorer relevanceScorer,
    required TokenBudgetAllocator tokenBudgetAllocator,
    required ContextTruncationStrategy truncationStrategy,
    RecordSummaryFormatter? formatter,
    this.maxRecords = 20,
    DateRange? dateRange,
  })  : _recordsServiceFuture = recordsServiceFuture,
        _recordsRepositoryOverride = recordsRepositoryOverride,
        _spaceManager = spaceManager,
        _filterEngine = filterEngine,
        _relevanceScorer = relevanceScorer,
        _tokenBudgetAllocator = tokenBudgetAllocator,
        _truncationStrategy = truncationStrategy,
        _dateRange = dateRange ?? DateRange.last14Days(),
        _formatter = formatter ?? RecordSummaryFormatter();

  final Future<RecordsService> _recordsServiceFuture;
  final RecordsRepository? _recordsRepositoryOverride;
  final SpaceManager _spaceManager;
  final ContextFilterEngine _filterEngine;
  final RecordRelevanceScorer _relevanceScorer;
  final TokenBudgetAllocator _tokenBudgetAllocator;
  final ContextTruncationStrategy _truncationStrategy;
  final DateRange _dateRange;
  final RecordSummaryFormatter _formatter;

  /// Maximum records to include in the context payload.
  final int maxRecords;

  @override
  Future<SpaceContext> build(String spaceId) async {
    final opId = AppLogger.startOperation('space_context_build');
    final stopwatch = Stopwatch()..start();
    await AppLogger.info(
      'Starting space context assembly',
      context: {
        'spaceId': spaceId,
        'maxRecords': maxRecords,
        'dateRangeStart': _dateRange.start.toIso8601String(),
        'dateRangeEnd': _dateRange.end.toIso8601String(),
      },
      correlationId: opId,
    );
    final recordsRepository = _recordsRepositoryOverride ?? (await _recordsServiceFuture).records;
    final space = await _spaceManager.getCurrentSpace();
    if (space.id != spaceId) {
      // Try to resolve the requested space explicitly.
      final activeSpaces = await _spaceManager.getActiveSpaces();
      final match = activeSpaces.firstWhere(
        (s) => s.id == spaceId,
        orElse: () => space,
      );
      if (match.id == spaceId) {
        final context = await _buildFromSpace(
          match,
          recordsRepository,
          correlationId: opId,
          stopwatch: stopwatch,
        );
        await AppLogger.endOperation(opId);
        return context;
      }
    }
    final context = await _buildFromSpace(
      space,
      recordsRepository,
      correlationId: opId,
      stopwatch: stopwatch,
    );
    await AppLogger.endOperation(opId);
    return context;
  }

  Future<SpaceContext> _buildFromSpace(
    Space space,
    RecordsRepository recordsRepository, {
    String? correlationId,
    Stopwatch? stopwatch,
  }) async {
    final allRecords = await _loadAllRecords(recordsRepository, space.id);
    final filters = ContextFilters(
      dateRange: _dateRange,
      spaceId: space.id,
      maxRecords: maxRecords,
    );
    final filtered = await _filterEngine.filterRecords(
      allRecords,
      spaceId: space.id,
      dateRange: _dateRange,
    );

    final sorted = await _relevanceScorer.sortByRelevance(filtered);
    final tokenAllocation = _tokenBudgetAllocator.allocate();
    final summaries = _truncationStrategy.truncateToFit(
      sorted,
      availableTokens: tokenAllocation.context,
      formatter: _formatter,
      maxRecords: maxRecords,
    );
    final estimatedTokens = summaries.fold<int>(
      0,
      (total, summary) => total + _formatter.estimateTokens(summary),
    );
    final assemblyTime = stopwatch?.elapsed ?? Duration.zero;

    final stats = ContextStats(
      recordsFiltered: filtered.length,
      recordsIncluded: summaries.length,
      tokensEstimated: estimatedTokens,
      tokensAvailable: tokenAllocation.context,
      compressionRatio: filtered.isEmpty ? 0 : summaries.length / filtered.length,
      assemblyTime: assemblyTime,
    );

    await AppLogger.info(
      'Built space context',
      context: {
        'spaceId': space.id,
        'recordsTotal': allRecords.length,
        'recordsConsidered': filtered.length,
        'recordsIncluded': summaries.length,
        'maxRecords': maxRecords,
        'estimatedTokens': estimatedTokens,
        'dateRangeStart': _dateRange.start.toIso8601String(),
        'dateRangeEnd': _dateRange.end.toIso8601String(),
        'tokensAvailable': tokenAllocation.context,
        'assemblyMs': assemblyTime.inMilliseconds,
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
