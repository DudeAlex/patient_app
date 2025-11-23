import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/repositories/chat_thread_repository.dart';
import 'package:patient_app/core/ai/chat/services/message_attachment_handler.dart';
import 'package:patient_app/core/di/app_container.dart';

final aiChatServiceProvider = Provider<AiChatService>((ref) {
  return AppContainer.instance.resolve<AiChatService>();
});

final chatThreadRepositoryProvider = Provider<ChatThreadRepository>((ref) {
  return AppContainer.instance.resolve<ChatThreadRepository>();
});

final messageAttachmentHandlerProvider =
    Provider<MessageAttachmentHandler>((ref) {
  return AppContainer.instance.resolve<MessageAttachmentHandler>();
});
