import '../ports/sync_state_repository.dart';

class SetAutoSyncEnabledInput {
  const SetAutoSyncEnabledInput({required this.enabled});

  final bool enabled;
}

class SetAutoSyncEnabledUseCase {
  const SetAutoSyncEnabledUseCase(this._repository);

  final SyncStateRepository _repository;

  Future<void> execute(SetAutoSyncEnabledInput input) {
    return _repository.setAutoSyncEnabled(input.enabled);
  }
}
