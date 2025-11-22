import 'package:patient_app/core/ai/ai_service.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';

/// Extended AI service that supports conversational interactions.
abstract class AiChatService extends AiService {
  /// Sends a chat message to the AI provider and awaits a complete response.
  ///
  /// [request] contains the message content, attachments, and context.
  /// Returns a [ChatResponse] with the AI's reply and metadata.
  Future<ChatResponse> sendMessage(ChatRequest request);

  /// Sends a chat message and streams the response in chunks.
  ///
  /// Useful for real-time UI updates as the AI generates text.
  /// Yields [ChatResponseChunk]s until the response is complete.
  Stream<ChatResponseChunk> sendMessageStream(ChatRequest request);
}
