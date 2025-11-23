import 'package:flutter/material.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';

/// Inline attachment preview for chat bubbles.
class AttachmentPreview extends StatelessWidget {
  const AttachmentPreview({super.key, required this.attachment});

  final MessageAttachment attachment;

  @override
  Widget build(BuildContext context) {
    switch (attachment.type) {
      case AttachmentType.photo:
        return _PhotoPreview(fileName: attachment.fileName);
      case AttachmentType.voice:
        return _VoicePreview(fileName: attachment.fileName);
      case AttachmentType.file:
        return _FilePreview(
          fileName: attachment.fileName,
          sizeBytes: attachment.fileSizeBytes,
        );
    }
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({this.fileName});

  final String? fileName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.photo, size: 18),
        const SizedBox(width: 6),
        Text(fileName ?? 'Photo', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _VoicePreview extends StatelessWidget {
  const _VoicePreview({this.fileName});

  final String? fileName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mic, size: 18),
        const SizedBox(width: 6),
        Text(
          fileName ?? 'Voice note',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _FilePreview extends StatelessWidget {
  const _FilePreview({this.fileName, this.sizeBytes});

  final String? fileName;
  final int? sizeBytes;

  @override
  Widget build(BuildContext context) {
    final sizeText = sizeBytes != null ? _formatSize(sizeBytes!) : '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.insert_drive_file, size: 18),
        const SizedBox(width: 6),
        Text(
          fileName ?? 'File',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (sizeText.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            sizeText,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ],
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)}KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)}MB';
  }
}
