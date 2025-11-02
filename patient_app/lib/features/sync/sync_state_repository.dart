import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../records/model/sync_state.dart';

/// Persists and exposes the singleton [SyncState] record that tracks pending
/// changes and auto sync preferences.
class SyncStateRepository {
  SyncStateRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Isar _db;
  final Uuid _uuid;

  String? _deviceIdCache;

  /// Ensures the sync state row exists and returns it.
  Future<SyncState> ensureInitialized() async {
    return _db.writeTxn(() async => _ensureState());
  }

  /// Reads the cached state without mutating counters.
  Future<SyncState?> read() async {
    final state = await _db.syncStates.get(1);
    if (state != null && state.deviceId.isNotEmpty) {
      _deviceIdCache ??= state.deviceId;
    }
    return state;
  }

  /// Updates the auto-sync toggle persisted in Isar.
  Future<void> setAutoSyncEnabled(bool value) async {
    await _db.writeTxn(() async {
      final state = await _ensureState();
      state.autoSyncEnabled = value;
      await _db.syncStates.put(state);
    });
  }

  /// Records a new local change, splitting into critical vs routine queues.
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

  /// Marks a successful sync run, clearing dirty counters and recording time.
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

  /// Upgrades accumulated routine changes into the critical queue.
  Future<void> promoteRoutineChanges() async {
    await _db.writeTxn(() async {
      final state = await _ensureState();
      state.pendingCriticalChanges += state.pendingRoutineChanges;
      state.pendingRoutineChanges = 0;
      state.localChangeCounter = state.pendingCriticalChanges;
      await _db.syncStates.put(state);
    });
  }

  /// Returns a stable device ID, creating one if needed.
  Future<String> deviceId() async {
    if (_deviceIdCache != null) {
      return _deviceIdCache!;
    }
    final state = await ensureInitialized();
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
    _deviceIdCache ??= state.deviceId;
    return state;
  }
}
