import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/chat_providers.dart';
import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/features/ai_chat/ui/controllers/ai_chat_controller.dart';
import 'package:patient_app/features/ai_chat/ui/widgets/chat_composer.dart';
import 'package:patient_app/features/ai_chat/ui/widgets/chat_header.dart';
import 'package:patient_app/features/ai_chat/ui/widgets/data_usage_banner.dart';
import 'package:patient_app/features/ai_chat/ui/widgets/message_list.dart';

/// AI Chat screen composed of header, data banner, messages, and composer.
class AiChatScreen extends ConsumerWidget {
  const AiChatScreen({
    super.key,
    required this.spaceId,
    this.recordId,
  });

  final String spaceId;
  final String? recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiChatControllerProvider(spaceId));
    final controller = ref.read(aiChatControllerProvider(spaceId).notifier);

    if (state.isLoading || state.thread == null || state.spaceContext == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final messages = state.thread?.messages ?? const <ChatMessage>[];

    return Scaffold(
      appBar: ChatHeader(
        spaceName: state.spaceContext?.spaceName ?? spaceId,
        spaceIcon: Icons.chat_bubble_outline,
        status: _statusFor(ref.read(aiChatServiceProvider)),
        onClearChat: controller.clearChat,
        onChangeContext: () {},
      ),
      body: Column(
        children: [
          DataUsageBanner(
            spaceName: state.spaceContext?.spaceName ?? spaceId,
            recordTitle: recordId,
          ),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                state.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: MessageList(
              messages: messages,
              onRetry: () {},
              onCopy: (text) {
                final preview = text.substring(0, min(text.length, 30));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Copied: $preview')),
                );
              },
              onActionHintTap: (hint) => controller.sendMessage(hint),
              onLoadMore: () {},
            ),
          ),
          ChatComposer(
            isOffline: state.isOffline,
            attachments: state.attachments,
            onSend: controller.sendMessage,
            onPhotoTap: () {},
            onVoiceTap: () {},
            onFileTap: () {},
            onRemoveAttachment: (att) => controller.removeAttachment(att.id),
          ),
        ],
      ),
    );
  }

  ChatHeaderStatus _statusFor(AiChatService service) {
    // Simple heuristic: use Fake vs Remote vs Offline.
    final provider = service.runtimeType.toString().toLowerCase();
    if (provider.contains('fake')) return ChatHeaderStatus.fake;
    if (provider.contains('http')) return ChatHeaderStatus.remote;
    return ChatHeaderStatus.offline;
  }
}
