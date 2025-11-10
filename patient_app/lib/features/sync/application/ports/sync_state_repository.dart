import '../../domain/entities/auto_sync_cadence.dart';
import '../../domain/entities/auto_sync_status.dart';

/// Repository port exposing sync state persistence operations to application
/// and UI layers. Implementations live in the adapters layer (e.g., Isar).
abstract class SyncStateRepository {
  Future<void> ensureInitialized();

  Future<AutoSyncStatus> readStatus();

  Stream<AutoSyncStatus> watchStatus({bool fireImmediately = true});

  Future<void> setAutoSyncEnabled(bool value);
  Future<void> setAutoSyncCadence(AutoSyncCadence cadence);

  Future<void> recordChange({required bool critical});

  Future<void> markSyncSuccess(DateTime completedAt);

  Future<void> promoteRoutineChanges();

  Future<String> deviceId();
}
