import '../ports/sync_state_repository.dart';

class RecordAutoSyncChangeInput {
  const RecordAutoSyncChangeInput({required this.critical});

  final bool critical;
}

class RecordAutoSyncChangeUseCase {
  const RecordAutoSyncChangeUseCase(this._repository);

  final SyncStateRepository _repository;

  Future<void> execute(RecordAutoSyncChangeInput input) {
    return _repository.recordChange(critical: input.critical);
  }
}
