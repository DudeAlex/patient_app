import '../ports/records_repository.dart';

/// Input DTO for [DeleteRecordUseCase].
class DeleteRecordInput {
  const DeleteRecordInput({required this.recordId});

  final int recordId;
}

/// Output DTO for [DeleteRecordUseCase].
class DeleteRecordOutput {
  const DeleteRecordOutput({required this.recordId});

  final int recordId;
}

/// Removes a record via the repository abstraction.
class DeleteRecordUseCase {
  DeleteRecordUseCase(this._repository);

  final RecordsRepository _repository;

  Future<DeleteRecordOutput> execute(DeleteRecordInput input) async {
    await _repository.delete(input.recordId);
    return DeleteRecordOutput(recordId: input.recordId);
  }
}
