import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/chat/application/interfaces/space_context_builder.dart';
import 'package:patient_app/core/ai/chat/models/chat_thread.dart';
import 'package:patient_app/core/ai/chat/repositories/chat_thread_repository.dart';
import 'package:patient_app/core/di/app_container.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';
import 'package:patient_app/features/records/application/use_cases/fetch_recent_records_use_case.dart';
import 'package:patient_app/features/records/data/records_service.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

/// Riverpod provider that builds [SpaceContext] for a given space.
final spaceContextProvider =
    FutureProvider.family<SpaceContext, String>((ref, spaceId) async {
  final builder = ref.watch(spaceContextBuilderProvider);
  return builder.build(spaceId);
});

final spaceContextBuilderProvider = Provider<SpaceContextBuilder>((ref) {
  return DefaultSpaceContextBuilder(
    recordsServiceFuture: AppContainer.instance.resolve<Future<RecordsService>>(),
    chatThreadRepository: AppContainer.instance.resolve<ChatThreadRepository>(),
  );
});



class DefaultSpaceContextBuilder implements SpaceContextBuilder {
  DefaultSpaceContextBuilder({
    required Future<RecordsService> recordsServiceFuture,
    required ChatThreadRepository chatThreadRepository,
    int maxRecords = 5,
  })  : _recordsServiceFuture = recordsServiceFuture,
        _chatThreadRepository = chatThreadRepository,
        _maxRecords = maxRecords;

  final Future<RecordsService> _recordsServiceFuture;
  final ChatThreadRepository _chatThreadRepository;
  final int _maxRecords;

  @override
  Future<SpaceContext> build(String spaceId) async {
    final recordsService = await _recordsServiceFuture;
    final recentItems = await recordsService.fetchRecentRecords.execute(
      FetchRecentRecordsInput(limit: _maxRecords * 2),
    );

    final filtered = recentItems.records
        .where((record) => record.spaceId == spaceId)
        .toList();

    final summaries = filtered
        .map(
          (record) => RecordSummary(
            title: record.title,
            category: record.type,
            tags: record.tags,
            summaryText: _truncate(record.text),
            createdAt: record.date,
          ),
        )
        .toList();

    return SpaceContext(
      spaceId: spaceId,
      spaceName: _spaceName(spaceId),
      persona: _personaFor(spaceId),
      recentRecords: summaries,
      maxContextRecords: _maxRecords,
    );
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

  String _spaceName(String spaceId) {
    // Fallback to capitalized spaceId if no mapping.
    switch (spaceId.toLowerCase()) {
      case 'health':
        return 'Health';
      case 'education':
        return 'Education';
      case 'finance':
        return 'Finance';
      case 'travel':
        return 'Travel';
      default:
        return spaceId[0].toUpperCase() + spaceId.substring(1);
    }
  }

  String? _truncate(String? text, {int maxLength = 200}) {
    if (text == null) return null;
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
