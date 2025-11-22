import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../records/model/sync_state.dart';
import '../../application/ports/sync_state_repository.dart';
import '../../domain/entities/auto_sync_cadence.dart';
import '../../domain/entities/auto_sync_status.dart';

/// Persists and exposes the singleton sync state record that tracks pending
/// changes and auto sync preferences.
class IsarSyncStateRepository implements SyncStateRepository {
  IsarSyncStateRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Isar _db;
  final Uuid _uuid;

  String? _deviceIdCache;

  @override
  Future<void> ensureInitialized() async {
    await _db.writeTxn(() async {
      await _ensureState();
    });
  }

  Future<SyncState?> _readState() async {
    final state = await _db.syncStates.get(1);
    if (state != null && state.deviceId.isNotEmpty) {
      _deviceIdCache ??= state.deviceId;
    }
    return state;
  }

  @override
  Future<AutoSyncStatus> readStatus() async {
    final existing = await _readState();
    if (existing != null) {
      return _mapToStatus(existing);
    }
    final ensured = await _ensureState();
    return _mapToStatus(ensured);
  }

  @override
  Stream<AutoSyncStatus> watchStatus({bool fireImmediately = true}) async* {
    await for (final state in _db.syncStates.watchObject(
      1,
      fireImmediately: fireImmediately,
    )) {
      if (state != null) {
        yield _mapToStatus(state);
      } else {
        final ensured = await _ensureState();
        yield _mapToStatus(ensured);
      }
    }
  }

  @override
  Future<void> setAutoSyncEnabled(bool value) async {
    await _db.writeTxn(() async {
      final state = await _ensureState();
      state.autoSyncEnabled = value;
      await _db.syncStates.put(state);
    });
  }

  @override
  Future<void> setAutoSyncCadence(AutoSyncCadence cadence) async {
    await _db.writeTxn(() async {
      final state = await _ensureState();
      state.autoSyncCadenceId = cadence.id;
      await _db.syncStates.put(state);
    });
  }

  @override
  Future<void> recordChange({required bool critical}) async {
    await _db.writeTxn(() async {
      final state = await _ensureState();
      if (critical) {
        state.pendingCriticalChanges += 1;
      } else {
        state.pendingRoutineChanges += 1;
      }
      state.localChangeCounter =
          state.pendingCriticalChanges + state.pendingRoutineChanges;
      await _db.syncStates.put(state);
    });
  }

  @override
  Future<void> markSyncSuccess(DateTime completedAt) async {
    await _db.writeTxn(() async {
      final state = await _ensureState();
      state.pendingCriticalChanges = 0;
      state.pendingRoutineChanges = 0;
      state.localChangeCounter = 0;
      state.lastSyncedAt = completedAt;
      await _db.syncStates.put(state);
    });
  }

  @override
  Future<void> promoteRoutineChanges() async {
    await _db.writeTxn(() async {
      final state = await _ensureState();
      state.pendingCriticalChanges += state.pendingRoutineChanges;
      state.pendingRoutineChanges = 0;
      state.localChangeCounter = state.pendingCriticalChanges;
      await _db.syncStates.put(state);
    });
  }

  @override
  Future<String> deviceId() async {
    if (_deviceIdCache != null) {
      return _deviceIdCache!;
    }
    final state = await _ensureState();
    _deviceIdCache = state.deviceId;
    return _deviceIdCache!;
  }

  Future<SyncState> _ensureState() async {
    var state = await _db.syncStates.get(1);
    if (state == null) {
      state = SyncState()
        ..id = 1
        ..deviceId = _uuid.v4();
      await _db.syncStates.put(state);
    } else if (state.deviceId.isEmpty) {
      state.deviceId = _uuid.v4();
      await _db.syncStates.put(state);
    }
    if (state.autoSyncCadenceId.isEmpty) {
      state.autoSyncCadenceId = AutoSyncCadence.weekly.id;
      await _db.syncStates.put(state);
    }
    _deviceIdCache ??= state.deviceId;
    return state;
  }

  AutoSyncStatus _mapToStatus(SyncState state) {
    return AutoSyncStatus(
      autoSyncEnabled: state.autoSyncEnabled,
      pendingCriticalChanges: state.pendingCriticalChanges,
      pendingRoutineChanges: state.pendingRoutineChanges,
      localChangeCounter: state.localChangeCounter,
      lastSyncedAt: state.lastSyncedAt,
      lastRemoteModified: state.lastRemoteModified,
      deviceId: state.deviceId,
      cadence: AutoSyncCadence.fromId(state.autoSyncCadenceId),
    );
  }
}
