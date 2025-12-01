import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:patient_app/core/ai/chat/models/date_range.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/chat/application/interfaces/space_context_builder.dart';
import 'package:patient_app/core/ai/chat/context/record_summary_formatter.dart';
import 'package:patient_app/core/ai/chat/context/space_context_builder.dart';
import 'package:patient_app/core/ai/chat/context/context_filter_engine.dart';
import 'package:patient_app/core/ai/chat/context/context_truncation_strategy.dart';
import 'package:patient_app/core/ai/chat/context/record_relevance_scorer.dart';
import 'package:patient_app/core/ai/chat/context/token_budget_allocator.dart';
import 'package:patient_app/core/ai/chat/repositories/context_config_repository.dart';
import 'package:patient_app/core/application/services/space_manager.dart';
import 'package:patient_app/core/di/app_container.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:patient_app/core/infrastructure/storage/space_preferences.dart';
import 'package:patient_app/features/records/data/records_service.dart';
import 'package:patient_app/features/spaces/domain/space_registry.dart';
import 'package:patient_app/core/ai/chat/domain/services/intent_driven_retriever.dart';
import 'package:patient_app/core/ai/chat/domain/services/privacy_filter.dart';
import 'package:patient_app/core/ai/chat/models/intent_retrieval_config.dart';
import 'package:patient_app/core/ai/chat/domain/services/query_analyzer.dart';
import 'package:patient_app/core/ai/chat/domain/services/keyword_extractor.dart';
import 'package:patient_app/core/ai/chat/domain/services/intent_classifier.dart';
import 'package:patient_app/core/ai/chat/domain/services/relevance_scorer.dart';

/// Riverpod provider that builds [SpaceContext] for a given space.
final spaceContextProvider =
    FutureProvider.family<SpaceContext, String>((ref, spaceId) async {
  final builder = await ref.watch(spaceContextBuilderProvider.future);
  return builder.build(spaceId);
});

/// Creates a SpaceContextBuilder with the user's configured date range.
/// 
/// Reads the date range setting from ContextConfigRepository and creates
/// an appropriate DateRange instance. Falls back to 14 days if the setting
/// is missing or invalid.
final spaceContextBuilderProvider = FutureProvider<SpaceContextBuilder>((ref) async {
  final container = AppContainer.instance;
  final recordsServiceFuture = container.resolve<Future<RecordsService>>();
  final contextConfigRepo = container.resolve<ContextConfigRepository>();
  final spaceManager = SpaceManager(
    SpacePreferences(),
    SpaceRegistry(),
  );

  final tokenAllocator = TokenBudgetAllocator();
  
  // Read date range setting
  final dateRangeDays = await contextConfigRepo.getDateRangeDays();
  final dateRange = DateRange.lastNDays(dateRangeDays);
  
  // Determine if this is a custom value (not one of the presets)
  final isCustom = ![7, 14, 30].contains(dateRangeDays);
  
  await AppLogger.info(
    'Creating SpaceContextBuilder with date range',
    context: {
      'dateRangeDays': dateRangeDays,
      'dateRangeStart': dateRange.start.toIso8601String(),
      'dateRangeEnd': dateRange.end.toIso8601String(),
      'isCustom': isCustom,
    },
  );

  return SpaceContextBuilderImpl(
    recordsServiceFuture: recordsServiceFuture,
    filterEngine: ContextFilterEngine(),
    relevanceScorer: RecordRelevanceScorer(),
    tokenBudgetAllocator: tokenAllocator,
    truncationStrategy: const ContextTruncationStrategy(),
    spaceManager: spaceManager,
    intentDrivenRetriever: IntentDrivenRetriever(
      relevanceScorer: RelevanceScorer(),
      privacyFilter: PrivacyFilter(),
      config: const IntentRetrievalConfig(),
    ),
    queryAnalyzer: QueryAnalyzer(
      keywordExtractor: KeywordExtractor(),
      intentClassifier: IntentClassifier(),
    ),
    intentRetrievalConfig: const IntentRetrievalConfig(),
    formatter: RecordSummaryFormatter(),
    maxRecords: tokenAllocator.context ~/ 100, // rough cap aligned to budget
    dateRange: dateRange, // Pass configured date range
  );
});
