import 'package:patient_app/core/ai/chat/models/chat_thread.dart';
import 'package:patient_app/core/ai/chat/repositories/chat_thread_repository.dart';
import 'package:uuid/uuid.dart';

/// Use case to load a chat thread for a space, creating one if absent.
class LoadChatHistoryUseCase {
  LoadChatHistoryUseCase({
    required ChatThreadRepository chatThreadRepository,
    Uuid? uuid,
  })  : _chatThreadRepository = chatThreadRepository,
        _uuid = uuid ?? const Uuid();

  final ChatThreadRepository _chatThreadRepository;
  final Uuid _uuid;

  Future<ChatThread> execute(String spaceId) async {
    final threads = await _chatThreadRepository.getBySpaceId(spaceId, limit: 1);
    if (threads.isNotEmpty) {
      return _sortedThread(threads.first);
    }

    final newThread = ChatThread(
      id: _uuid.v4(),
      spaceId: spaceId,
      messages: const [],
    );
    await _chatThreadRepository.saveThread(newThread);
    return newThread;
  }

  ChatThread _sortedThread(ChatThread thread) {
    final sortedMessages = [...thread.messages]..sort(
        (a, b) => a.timestamp.compareTo(b.timestamp),
      );
    return thread.copyWith(messages: sortedMessages);
  }
}
