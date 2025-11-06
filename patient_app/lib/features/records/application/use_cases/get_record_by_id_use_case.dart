import '../../domain/entities/record.dart';
import '../ports/records_repository.dart';

/// Input DTO for [GetRecordByIdUseCase].
class GetRecordByIdInput {
  const GetRecordByIdInput({required this.id});

  final int id;
}

/// Output DTO for [GetRecordByIdUseCase].
class GetRecordByIdOutput {
  const GetRecordByIdOutput({required this.record});

  final RecordEntity? record;
}

/// Retrieves a single record by id through the repository port.
class GetRecordByIdUseCase {
  const GetRecordByIdUseCase(this._repository);

  final RecordsRepository _repository;

  Future<GetRecordByIdOutput> execute(GetRecordByIdInput input) async {
    final record = await _repository.byId(input.id);
    return GetRecordByIdOutput(record: record);
  }
}
