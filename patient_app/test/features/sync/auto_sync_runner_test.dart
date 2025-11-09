import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';

import 'package:patient_app/features/sync/application/ports/sync_state_repository.dart';
import 'package:patient_app/features/sync/application/use_cases/mark_auto_sync_success_use_case.dart';
import 'package:patient_app/features/sync/auto_sync_backup_service.dart';
import 'package:patient_app/features/sync/auto_sync_runner.dart';
import 'package:patient_app/features/sync/domain/entities/auto_sync_status.dart';
import 'package:patient_app/features/sync/network/auto_sync_network_info.dart';

void main() {
  group('AutoSyncRunner', () {
    test('skips background backup when not on Wi-Fi', () async {
      final repository = _RecordingSyncStateRepository();
      final backupClient = _StubBackupClient();
      final runner = AutoSyncRunner(
        MarkAutoSyncSuccessUseCase(repository),
        backupClient: backupClient,
        networkInfo: _StubNetworkInfo(AutoSyncConnectionType.cellular),
      );

      await runner.handleAppResume(_statusWithCriticalChanges());

      expect(repository.lastSuccess, isNull);
      expect(backupClient.runCount, 0);
    });

    test('runs backup and marks success when Wi-Fi is available', () async {
      final repository = _RecordingSyncStateRepository();
      final now = DateTime.utc(2025, 11, 8, 12, 0);
      final backupClient = _StubBackupClient(
        responses: Queue<AutoSyncBackupResult>.of([
          AutoSyncBackupResult.success(completedAt: now),
        ]),
      );
      final runner = AutoSyncRunner(
        MarkAutoSyncSuccessUseCase(repository),
        backupClient: backupClient,
        networkInfo: _StubNetworkInfo(AutoSyncConnectionType.wifiLike),
        clock: () => now,
      );

      await runner.handleAppResume(_statusWithCriticalChanges());

      expect(backupClient.runCount, 1);
      expect(repository.lastSuccess, now);
    });

    test('schedules retry with backoff after failure', () async {
      final repository = _RecordingSyncStateRepository();
      DateTime current = DateTime.utc(2025, 11, 8, 12, 0);
      final responses = Queue<AutoSyncBackupResult>.of([
        AutoSyncBackupResult.failure(
          error: Exception('boom'),
          stackTrace: StackTrace.fromString('boom'),
        ),
        AutoSyncBackupResult.success(
          completedAt: current.add(const Duration(minutes: 6)),
        ),
      ]);
      final backupClient = _StubBackupClient(responses: responses);
      final runner = AutoSyncRunner(
        MarkAutoSyncSuccessUseCase(repository),
        backupClient: backupClient,
        networkInfo: _StubNetworkInfo(AutoSyncConnectionType.wifiLike),
        clock: () => current,
        initialRetryDelay: const Duration(minutes: 5),
        maxRetryDelay: const Duration(minutes: 30),
      );
      final status = _statusWithCriticalChanges();

      await runner.handleAppResume(status);

      expect(backupClient.runCount, 1);
      expect(repository.lastSuccess, isNull);
      expect(runner.nextRetryAt, current.add(const Duration(minutes: 5)));

      // Trigger resume before retry delay expires; should skip backup.
      await runner.handleAppResume(status);
      expect(backupClient.runCount, 1);

      // Advance time beyond retry delay and ensure backup runs + succeeds.
      current = current.add(const Duration(minutes: 6));
      await runner.handleAppResume(status);

      expect(backupClient.runCount, 2);
      expect(repository.lastSuccess, current);
    });
  });
}

AutoSyncStatus _statusWithCriticalChanges() {
  return AutoSyncStatus(
    autoSyncEnabled: true,
    pendingCriticalChanges: 1,
    pendingRoutineChanges: 0,
    localChangeCounter: 1,
    deviceId: 'device',
  );
}

class _StubNetworkInfo implements AutoSyncNetworkInfo {
  _StubNetworkInfo(this._type);

  final AutoSyncConnectionType _type;

  @override
  Future<AutoSyncConnectionType> connectionType() async => _type;
}

class _StubBackupClient implements AutoSyncBackupClient {
  _StubBackupClient({Queue<AutoSyncBackupResult>? responses})
    : _responses =
          responses ??
          Queue<AutoSyncBackupResult>.of(<AutoSyncBackupResult>[
            AutoSyncBackupResult.success(completedAt: DateTime.now()),
          ]);

  final Queue<AutoSyncBackupResult> _responses;
  final bool hasAccount = true;
  final String? email = 'test@example.com';
  int runCount = 0;

  @override
  bool get hasCachedAccount => hasAccount;

  @override
  String? get cachedEmail => email;

  @override
  Future<AutoSyncBackupResult> runBackup({
    bool promptIfNecessary = true,
  }) async {
    runCount += 1;
    if (_responses.isEmpty) {
      return AutoSyncBackupResult.success(completedAt: DateTime.now());
    }
    return _responses.removeFirst();
  }
}

class _RecordingSyncStateRepository implements SyncStateRepository {
  DateTime? lastSuccess;

  @override
  Future<void> ensureInitialized() async => throw UnimplementedError();

  @override
  Future<AutoSyncStatus> readStatus() => throw UnimplementedError();

  @override
  Stream<AutoSyncStatus> watchStatus({bool fireImmediately = true}) =>
      const Stream<AutoSyncStatus>.empty();

  @override
  Future<void> setAutoSyncEnabled(bool value) async =>
      throw UnimplementedError();

  @override
  Future<void> recordChange({required bool critical}) async =>
      throw UnimplementedError();

  @override
  Future<void> markSyncSuccess(DateTime completedAt) async {
    lastSuccess = completedAt;
  }

  @override
  Future<void> promoteRoutineChanges() async => throw UnimplementedError();

  @override
  Future<String> deviceId() async => 'device';
}
