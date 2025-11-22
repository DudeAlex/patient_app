import '../ports/sync_state_repository.dart';

class MarkAutoSyncSuccessInput {
  const MarkAutoSyncSuccessInput({required this.completedAt});

  final DateTime completedAt;
}

class MarkAutoSyncSuccessUseCase {
  const MarkAutoSyncSuccessUseCase(this._repository);

  final SyncStateRepository _repository;

  Future<void> execute(MarkAutoSyncSuccessInput input) {
    return _repository.markSyncSuccess(input.completedAt);
  }
}
