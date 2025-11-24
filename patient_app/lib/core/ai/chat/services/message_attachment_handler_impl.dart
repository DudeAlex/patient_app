import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:uuid/uuid.dart';

import 'message_attachment_handler.dart';

class MessageAttachmentHandlerImpl implements MessageAttachmentHandler {
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB
  final Uuid _uuid = const Uuid();

  final Future<Directory> Function()? _directoryProvider;

  MessageAttachmentHandlerImpl({Future<Directory> Function()? directoryProvider})
      : _directoryProvider = directoryProvider;

  Future<Directory> _attachmentsDirFor(String threadId) async {
    final appDir = _directoryProvider != null
        ? await _directoryProvider()
        : await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(
      path.join(appDir.path, 'chat_attachments', threadId),
    );
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    return attachmentsDir;
  }

  @override
  Future<MessageAttachment> processAttachment({
    required File sourceFile,
    required AttachmentType type,
    required String targetThreadId,
  }) async {
    await validateAttachment(sourceFile, type);

    final dir = await _attachmentsDirFor(targetThreadId);
    final extension = path.extension(sourceFile.path);
    final uniqueId = _uuid.v4();
    final fileName = '$uniqueId$extension';
    final targetPath = path.join(dir.path, fileName);

    await sourceFile.copy(targetPath);

    final fileSize = await sourceFile.length();
    final mimeType = _getMimeType(sourceFile.path);

    final attachment = MessageAttachment(
      id: uniqueId,
      type: type,
      localPath: targetPath,
      fileName: path.basename(sourceFile.path),
      fileSizeBytes: fileSize,
      mimeType: mimeType,
    );

    await AppLogger.info(
      'Processed chat attachment',
      context: {
        'threadId': targetThreadId,
        'attachmentId': uniqueId,
        'type': type.name,
        'sizeBytes': fileSize,
      },
    );

    return attachment;
  }

  @override
  Future<void> deleteAttachment(MessageAttachment attachment) async {
    if (attachment.localPath == null) return;

    final file = File(attachment.localPath!);
    if (await file.exists()) {
      await file.delete();
      await AppLogger.debug(
        'Deleted chat attachment file',
        context: {
          'attachmentId': attachment.id,
          'path': attachment.localPath,
        },
      );
    }
  }

  @override
  Future<void> validateAttachment(File file, AttachmentType type) async {
    if (!await file.exists()) {
      throw const FileSystemException('File does not exist');
    }

    final size = await file.length();
    if (size > _maxFileSizeBytes) {
      throw Exception('File size exceeds limit of 10MB');
    }

    // Add more validation logic here if needed (e.g., mime type check)

    await AppLogger.debug(
      'Validated chat attachment',
      context: {'sizeBytes': size, 'type': type.name},
    );
  }

  String _getMimeType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.mp4': // Assuming voice notes might be m4a/mp4
      case '.m4a':
        return 'audio/mp4';
      case '.mp3':
        return 'audio/mpeg';
      case '.pdf':
        return 'application/pdf';
      case '.txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
