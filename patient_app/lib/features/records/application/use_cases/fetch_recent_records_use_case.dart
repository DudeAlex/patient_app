import '../../domain/entities/record.dart';
import '../ports/records_repository.dart';

/// Input DTO for [FetchRecentRecordsUseCase].
class FetchRecentRecordsInput {
  const FetchRecentRecordsInput({this.limit = 50});

  final int limit;
}

/// Output DTO for [FetchRecentRecordsUseCase].
class FetchRecentRecordsOutput {
  const FetchRecentRecordsOutput({required this.records});

  final List<RecordEntity> records;
}

/// Retrieves the latest records using the repository port.
class FetchRecentRecordsUseCase {
  FetchRecentRecordsUseCase(this._repository);

  final RecordsRepository _repository;

  Future<FetchRecentRecordsOutput> execute(
    FetchRecentRecordsInput input,
  ) async {
    final results = await _repository.recent(limit: input.limit);
    return FetchRecentRecordsOutput(records: results);
  }
}
