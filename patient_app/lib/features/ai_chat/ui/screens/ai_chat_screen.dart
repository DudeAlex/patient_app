import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patient_app/core/ai/chat/chat_providers.dart';
import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';
import 'package:patient_app/core/ai/ai_config.dart';
import 'package:patient_app/core/ai/repositories/ai_config_repository.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:patient_app/core/storage/attachments.dart';
import 'package:patient_app/features/ai_chat/ui/controllers/ai_chat_controller.dart';
import 'package:patient_app/features/ai_chat/ui/widgets/chat_composer.dart';
import 'package:patient_app/features/ai_chat/ui/widgets/chat_header.dart';
import 'package:patient_app/features/ai_chat/ui/widgets/data_usage_banner.dart';
import 'package:patient_app/features/ai_chat/ui/widgets/error_message_bubble.dart';
import 'package:patient_app/features/ai_chat/ui/widgets/message_list.dart';
import 'package:patient_app/features/capture_core/api/capture_mode.dart';
import 'package:patient_app/features/capture_modes/voice/voice_capture_service.dart';
import 'package:patient_app/core/di/app_container.dart';

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
    final aiConfig =
        AppContainer.instance.resolve<AiConfigRepository>().current;

    return Scaffold(
      appBar: ChatHeader(
        spaceName: state.spaceContext?.spaceName ?? spaceId,
        spaceIcon: Icons.chat_bubble_outline,
        status: _statusFor(
          isOffline: state.isOffline,
          config: aiConfig,
        ),
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
            ErrorMessageBubble(
              message: state.errorMessage!,
              showRetry: true,
              onRetry: () => controller.loadInitial(),
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
              onFeedback: (messageId, feedback) {
                controller.provideFeedback(messageId, feedback);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      feedback == MessageFeedback.positive
                          ? 'Thanks for your feedback!'
                          : 'Feedback recorded. We\'ll work to improve.',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              onLoadMore: () {},
            ),
          ),
          ChatComposer(
            isOffline: state.isOffline,
            attachments: state.attachments,
            onSend: controller.sendMessage,
            onPhotoTap: () => _handlePhotoAttachment(
              context,
              ref,
              state,
              controller,
            ),
            onVoiceTap: () => _handleVoiceAttachment(
              context,
              ref,
              state,
              controller,
            ),
            onFileTap: () => _handleFileAttachment(
              context,
              ref,
              state,
              controller,
            ),
            onRemoveAttachment: (att) => controller.removeAttachment(att.id),
          ),
        ],
      ),
    );
  }

  ChatHeaderStatus _statusFor({
    required bool isOffline,
    required AiConfig config,
  }) {
    if (isOffline) return ChatHeaderStatus.offline;
    if (!config.enabled || config.mode == AiMode.fake) {
      return ChatHeaderStatus.fake;
    }
    return ChatHeaderStatus.remote;
  }

  Future<void> _handlePhotoAttachment(
    BuildContext context,
    WidgetRef ref,
    AiChatState state,
    AiChatController controller,
  ) async {
    if (state.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline - cannot attach photos')),
      );
      return;
    }
    if (state.thread == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat is still loading')),
      );
      return;
    }

    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.camera);
    if (xfile == null) return;

    final file = File(xfile.path);
    final handler = ref.read(messageAttachmentHandlerProvider);

    try {
      await handler.validateAttachment(file, AttachmentType.photo);
    } catch (e, stackTrace) {
      await AppLogger.error(
        'Photo attachment validation failed',
        error: e,
        stackTrace: stackTrace,
        context: {'path': file.path},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo too large or invalid: $e')),
        );
      }
      return;
    }

    final sizeBytes = await file.length();
    final sizeMb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Attach photo to AI chat?'),
        content: Text(
          'This photo (~$sizeMb MB) will be added to your chat and may be '
          'sent to the AI provider when you send the message. The original '
          'file stays on your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Attach'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    try {
      final attachment = await handler.processAttachment(
        sourceFile: file,
        type: AttachmentType.photo,
        targetThreadId: state.thread!.id,
      );
      controller.addAttachment(attachment);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo attached')),
        );
      }
    } catch (e, stackTrace) {
      await AppLogger.error(
        'Failed to attach photo',
        error: e,
        stackTrace: stackTrace,
        context: {'threadId': state.thread?.id},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to attach photo: $e')),
        );
      }
    }
  }

  Future<void> _handleFileAttachment(
    BuildContext context,
    WidgetRef ref,
    AiChatState state,
    AiChatController controller,
  ) async {
    if (state.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline - cannot attach files')),
      );
      return;
    }
    if (state.thread == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat is still loading')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp', 'txt'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;
    final path = picked.path;
    if (path == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected file has no local path')),
        );
      }
      return;
    }

    final file = File(path);
    final handler = ref.read(messageAttachmentHandlerProvider);

    try {
      await handler.validateAttachment(file, AttachmentType.file);
    } catch (e, stackTrace) {
      await AppLogger.error(
        'File attachment validation failed',
        error: e,
        stackTrace: stackTrace,
        context: {'path': file.path},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File too large or invalid: $e')),
        );
      }
      return;
    }

    final sizeBytes = await file.length();
    final sizeMb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Attach file to AI chat?'),
        content: Text(
          'This file (~$sizeMb MB) will be added to your chat and may be '
          'sent to the AI provider when you send the message. The original '
          'file stays on your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Attach'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final attachment = await handler.processAttachment(
        sourceFile: file,
        type: AttachmentType.file,
        targetThreadId: state.thread!.id,
      );
      controller.addAttachment(
        attachment.copyWith(fileSizeBytes: sizeBytes),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File attached')),
        );
      }
    } catch (e, stackTrace) {
      await AppLogger.error(
        'Failed to attach file',
        error: e,
        stackTrace: stackTrace,
        context: {'threadId': state.thread?.id},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to attach file: $e')),
        );
      }
    }
  }

  Future<void> _handleVoiceAttachment(
    BuildContext context,
    WidgetRef ref,
    AiChatState state,
    AiChatController controller,
  ) async {
    if (state.thread == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat is still loading')),
      );
      return;
    }

    final locale = Localizations.localeOf(context).toLanguageTag();
    final accessibility =
        MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;

    final captureService = VoiceCaptureService();
    final captureContext = CaptureContext(
      sessionId: state.thread!.id,
      locale: locale,
      isAccessibilityEnabled: accessibility,
      withUiContext: <T>(action) async => action(context),
      onProcessing: (isProcessing) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (isProcessing) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transcribing voice note...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    );

    final outcome = await captureService.captureVoice(captureContext);
    if (outcome == null) return;

    try {
      final file =
          await AttachmentsStorage.resolveRelativePath(outcome.artifact.relativePath);
      final handler = ref.read(messageAttachmentHandlerProvider);
      await handler.validateAttachment(file, AttachmentType.voice);

      final sizeBytes = await file.length();
      final transcription = (outcome.artifact.metadata['analysis']
              as Map<String, Object?>?)?['transcription'] as String?;

      final attachment = await handler.processAttachment(
        sourceFile: file,
        type: AttachmentType.voice,
        targetThreadId: state.thread!.id,
      );

      controller.addAttachment(
        attachment.copyWith(
          transcription: transcription,
          fileSizeBytes: sizeBytes,
        ),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice note attached')),
        );
      }
    } catch (e, stackTrace) {
      await AppLogger.error(
        'Failed to attach voice note',
        error: e,
        stackTrace: stackTrace,
        context: {'threadId': state.thread?.id},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to attach voice note: $e')),
        );
      }
    }
  }
}
