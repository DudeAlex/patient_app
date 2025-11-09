import 'dart:async';

import 'package:isar/isar.dart';

import '../../../core/db/isar.dart' as db_helpers;
import '../../sync/adapters/repositories/isar_sync_state_repository.dart';
import '../../sync/application/use_cases/mark_auto_sync_success_use_case.dart';
import '../../sync/application/use_cases/promote_routine_changes_use_case.dart';
import '../../sync/application/use_cases/read_auto_sync_status_use_case.dart';
import '../../sync/application/use_cases/record_auto_sync_change_use_case.dart';
import '../../sync/application/use_cases/set_auto_sync_enabled_use_case.dart';
import '../../sync/application/use_cases/watch_auto_sync_status_use_case.dart';
import '../../sync/auto_sync_backup_service.dart';
import '../../sync/auto_sync_coordinator.dart';
import '../../sync/auto_sync_runner.dart';
import '../../sync/dirty_tracker.dart';
import '../../sync/network/auto_sync_network_info.dart';
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
  RecordsService._({
    required this.db,
    required this.records,
    required this.fetchRecordsPage,
    required this.fetchRecentRecords,
    required this.getRecordById,
    required this.saveRecord,
    required this.deleteRecord,
    required this.dirtyTracker,
    required this.backupService,
    required this.autoSync,
    required this.setAutoSyncEnabled,
    required this.readAutoSyncStatus,
  });

  final Isar db;
  final port.RecordsRepository records;
  final FetchRecordsPageUseCase fetchRecordsPage;
  final FetchRecentRecordsUseCase fetchRecentRecords;
  final GetRecordByIdUseCase getRecordById;
  final SaveRecordUseCase saveRecord;
  final DeleteRecordUseCase deleteRecord;
  final AutoSyncDirtyTracker dirtyTracker;
  final AutoSyncBackupService backupService;
  final AutoSyncCoordinator autoSync;
  final SetAutoSyncEnabledUseCase setAutoSyncEnabled;
  final ReadAutoSyncStatusUseCase readAutoSyncStatus;

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
    final syncRepo = IsarSyncStateRepository(isar);
    await syncRepo.ensureInitialized();
    final recordChangeUseCase = RecordAutoSyncChangeUseCase(syncRepo);
    final tracker = AutoSyncDirtyTracker(recordChangeUseCase);
    final markSuccess = MarkAutoSyncSuccessUseCase(syncRepo);
    final backupService = AutoSyncBackupService();
    final autoSyncRunner = AutoSyncRunner(
      markSuccess,
      backupClient: backupService,
      networkInfo: ConnectivityAutoSyncNetworkInfo(),
    );
    final watchStatus = WatchAutoSyncStatusUseCase(syncRepo);
    final promoteRoutineChanges = PromoteRoutineChangesUseCase(syncRepo);
    final autoSync = AutoSyncCoordinator(
      watchStatus,
      autoSyncRunner,
      promoteRoutineChanges,
    )..start();
    final setAutoSyncEnabled = SetAutoSyncEnabledUseCase(syncRepo);
    final readAutoSyncStatus = ReadAutoSyncStatusUseCase(syncRepo);
    return RecordsService._(
      db: isar,
      records: repo,
      fetchRecordsPage: fetchRecordsPage,
      fetchRecentRecords: fetchRecentRecords,
      getRecordById: getRecordById,
      saveRecord: saveRecord,
      deleteRecord: deleteRecord,
      dirtyTracker: tracker,
      backupService: backupService,
      autoSync: autoSync,
      setAutoSyncEnabled: setAutoSyncEnabled,
      readAutoSyncStatus: readAutoSyncStatus,
    );
  }
}
