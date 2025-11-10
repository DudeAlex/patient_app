import 'package:flutter_test/flutter_test.dart';

import 'package:patient_app/features/records/domain/entities/record.dart';
import 'package:patient_app/features/sync/application/use_cases/record_auto_sync_change_use_case.dart';
import 'package:patient_app/features/sync/dirty_tracker.dart';

void main() {
  group('AutoSyncDirtyTracker', () {
    late _RecordingUseCase recordingUseCase;
    late AutoSyncDirtyTracker tracker;

    setUp(() {
      recordingUseCase = _RecordingUseCase();
      tracker = AutoSyncDirtyTracker(recordingUseCase);
    });

    test('marks visit/lab/med changes as critical', () async {
      final criticalTypes = ['visit', 'lab', 'med'];

      for (final type in criticalTypes) {
        recordingUseCase.lastCriticalFlag = null;
        final record = _buildRecord(type: type);

        await tracker.recordRecordSave(record);

        expect(recordingUseCase.lastCriticalFlag, isTrue, reason: type);
      }
    });

    test('marks other record types as routine', () async {
      final record = _buildRecord(type: 'note');

      await tracker.recordRecordSave(record);

      expect(recordingUseCase.lastCriticalFlag, isFalse);
    });

    test('treats unknown delete target as critical', () async {
      await tracker.recordRecordDelete(null);

      expect(recordingUseCase.lastCriticalFlag, isTrue);
    });
  });
}

RecordEntity _buildRecord({required String type}) {
  final now = DateTime.now();
  return RecordEntity(
    id: 1,
    type: type,
    date: now,
    title: 'Title',
    text: 'notes',
    tags: const [],
    createdAt: now,
    updatedAt: now,
  );
}

class _RecordingUseCase implements RecordAutoSyncChangeUseCase {
  bool? lastCriticalFlag;

  @override
  Future<void> execute(RecordAutoSyncChangeInput input) async {
    lastCriticalFlag = input.critical;
  }
}
