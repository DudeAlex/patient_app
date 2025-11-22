import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
// ignore: unused_import
import 'package:isar_flutter_libs/isar_flutter_libs.dart';

import 'package:patient_app/features/records/adapters/repositories/isar_records_repository.dart';
import 'package:patient_app/features/records/adapters/storage/record_isar_model.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

void main() {
  group('IsarRecordsRepository', () {
    late Directory tempDir;
    late Isar isar;
    late IsarRecordsRepository repository;

    setUpAll(() async {
      await Isar.initializeIsarCore(download: true);
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('isar_records_repo_test');
      isar = await Isar.open(
        [RecordSchema],
        directory: tempDir.path,
      );
      repository = IsarRecordsRepository(isar);
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saves and retrieves a record with generated id', () async {
      final now = DateTime(2025, 10, 20);
      final saved = await repository.save(
        RecordEntity(
          type: 'visit',
          date: now,
          title: 'Post-op check',
          text: 'Patient recovering well.',
          tags: const ['visit'],
          createdAt: now,
          updatedAt: now,
        ),
      );

      expect(saved.id, isNotNull);
      final byId = await repository.byId(saved.id!);
      expect(byId, isNotNull);
      expect(byId!.title, 'Post-op check');
      expect(byId.tags, ['visit']);
    });

    test('fetchPage respects pagination and search query ordering', () async {
      final base = DateTime(2025, 7, 1);
      final records = <RecordEntity>[
        RecordEntity(
          type: 'lab',
          date: base.add(const Duration(days: 2)),
          title: 'Blood panel results',
          text: 'Slightly elevated cholesterol.',
          tags: const ['lab'],
          createdAt: base,
          updatedAt: base,
        ),
        RecordEntity(
          type: 'note',
          date: base.add(const Duration(days: 1)),
          title: 'Daily journal',
          text: 'Felt tired today.',
          tags: const ['note'],
          createdAt: base,
          updatedAt: base,
        ),
        RecordEntity(
          type: 'visit',
          date: base.add(const Duration(days: 3)),
          title: 'Cardiology follow-up',
          text: 'Discussed new medication plan.',
          tags: const ['visit'],
          createdAt: base,
          updatedAt: base,
        ),
      ];

      for (final record in records) {
        await repository.save(record);
      }

      final page = await repository.fetchPage(offset: 0, limit: 2);

      expect(page.map((r) => r.title), [
        'Cardiology follow-up',
        'Blood panel results',
      ]);

      final search = await repository.fetchPage(
        offset: 0,
        limit: 5,
        query: 'tired',
      );

      expect(search, hasLength(1));
      expect(search.single.title, 'Daily journal');
    });

    test('delete removes stored record', () async {
      final now = DateTime(2025, 5, 10);
      final saved = await repository.save(
        RecordEntity(
          type: 'note',
          date: now,
          title: 'Quick note',
          text: 'Remember to book appointment.',
          tags: const ['note'],
          createdAt: now,
          updatedAt: now,
        ),
      );

      await repository.delete(saved.id!);

      final remaining = await repository.recent(limit: 10);
      expect(remaining, isEmpty);
    });
  });
}
