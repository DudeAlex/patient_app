import 'dart:io';

import 'package:flutter/material.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';

/// Chat composer with text input, attachment shortcuts, and send control.
class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.onSend,
    this.onPhotoTap,
    this.onVoiceTap,
    this.onFileTap,
    this.onRemoveAttachment,
    this.attachments = const [],
    this.isOffline = false,
  });

  /// Called when the user taps send with the current text.
  final ValueChanged<String> onSend;

  /// Attachment entry points.
  final VoidCallback? onPhotoTap;
  final VoidCallback? onVoiceTap;
  final VoidCallback? onFileTap;

  /// Called when an attachment chip is removed.
  final ValueChanged<MessageAttachment>? onRemoveAttachment;

  /// Attachments selected for this draft.
  final List<MessageAttachment> attachments;

  /// Disables input when offline.
  final bool isOffline;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  late final TextEditingController _controller;

  bool get _hasContent =>
      _controller.text.trim().isNotEmpty || widget.attachments.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.attachments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: widget.attachments
                  .map(
                    (att) => InputChip(
                      key: ValueKey('attachment_${att.id}'),
                      avatar: att.type == AttachmentType.photo &&
                              att.localPath != null &&
                              File(att.localPath!).existsSync()
                          ? CircleAvatar(
                              backgroundImage: FileImage(File(att.localPath!)),
                            )
                          : null,
                      label: Text(att.fileName ?? att.type.name),
                      onDeleted: widget.onRemoveAttachment != null
                          ? () => widget.onRemoveAttachment!(att)
                          : null,
                    ),
                  )
                  .toList(),
            ),
          ),
        Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.photo_camera),
                tooltip: 'Photo',
                onPressed: widget.isOffline ? null : widget.onPhotoTap,
              ),
              IconButton(
                icon: const Icon(Icons.mic),
                tooltip: 'Voice',
                onPressed: widget.isOffline ? null : widget.onVoiceTap,
              ),
              IconButton(
                icon: const Icon(Icons.attach_file),
                tooltip: 'File',
                onPressed: widget.isOffline ? null : widget.onFileTap,
              ),
              Expanded(
                child: TextField(
                  key: const Key('chat_composer_input'),
                  controller: _controller,
                  enabled: !widget.isOffline,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Type a message',
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                tooltip: widget.isOffline
                    ? 'Offline - cannot send'
                    : 'Send message',
                onPressed: !_hasContent || widget.isOffline
                    ? null
                    : () {
                        final text = _controller.text.trim();
                        widget.onSend(text);
                        _controller.clear();
                        setState(() {});
                      },
              ),
            ],
          ),
        ),
        if (widget.isOffline)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              'Offline - cannot send',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.error),
            ),
          ),
      ],
    );
  }
}
