import '../../domain/entities/auto_sync_cadence.dart';
import '../ports/sync_state_repository.dart';

class SetAutoSyncCadenceInput {
  const SetAutoSyncCadenceInput({required this.cadence});

  final AutoSyncCadence cadence;
}

class SetAutoSyncCadenceUseCase {
  const SetAutoSyncCadenceUseCase(this._repository);

  final SyncStateRepository _repository;

  Future<void> execute(SetAutoSyncCadenceInput input) {
    return _repository.setAutoSyncCadence(input.cadence);
  }
}
