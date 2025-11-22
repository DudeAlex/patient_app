import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:patient_app/core/ai/chat/data/entities/chat_message_entity.dart';
import 'package:patient_app/core/ai/chat/data/entities/chat_thread_entity.dart';
import 'package:patient_app/core/ai/chat/data/entities/message_attachment_entity.dart';
import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/core/ai/chat/models/chat_thread.dart';
import 'package:patient_app/core/ai/chat/repositories/chat_thread_repository_impl.dart';

void main() {
  late Isar isar;
  late ChatThreadRepositoryImpl repository;
  late Directory tempDir;

  setUp(() async {
    await Isar.initializeIsarCore(download: true);
    tempDir = await Directory.systemTemp.createTemp();
    isar = await Isar.open(
      [ChatThreadEntitySchema],
      directory: tempDir.path,
    );
    repository = ChatThreadRepositoryImpl(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    await tempDir.delete(recursive: true);
  });

  final testThread = ChatThread(
    id: 'thread_1',
    spaceId: 'space_1',
    messages: [
      ChatMessage(
        id: 'msg_1',
        threadId: 'thread_1',
        sender: MessageSender.user,
        content: 'Hello',
        timestamp: DateTime.now(),
      ),
    ],
  );

  test('saveThread and getById', () async {
    await repository.saveThread(testThread);

    final retrieved = await repository.getById('thread_1');
    expect(retrieved, isNotNull);
    expect(retrieved!.id, testThread.id);
    expect(retrieved.messages.length, 1);
    expect(retrieved.messages.first.content, 'Hello');
  });

  test('addMessage', () async {
    await repository.saveThread(testThread);

    final newMessage = ChatMessage(
      id: 'msg_2',
      threadId: 'thread_1',
      sender: MessageSender.ai,
      content: 'Hi there',
      timestamp: DateTime.now(),
    );

    await repository.addMessage('thread_1', newMessage);

    final retrieved = await repository.getById('thread_1');
    expect(retrieved!.messages.length, 2);
    expect(retrieved.messages.last.content, 'Hi there');
  });

  test('getBySpaceId', () async {
    await repository.saveThread(testThread);
    await repository.saveThread(ChatThread(
      id: 'thread_2',
      spaceId: 'space_1',
      messages: [],
    ));
    await repository.saveThread(ChatThread(
      id: 'thread_3',
      spaceId: 'space_2',
      messages: [],
    ));

    final space1Threads = await repository.getBySpaceId('space_1');
    expect(space1Threads.length, 2);
    expect(space1Threads.any((t) => t.id == 'thread_1'), isTrue);
    expect(space1Threads.any((t) => t.id == 'thread_2'), isTrue);

    final space2Threads = await repository.getBySpaceId('space_2');
    expect(space2Threads.length, 1);
    expect(space2Threads.first.id, 'thread_3');
  });

  test('deleteThread', () async {
    await repository.saveThread(testThread);
    await repository.deleteThread('thread_1');

    final retrieved = await repository.getById('thread_1');
    expect(retrieved, isNull);
  });
}
