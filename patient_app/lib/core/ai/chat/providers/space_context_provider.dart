import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/chat/application/interfaces/space_context_builder.dart';
import 'package:patient_app/core/ai/chat/context/record_summary_formatter.dart';
import 'package:patient_app/core/ai/chat/context/space_context_builder.dart';
import 'package:patient_app/core/ai/chat/context/context_filter_engine.dart';
import 'package:patient_app/core/ai/chat/context/context_truncation_strategy.dart';
import 'package:patient_app/core/ai/chat/context/record_relevance_scorer.dart';
import 'package:patient_app/core/ai/chat/context/token_budget_allocator.dart';
import 'package:patient_app/core/application/services/space_manager.dart';
import 'package:patient_app/core/di/app_container.dart';
import 'package:patient_app/core/infrastructure/storage/space_preferences.dart';
import 'package:patient_app/features/records/data/records_service.dart';
import 'package:patient_app/features/spaces/domain/space_registry.dart';

/// Riverpod provider that builds [SpaceContext] for a given space.
final spaceContextProvider =
    FutureProvider.family<SpaceContext, String>((ref, spaceId) async {
  final builder = ref.watch(spaceContextBuilderProvider);
  return builder.build(spaceId);
});

final spaceContextBuilderProvider = Provider<SpaceContextBuilder>((ref) {
  final container = AppContainer.instance;
  final recordsServiceFuture = container.resolve<Future<RecordsService>>();
  final spaceManager = SpaceManager(
    SpacePreferences(),
    SpaceRegistry(),
  );

  final tokenAllocator = TokenBudgetAllocator();

  return SpaceContextBuilderImpl(
    recordsServiceFuture: recordsServiceFuture,
    filterEngine: ContextFilterEngine(),
    relevanceScorer: RecordRelevanceScorer(),
    tokenBudgetAllocator: tokenAllocator,
    truncationStrategy: const ContextTruncationStrategy(),
    spaceManager: spaceManager,
    formatter: RecordSummaryFormatter(),
    maxRecords: tokenAllocator.context ~/ 100, // rough cap aligned to budget
  );
});
