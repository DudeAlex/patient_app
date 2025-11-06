import 'dart:async';

import 'package:isar/isar.dart';

import '../../../core/db/isar.dart' as db_helpers;
import '../../sync/auto_sync_coordinator.dart';
import '../../sync/auto_sync_runner.dart';
import '../../sync/dirty_tracker.dart';
import '../../sync/sync_state_repository.dart';
import '../adapters/repositories/isar_records_repository.dart';
import '../application/ports/records_repository.dart' as port;
import '../application/use_cases/delete_record_use_case.dart';
import '../application/use_cases/fetch_recent_records_use_case.dart';
import '../application/use_cases/fetch_records_page_use_case.dart';
import '../application/use_cases/get_record_by_id_use_case.dart';
import '../application/use_cases/save_record_use_case.dart';

/// Singleton wrapper that exposes a shared [RecordsRepository] backed by the
/// Isar database. Consumers call [RecordsService.instance] to obtain the lazy
/// loaded service rather than opening Isar manually.
class RecordsService {
  RecordsService._(
    this.db,
    this.records,
    this.fetchRecordsPage,
    this.fetchRecentRecords,
    this.getRecordById,
    this.saveRecord,
    this.deleteRecord,
    this.syncState,
    this.dirtyTracker,
    this.autoSync,
  );

  final Isar db;
  final port.RecordsRepository records;
  final FetchRecordsPageUseCase fetchRecordsPage;
  final FetchRecentRecordsUseCase fetchRecentRecords;
  final GetRecordByIdUseCase getRecordById;
  final SaveRecordUseCase saveRecord;
  final DeleteRecordUseCase deleteRecord;
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
    final repo = IsarRecordsRepository(isar);
    final fetchRecordsPage = FetchRecordsPageUseCase(repo);
    final fetchRecentRecords = FetchRecentRecordsUseCase(repo);
    final getRecordById = GetRecordByIdUseCase(repo);
    final saveRecord = SaveRecordUseCase(repo);
    final deleteRecord = DeleteRecordUseCase(repo);
    final syncRepo = SyncStateRepository(isar);
    await syncRepo.ensureInitialized();
    final tracker = AutoSyncDirtyTracker(syncRepo);
    final autoSyncRunner = AutoSyncRunner(syncRepo);
    final autoSync = AutoSyncCoordinator(syncRepo, autoSyncRunner)..start();
    return RecordsService._(
      isar,
      repo,
      fetchRecordsPage,
      fetchRecentRecords,
      getRecordById,
      saveRecord,
      deleteRecord,
      syncRepo,
      tracker,
      autoSync,
    );
  }
}
