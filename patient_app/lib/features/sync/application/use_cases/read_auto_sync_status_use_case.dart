import '../../domain/entities/auto_sync_status.dart';
import '../ports/sync_state_repository.dart';

class ReadAutoSyncStatusUseCase {
  const ReadAutoSyncStatusUseCase(this._repository);

  final SyncStateRepository _repository;

  Future<AutoSyncStatus> execute() {
    return _repository.readStatus();
  }
}
