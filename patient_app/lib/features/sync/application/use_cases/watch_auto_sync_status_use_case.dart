import '../../domain/entities/auto_sync_status.dart';
import '../ports/sync_state_repository.dart';

class WatchAutoSyncStatusUseCase {
  const WatchAutoSyncStatusUseCase(this._repository);

  final SyncStateRepository _repository;

  Stream<AutoSyncStatus> execute({bool fireImmediately = true}) {
    return _repository.watchStatus(fireImmediately: fireImmediately);
  }
}
