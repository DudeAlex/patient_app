import '../../domain/entities/record.dart';
import '../ports/records_repository.dart';

/// Input DTO for [FetchRecordsPageUseCase].
class FetchRecordsPageInput {
  const FetchRecordsPageInput({
    required this.offset,
    required this.limit,
    this.query,
  });

  final int offset;
  final int limit;
  final String? query;
}

/// Output DTO for [FetchRecordsPageUseCase].
class FetchRecordsPageOutput {
  const FetchRecordsPageOutput({
    required this.records,
    required this.hasMore,
  });

  final List<RecordEntity> records;
  final bool hasMore;
}

/// Paginates records and applies an optional text query.
class FetchRecordsPageUseCase {
  FetchRecordsPageUseCase(this._repository);

  final RecordsRepository _repository;

  Future<FetchRecordsPageOutput> execute(
    FetchRecordsPageInput input,
  ) async {
    final trimmedQuery = input.query?.trim();
    final results = await _repository.fetchPage(
      offset: input.offset,
      limit: input.limit,
      query: trimmedQuery?.isEmpty == true ? null : trimmedQuery,
    );
    final hasMore = results.length == input.limit;
    return FetchRecordsPageOutput(records: results, hasMore: hasMore);
  }
}
