import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';
import 'package:patient_app/core/ai/chat/services/message_attachment_handler_impl.dart';

void main() {
  late MessageAttachmentHandlerImpl handler;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp();
    handler = MessageAttachmentHandlerImpl(
      directoryProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('processAttachment copies file and generates metadata', () async {
    final sourceFile = File(path.join(tempDir.path, 'test_image.jpg'));
    await sourceFile.writeAsBytes([0, 1, 2, 3]);

    final attachment = await handler.processAttachment(
      sourceFile: sourceFile,
      type: AttachmentType.photo,
      targetThreadId: 'thread_1',
    );

    expect(attachment.id, isNotEmpty);
    expect(attachment.type, AttachmentType.photo);
    expect(attachment.fileName, 'test_image.jpg');
    expect(attachment.fileSizeBytes, 4);
    expect(attachment.mimeType, 'image/jpeg');
    expect(attachment.localPath, isNotNull);
    expect(attachment.localPath, isNot(sourceFile.path));

    final targetFile = File(attachment.localPath!);
    expect(await targetFile.exists(), isTrue);
    expect(await targetFile.readAsBytes(), [0, 1, 2, 3]);
  });

  test('deleteAttachment removes file', () async {
    final sourceFile = File(path.join(tempDir.path, 'test_doc.pdf'));
    await sourceFile.writeAsBytes([1, 2, 3]);

    final attachment = await handler.processAttachment(
      sourceFile: sourceFile,
      type: AttachmentType.file,
      targetThreadId: 'thread_1',
    );

    final targetFile = File(attachment.localPath!);
    expect(await targetFile.exists(), isTrue);

    await handler.deleteAttachment(attachment);
    expect(await targetFile.exists(), isFalse);
  });

  test('validateAttachment throws on missing file', () async {
    final missingFile = File(path.join(tempDir.path, 'missing.txt'));
    
    expect(
      () => handler.validateAttachment(missingFile, AttachmentType.file),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('validateAttachment throws on large file', () async {
    final largeFile = File(path.join(tempDir.path, 'large.txt'));
    // Create a sparse file just over the 10MB limit to verify validation.
    final raf = await largeFile.open(mode: FileMode.write);
    await raf.setPosition(10 * 1024 * 1024 + 1);
    await raf.writeByte(0);
    await raf.close();

    expect(
      () => handler.validateAttachment(largeFile, AttachmentType.file),
      throwsException,
    );
  });
}
