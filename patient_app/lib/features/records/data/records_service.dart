import 'dart:async';

import 'package:isar/isar.dart';

import '../../../core/db/isar.dart' as db_helpers;
import '../../sync/dirty_tracker.dart';
import '../../sync/sync_state_repository.dart';
import '../../sync/auto_sync_coordinator.dart';
import '../../sync/auto_sync_runner.dart';
import '../repo/records_repo.dart';

/// Singleton wrapper that exposes a shared [RecordsRepository] backed by the
/// Isar database. Consumers call [RecordsService.instance] to obtain the lazy
/// loaded service rather than opening Isar manually.
class RecordsService {
  RecordsService._(
    this.db,
    this.records,
    this.syncState,
    this.dirtyTracker,
    this.autoSync,
  );

  final Isar db;
  final RecordsRepository records;
  final SyncStateRepository syncState;
  final AutoSyncDirtyTracker dirtyTracker;
  final AutoSyncCoordinator autoSync;

  static Future<RecordsService>? _pending;

  /// Returns the cached service instance, opening the Isar database on first
  /// access. Subsequent calls reuse the same [Future] so concurrent callers do
  /// not trigger multiple openings.
  static Future<RecordsService> instance() {
    final cached = _pending;
    if (cached != null) {
      return cached;
    }
    final future = _create();
    _pending = future;
    return future;
  }

  static Future<RecordsService> _create() async {
    final isar = await db_helpers.IsarDatabase.open(
      // Encryption-at-rest is not enabled yet; we pass a stable placeholder key
      // to maintain API compatibility when encryption lands (see SPEC.md).
      encryptionKey: List<int>.filled(32, 0),
    );
    final repo = RecordsRepository(isar);
    final syncRepo = SyncStateRepository(isar);
    await syncRepo.ensureInitialized();
    final tracker = AutoSyncDirtyTracker(syncRepo);
    final autoSyncRunner = AutoSyncRunner(syncRepo);
    final autoSync = AutoSyncCoordinator(syncRepo, autoSyncRunner)..start();
    return RecordsService._(isar, repo, syncRepo, tracker, autoSync);
  }
}
