import 'package:patient_app/core/ai/chat/application/use_cases/clear_chat_thread_use_case.dart';
import 'package:patient_app/core/ai/chat/application/use_cases/load_chat_history_use_case.dart';
import 'package:patient_app/core/ai/chat/models/chat_thread.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';

/// Use case to switch chat context between spaces.
///
/// Clears the current thread (with caller-managed confirmation) and loads or
/// creates the thread for the new space, returning the SpaceContext to use.
class SwitchSpaceContextUseCase {
  SwitchSpaceContextUseCase({
    required LoadChatHistoryUseCase loadChatHistoryUseCase,
    required ClearChatThreadUseCase clearChatThreadUseCase,
    required SpaceContextBuilder spaceContextBuilder,
  })  : _loadChatHistoryUseCase = loadChatHistoryUseCase,
        _clearChatThreadUseCase = clearChatThreadUseCase,
        _spaceContextBuilder = spaceContextBuilder;

  final LoadChatHistoryUseCase _loadChatHistoryUseCase;
  final ClearChatThreadUseCase _clearChatThreadUseCase;
  final SpaceContextBuilder _spaceContextBuilder;

  Future<SwitchSpaceResult> execute({
    required String currentThreadId,
    required String newSpaceId,
    required bool shouldClearCurrentThread,
  }) async {
    if (shouldClearCurrentThread) {
      await _clearChatThreadUseCase.execute(currentThreadId);
    }

    final newThread = await _loadChatHistoryUseCase.execute(newSpaceId);
    final context = await _spaceContextBuilder.build(newSpaceId);

    return SwitchSpaceResult(
      newThread: newThread,
      spaceContext: context,
    );
  }
}

/// Result returned when switching spaces.
class SwitchSpaceResult {
  SwitchSpaceResult({
    required this.newThread,
    required this.spaceContext,
  });

  final ChatThread newThread;
  final SpaceContext spaceContext;
}

/// Abstraction for building SpaceContext (e.g., with recent records/persona).
abstract class SpaceContextBuilder {
  Future<SpaceContext> build(String spaceId);
}
