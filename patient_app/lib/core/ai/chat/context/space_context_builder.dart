import 'package:patient_app/core/ai/chat/application/interfaces/space_context_builder.dart';
import 'package:patient_app/core/ai/chat/context/record_summary_formatter.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/application/services/space_manager.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:patient_app/core/domain/entities/space.dart';
import 'package:patient_app/features/records/application/ports/records_repository.dart';
import 'package:patient_app/features/records/application/ports/records_repository.dart';
import 'package:patient_app/features/records/data/records_service.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

/// Builds SpaceContext using space metadata and recent records.
class SpaceContextBuilderImpl implements SpaceContextBuilder {
  SpaceContextBuilderImpl({
    required Future<RecordsService> recordsServiceFuture,
    RecordsRepository? recordsRepositoryOverride,
    required SpaceManager spaceManager,
    RecordSummaryFormatter? formatter,
    this.maxRecords = 10,
  })  : _recordsServiceFuture = recordsServiceFuture,
        _recordsRepositoryOverride = recordsRepositoryOverride,
        _spaceManager = spaceManager,
        _formatter = formatter ?? RecordSummaryFormatter();

  final Future<RecordsService> _recordsServiceFuture;
  final RecordsRepository? _recordsRepositoryOverride;
  final SpaceManager _spaceManager;
  final RecordSummaryFormatter _formatter;

  /// Maximum records to include in the context payload.
  final int maxRecords;

  @override
  Future<SpaceContext> build(String spaceId) async {
    final opId = AppLogger.startOperation('space_context_build');
    await AppLogger.info(
      'Starting space context assembly',
      context: {'spaceId': spaceId, 'maxRecords': maxRecords},
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
        final context = await _buildFromSpace(match, recordsRepository, correlationId: opId);
        await AppLogger.endOperation(opId);
        return context;
      }
    }
    final context = await _buildFromSpace(space, recordsRepository, correlationId: opId);
    await AppLogger.endOperation(opId);
    return context;
  }

  Future<SpaceContext> _buildFromSpace(
    Space space,
    RecordsRepository recordsRepository,
    {String? correlationId},
  ) async {
    final recent = await recordsRepository.recent(limit: maxRecords * 2);
    final filtered = recent
        .where((record) => _belongsToSpace(record, space.id))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final summaries = filtered.take(maxRecords).map(_formatter.format).toList();
    final estimatedTokens = summaries.fold<int>(
      0,
      (total, summary) => total + _formatter.estimateTokens(summary),
    );

    await AppLogger.info(
      'Built space context',
      context: {
        'spaceId': space.id,
        'recordsConsidered': filtered.length,
        'recordsIncluded': summaries.length,
        'maxRecords': maxRecords,
        'estimatedTokens': estimatedTokens,
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
    );
  }

  bool _belongsToSpace(RecordEntity record, String spaceId) {
    if (record.deletedAt != null) return false;
    return record.spaceId == spaceId;
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
