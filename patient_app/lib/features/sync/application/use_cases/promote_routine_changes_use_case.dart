import '../ports/sync_state_repository.dart';

class PromoteRoutineChangesUseCase {
  const PromoteRoutineChangesUseCase(this._repository);

  final SyncStateRepository _repository;

  Future<void> execute() {
    return _repository.promoteRoutineChanges();
  }
}
