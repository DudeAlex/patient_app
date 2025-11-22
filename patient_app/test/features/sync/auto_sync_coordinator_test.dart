import 'package:flutter_test/flutter_test.dart';

import 'package:patient_app/features/sync/auto_sync_runner.dart';
import 'package:patient_app/features/sync/auto_sync_backup_service.dart';
import 'package:patient_app/features/sync/auto_sync_coordinator.dart';
import 'package:patient_app/features/sync/application/ports/sync_state_repository.dart';
import 'package:patient_app/features/sync/application/use_cases/mark_auto_sync_success_use_case.dart';
import 'package:patient_app/features/sync/application/use_cases/promote_routine_changes_use_case.dart';
import 'package:patient_app/features/sync/application/use_cases/watch_auto_sync_status_use_case.dart';
import 'package:patient_app/features/sync/domain/entities/auto_sync_cadence.dart';
import 'package:patient_app/features/sync/domain/entities/auto_sync_status.dart';
import 'package:patient_app/features/sync/network/auto_sync_network_info.dart';

void main() {
  group('AutoSyncCoordinator', () {
    test('promotes routine changes before invoking runner', () async {
      final runner = _RecordingRunner();
      final promoteUseCase = _RecordingPromoteUseCase();
      final coordinator = AutoSyncCoordinator(
        _SilentWatchUseCase(),
        runner,
        promoteUseCase,
      );
      final status = AutoSyncStatus(
        autoSyncEnabled: true,
        pendingCriticalChanges: 0,
        pendingRoutineChanges: 2,
        localChangeCounter: 2,
        deviceId: 'device',
        cadence: AutoSyncCadence.weekly,
      );

      await coordinator.handleResumeForTest(status);

      expect(promoteUseCase.called, isTrue);
      expect(runner.handledStatuses, hasLength(1));
      expect(runner.handledStatuses.first.pendingCriticalChanges, 2);
      expect(runner.handledStatuses.first.pendingRoutineChanges, 0);
    });

    test('skips runner when promotion fails', () async {
      final runner = _RecordingRunner();
      final promoteUseCase = _RecordingPromoteUseCase(shouldThrow: true);
      final coordinator = AutoSyncCoordinator(
        _SilentWatchUseCase(),
        runner,
        promoteUseCase,
      );
      final status = AutoSyncStatus(
        autoSyncEnabled: true,
        pendingCriticalChanges: 0,
        pendingRoutineChanges: 1,
        localChangeCounter: 1,
        deviceId: 'device',
        cadence: AutoSyncCadence.weekly,
      );

      await coordinator.handleResumeForTest(status);

      expect(promoteUseCase.called, isTrue);
      expect(runner.handledStatuses, isEmpty);
    });
    test('skips when cadence is manual', () async {
      final runner = _RecordingRunner();
      final promoteUseCase = _RecordingPromoteUseCase();
      final coordinator = AutoSyncCoordinator(
        _SilentWatchUseCase(),
        runner,
        promoteUseCase,
      );
      final status = AutoSyncStatus(
        autoSyncEnabled: true,
        pendingCriticalChanges: 1,
        pendingRoutineChanges: 0,
        localChangeCounter: 1,
        deviceId: 'device',
        cadence: AutoSyncCadence.manual,
      );

      await coordinator.handleResumeForTest(status);

      expect(promoteUseCase.called, isFalse);
      expect(runner.handledStatuses, isEmpty);
    });
  });
}

class _RecordingRunner extends AutoSyncRunner {
  _RecordingRunner()
    : super(
        MarkAutoSyncSuccessUseCase(_NoopSyncStateRepository()),
        backupClient: _NoopBackupClient(),
        networkInfo: _WifiOnlyNetworkInfo(),
      );

  final List<AutoSyncStatus> handledStatuses = <AutoSyncStatus>[];

  @override
  Future<void> handleAppResume(AutoSyncStatus status) async {
    handledStatuses.add(status);
  }
}

class _NoopBackupClient implements AutoSyncBackupClient {
  @override
  bool get hasCachedAccount => true;

  @override
  String? get cachedEmail => 'test@example.com';

  @override
  Future<AutoSyncBackupResult> runBackup({
    bool promptIfNecessary = true,
  }) async {
    return AutoSyncBackupResult.success(completedAt: DateTime.now());
  }
}

class _WifiOnlyNetworkInfo implements AutoSyncNetworkInfo {
  @override
  Future<AutoSyncConnectionType> connectionType() async {
    return AutoSyncConnectionType.wifiLike;
  }
}

class _RecordingPromoteUseCase extends PromoteRoutineChangesUseCase {
  _RecordingPromoteUseCase({this.shouldThrow = false})
    : super(_NoopSyncStateRepository());

  final bool shouldThrow;
  bool called = false;

  @override
  Future<void> execute() async {
    called = true;
    if (shouldThrow) {
      throw Exception('fail');
    }
  }
}

class _SilentWatchUseCase extends WatchAutoSyncStatusUseCase {
  _SilentWatchUseCase() : super(_NoopSyncStateRepository());

  @override
  Stream<AutoSyncStatus> execute({bool fireImmediately = true}) =>
      const Stream<AutoSyncStatus>.empty();
}

class _NoopSyncStateRepository implements SyncStateRepository {
  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<AutoSyncStatus> readStatus() {
    throw UnimplementedError();
  }

  @override
  Stream<AutoSyncStatus> watchStatus({bool fireImmediately = true}) =>
      const Stream<AutoSyncStatus>.empty();

  @override
  Future<void> setAutoSyncEnabled(bool value) async {}

  @override
  Future<void> setAutoSyncCadence(AutoSyncCadence cadence) async {}

  @override
  Future<void> recordChange({required bool critical}) async {}

  @override
  Future<void> markSyncSuccess(DateTime completedAt) async {}

  @override
  Future<void> promoteRoutineChanges() async {}

  @override
  Future<String> deviceId() async => 'stub';
}
