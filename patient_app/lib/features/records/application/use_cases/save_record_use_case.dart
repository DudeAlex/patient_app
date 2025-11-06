import '../../domain/entities/record.dart';
import '../ports/records_repository.dart';

/// Input DTO for [SaveRecordUseCase].
class SaveRecordInput {
  const SaveRecordInput({required this.record});

  final RecordEntity record;
}

/// Output DTO for [SaveRecordUseCase].
class SaveRecordOutput {
  const SaveRecordOutput({required this.record});

  final RecordEntity record;
}

/// Persists a [RecordEntity] via the [RecordsRepository] port.
class SaveRecordUseCase {
  SaveRecordUseCase(this._repository);

  final RecordsRepository _repository;

  Future<SaveRecordOutput> execute(SaveRecordInput input) async {
    final saved = await _repository.save(input.record);
    return SaveRecordOutput(record: saved);
  }
}
