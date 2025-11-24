import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/features/ai_chat/ui/widgets/attachment_preview.dart';
import 'package:patient_app/features/ai_chat/ui/widgets/action_hints_row.dart';

/// Displays a chat message bubble with optional attachments and status UI.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.onCopy,
    this.onActionHintTap,
  });

  final ChatMessage message;
  final VoidCallback? onRetry;
  final ValueChanged<String>? onCopy;
  final ValueChanged<String>? onActionHintTap;

  bool get _isUser => message.sender == MessageSender.user;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = _isUser
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceVariant;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!_isUser) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                child: Icon(Icons.smart_toy,
                    size: 18, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: GestureDetector(
                  onLongPress: () {
                    if (message.content.isNotEmpty && onCopy != null) {
                      onCopy!(message.content);
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.content.isNotEmpty)
                        MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: textColor),
                          ),
                          shrinkWrap: true,
                        ),
                      if (message.attachments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: message.attachments
                              .map(
                                (att) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: AttachmentPreview(attachment: att),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      if (message.actionHints.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ActionHintsRow(
                          hints: message.actionHints,
                          onHintTapped: onActionHintTap,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('HH:mm').format(message.timestamp),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(width: 8),
                          if (message.status == MessageStatus.sending)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          if (message.status == MessageStatus.failed) ...[
                            const Icon(Icons.error, size: 16, color: Colors.red),
                            const SizedBox(width: 4),
                            TextButton(
                              onPressed: onRetry,
                              child: const Text('Retry'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                child: const Icon(Icons.person, size: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
