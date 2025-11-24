import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/core/ai/chat/models/chat_thread.dart';

/// Repository for managing chat threads and messages.
abstract class ChatThreadRepository {
  /// Retrieves a chat thread by its unique ID.
  Future<ChatThread?> getById(String threadId);

  /// Retrieves all chat threads associated with a specific Space.
  ///
  /// [spaceId] The ID of the space.
  /// [limit] Optional limit on the number of threads to return (default 20).
  /// [offset] Optional offset for pagination (default 0).
  Future<List<ChatThread>> getBySpaceId(
    String spaceId, {
    int limit = 20,
    int offset = 0,
  });

  /// Saves or updates a chat thread.
  Future<void> saveThread(ChatThread thread);

  /// Deletes a chat thread and all its messages.
  Future<void> deleteThread(String threadId);

  /// Adds a message to an existing thread.
  Future<void> addMessage(String threadId, ChatMessage message);

  /// Updates the status of a specific message in a thread.
  Future<void> updateMessageStatus(
    String threadId,
    String messageId,
    MessageStatus status, {
    String? errorMessage,
    String? errorCode,
    bool? errorRetryable,
  });
  
  /// Updates the content of a specific message (e.g. for streaming responses).
  Future<void> updateMessageContent(
    String threadId, 
    String messageId, 
    String content,
  );
  
  /// Updates the token usage and latency metrics for a message.
  Future<void> updateMessageMetrics(
    String threadId,
    String messageId, {
    int? tokensUsed,
    int? latencyMs,
  });
}
