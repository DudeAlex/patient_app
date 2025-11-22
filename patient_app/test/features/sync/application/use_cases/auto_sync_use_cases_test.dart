import 'package:flutter_test/flutter_test.dart';

import 'package:patient_app/features/sync/application/ports/sync_state_repository.dart';
import 'package:patient_app/features/sync/application/use_cases/mark_auto_sync_success_use_case.dart';
import 'package:patient_app/features/sync/application/use_cases/promote_routine_changes_use_case.dart';
import 'package:patient_app/features/sync/application/use_cases/read_auto_sync_status_use_case.dart';
import 'package:patient_app/features/sync/application/use_cases/record_auto_sync_change_use_case.dart';
import 'package:patient_app/features/sync/application/use_cases/set_auto_sync_cadence_use_case.dart';
import 'package:patient_app/features/sync/application/use_cases/set_auto_sync_enabled_use_case.dart';
import 'package:patient_app/features/sync/application/use_cases/watch_auto_sync_status_use_case.dart';
import 'package:patient_app/features/sync/domain/entities/auto_sync_cadence.dart';
import 'package:patient_app/features/sync/domain/entities/auto_sync_status.dart';

void main() {
  final initialStatus = AutoSyncStatus(
    autoSyncEnabled: true,
    pendingCriticalChanges: 1,
    pendingRoutineChanges: 0,
    localChangeCounter: 1,
    deviceId: 'device',
    cadence: AutoSyncCadence.weekly,
    lastSyncedAt: DateTime(2025, 1, 1),
  );

  group('SetAutoSyncEnabledUseCase', () {
    test('forwards toggle to repository', () async {
      final repository = _RecordingRepository(initialStatus);
      final useCase = SetAutoSyncEnabledUseCase(repository);

      await useCase.execute(const SetAutoSyncEnabledInput(enabled: false));

      expect(repository.setAutoSyncEnabledValue, isFalse);
    });
  });

  group('SetAutoSyncCadenceUseCase', () {
    test('persists cadence via repository', () async {
      final repository = _RecordingRepository(initialStatus);
      final useCase = SetAutoSyncCadenceUseCase(repository);

      await useCase.execute(
        const SetAutoSyncCadenceInput(cadence: AutoSyncCadence.daily),
      );

      expect(repository.setAutoSyncCadenceValue, AutoSyncCadence.daily);
    });
  });


  group('RecordAutoSyncChangeUseCase', () {
    test('records critical flag', () async {
      final repository = _RecordingRepository(initialStatus);
      final useCase = RecordAutoSyncChangeUseCase(repository);

      await useCase.execute(const RecordAutoSyncChangeInput(critical: true));

      expect(repository.lastRecordedChange, isTrue);
    });
  });

  group('MarkAutoSyncSuccessUseCase', () {
    test('passes completion timestamp', () async {
      final repository = _RecordingRepository(initialStatus);
      final useCase = MarkAutoSyncSuccessUseCase(repository);
      final completedAt = DateTime(2025, 2, 1, 10, 30);

      await useCase.execute(
        MarkAutoSyncSuccessInput(completedAt: completedAt),
      );

      expect(repository.lastMarkedSuccess, completedAt);
    });
  });

  group('PromoteRoutineChangesUseCase', () {
    test('invokes promotion on repository', () async {
      final repository = _RecordingRepository(initialStatus);
      final useCase = PromoteRoutineChangesUseCase(repository);

      await useCase.execute();

      expect(repository.promoteCalled, isTrue);
    });
  });

  group('ReadAutoSyncStatusUseCase', () {
    test('returns status from repository', () async {
      final repository = _RecordingRepository(initialStatus);
      final useCase = ReadAutoSyncStatusUseCase(repository);

      final status = await useCase.execute();

      expect(status, same(initialStatus));
    });
  });

  group('WatchAutoSyncStatusUseCase', () {
    test('returns stream from repository', () async {
      final repository = _RecordingRepository(initialStatus);
      final useCase = WatchAutoSyncStatusUseCase(repository);

      final events = await useCase.execute().take(2).toList();

      expect(events, hasLength(2));
      expect(events.first.autoSyncEnabled, isTrue);
      expect(events.last.autoSyncEnabled, isFalse);
    });
  });
}

class _RecordingRepository implements SyncStateRepository {
  _RecordingRepository(this.readStatusResult);

  final AutoSyncStatus readStatusResult;

  bool? setAutoSyncEnabledValue;
  AutoSyncCadence? setAutoSyncCadenceValue;
  bool? lastRecordedChange;
  DateTime? lastMarkedSuccess;
  bool promoteCalled = false;

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<AutoSyncStatus> readStatus() async {
    return readStatusResult;
  }

  @override
  Stream<AutoSyncStatus> watchStatus({bool fireImmediately = true}) =>
      Stream<AutoSyncStatus>.fromIterable([
        readStatusResult,
        readStatusResult.copyWith(autoSyncEnabled: false),
      ]);

  @override
  Future<void> setAutoSyncEnabled(bool value) async {
    setAutoSyncEnabledValue = value;
  }

  @override
  Future<void> setAutoSyncCadence(AutoSyncCadence cadence) async {
    setAutoSyncCadenceValue = cadence;
  }

  @override
  Future<void> recordChange({required bool critical}) async {
    lastRecordedChange = critical;
  }

  @override
  Future<void> markSyncSuccess(DateTime completedAt) async {
    lastMarkedSuccess = completedAt;
  }

  @override
  Future<void> promoteRoutineChanges() async {
    promoteCalled = true;
  }

  @override
  Future<String> deviceId() async => readStatusResult.deviceId;
}
