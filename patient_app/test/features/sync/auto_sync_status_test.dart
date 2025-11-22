import 'package:flutter_test/flutter_test.dart';

import 'package:patient_app/features/sync/domain/entities/auto_sync_cadence.dart';
import 'package:patient_app/features/sync/domain/entities/auto_sync_status.dart';

void main() {
  group('AutoSyncStatus invariants', () {
    test('allows valid pending counts and computes helpers', () {
      final status = AutoSyncStatus(
        autoSyncEnabled: true,
        pendingCriticalChanges: 2,
        pendingRoutineChanges: 1,
        localChangeCounter: 3,
        deviceId: 'device-123',
        cadence: AutoSyncCadence.weekly,
        lastSyncedAt: DateTime(2025, 1, 1),
      );

      expect(status.hasPendingCriticalChanges, isTrue);
      expect(status.hasPendingRoutineChanges, isTrue);
      expect(status.hasPendingChanges, isTrue);
      expect(status.deviceId, 'device-123');

      final copy = status.copyWith(pendingRoutineChanges: 0);
      expect(copy.pendingRoutineChanges, 0);
      expect(copy.hasPendingRoutineChanges, isFalse);
    });

    test('throws when pending counts are negative', () {
      expect(
        () => AutoSyncStatus(
          autoSyncEnabled: false,
          pendingCriticalChanges: -1,
          pendingRoutineChanges: 0,
          localChangeCounter: 0,
          deviceId: 'abc',
          cadence: AutoSyncCadence.weekly,
        ),
        throwsAssertionError,
      );

      expect(
        () => AutoSyncStatus(
          autoSyncEnabled: false,
          pendingCriticalChanges: 0,
          pendingRoutineChanges: -5,
          localChangeCounter: 0,
          deviceId: 'abc',
          cadence: AutoSyncCadence.weekly,
        ),
        throwsAssertionError,
      );
    });

    test('throws when local change counter is inconsistent', () {
      expect(
        () => AutoSyncStatus(
          autoSyncEnabled: true,
          pendingCriticalChanges: 2,
          pendingRoutineChanges: 2,
          localChangeCounter: 3,
          deviceId: 'abc',
          cadence: AutoSyncCadence.weekly,
        ),
        throwsAssertionError,
      );
    });

    test('throws when device id is empty', () {
      expect(
        () => AutoSyncStatus(
          autoSyncEnabled: true,
          pendingCriticalChanges: 0,
          pendingRoutineChanges: 0,
          localChangeCounter: 0,
          deviceId: '',
          cadence: AutoSyncCadence.weekly,
        ),
        throwsAssertionError,
      );
    });
  });
}
