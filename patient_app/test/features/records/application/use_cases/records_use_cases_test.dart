import 'package:flutter_test/flutter_test.dart';

import 'package:patient_app/features/records/application/ports/records_repository.dart';
import 'package:patient_app/features/records/application/use_cases/delete_record_use_case.dart';
import 'package:patient_app/features/records/application/use_cases/fetch_recent_records_use_case.dart';
import 'package:patient_app/features/records/application/use_cases/fetch_records_page_use_case.dart';
import 'package:patient_app/features/records/application/use_cases/get_record_by_id_use_case.dart';
import 'package:patient_app/features/records/application/use_cases/save_record_use_case.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

void main() {
  group('SaveRecordUseCase', () {
    test('persists record and returns saved entity', () async {
      final repository = _RecordingRepository();
      final initial = _buildRecord(id: null, title: 'Initial');
      final saved = _buildRecord(id: 1, title: 'Saved');
      repository.saveResult = saved;

      final useCase = SaveRecordUseCase(repository);
      final output = await useCase.execute(SaveRecordInput(record: initial));

      expect(repository.saveInput, same(initial));
      expect(output.record, same(saved));
    });
  });

  group('FetchRecentRecordsUseCase', () {
    test('requests recent records with provided limit', () async {
      final repository = _RecordingRepository();
      final records = [
        _buildRecord(id: 1, title: 'One'),
        _buildRecord(id: 2, title: 'Two'),
      ];
      repository.recentResults = records;

      final useCase = FetchRecentRecordsUseCase(repository);
      final output = await useCase.execute(
        const FetchRecentRecordsInput(limit: 10),
      );

      expect(repository.recentLimit, 10);
      expect(output.records, records);
    });
  });

  group('FetchRecordsPageUseCase', () {
    test('trims query and reports hasMore when limit reached', () async {
      final repository = _RecordingRepository();
      final records = List<RecordEntity>.generate(
        2,
        (index) => _buildRecord(id: index + 1, title: 'Record ${index + 1}'),
      );
      repository.fetchPageResults = records;

      final useCase = FetchRecordsPageUseCase(repository);
      final output = await useCase.execute(
        const FetchRecordsPageInput(offset: 0, limit: 2, query: '  search  '),
      );

      expect(repository.fetchPageArgs?.query, 'search');
      expect(repository.fetchPageArgs?.offset, 0);
      expect(repository.fetchPageArgs?.limit, 2);
      expect(output.records, records);
      expect(output.hasMore, isTrue); // same size as limit => more pages likely
    });

    test('normalises empty query to null and detects end of results', () async {
      final repository = _RecordingRepository();
      final records = [
        _buildRecord(id: 10, title: 'Last'),
      ];
      repository.fetchPageResults = records;

      final useCase = FetchRecordsPageUseCase(repository);
      final output = await useCase.execute(
        const FetchRecordsPageInput(offset: 20, limit: 10, query: '  '),
      );

      expect(repository.fetchPageArgs?.query, isNull);
      expect(output.records, records);
      expect(output.hasMore, isFalse);
    });
  });

  group('GetRecordByIdUseCase', () {
    test('returns record when repository finds one', () async {
      final repository = _RecordingRepository();
      final record = _buildRecord(id: 99, title: 'Lookup');
      repository.store(record);

      final useCase = GetRecordByIdUseCase(repository);
      final output =
          await useCase.execute(const GetRecordByIdInput(id: 99));

      expect(output.record, same(record));
    });

    test('returns null when record missing', () async {
      final repository = _RecordingRepository();
      final useCase = GetRecordByIdUseCase(repository);

      final output =
          await useCase.execute(const GetRecordByIdInput(id: 123));

      expect(output.record, isNull);
    });
  });

  group('DeleteRecordUseCase', () {
    test('delegates to repository and returns deleted id', () async {
      final repository = _RecordingRepository();
      final useCase = DeleteRecordUseCase(repository);

      final output = await useCase.execute(const DeleteRecordInput(recordId: 7));

      expect(repository.deletedIds.single, 7);
      expect(output.recordId, 7);
    });
  });
}

class _RecordingRepository implements RecordsRepository {
  RecordEntity? saveInput;
  RecordEntity? saveResult;

  List<RecordEntity> recentResults = const <RecordEntity>[];
  int? recentLimit;

  final Map<int, RecordEntity> _recordsById = <int, RecordEntity>{};

  List<RecordEntity> fetchPageResults = const <RecordEntity>[];
  _FetchPageArgs? fetchPageArgs;

  final List<int> deletedIds = <int>[];

  @override
  Future<RecordEntity> save(RecordEntity record) async {
    saveInput = record;
    final result = saveResult ?? record;
    if (result.id != null) {
      _recordsById[result.id!] = result;
    }
    return result;
  }

  @override
  Future<List<RecordEntity>> recent({int limit = 50}) async {
    recentLimit = limit;
    return recentResults;
  }

  @override
  Future<RecordEntity?> byId(int id) async {
    return _recordsById[id];
  }

  @override
  Future<void> delete(int id) async {
    deletedIds.add(id);
    _recordsById.remove(id);
  }

  @override
  Future<List<RecordEntity>> fetchPage({
    required int offset,
    required int limit,
    String? query,
  }) async {
    fetchPageArgs = _FetchPageArgs(offset: offset, limit: limit, query: query);
    return fetchPageResults;
  }
}

extension on _RecordingRepository {
  void store(RecordEntity record) {
    if (record.id == null) {
      throw ArgumentError('Record must have an id to store.');
    }
    _recordsById[record.id!] = record;
  }
}

class _FetchPageArgs {
  _FetchPageArgs({required this.offset, required this.limit, this.query});

  final int offset;
  final int limit;
  final String? query;
}

RecordEntity _buildRecord({int? id, required String title}) {
  final now = DateTime(2025, 1, 1);
  return RecordEntity(
    id: id,
    type: 'note',
    date: now,
    title: title,
    text: 'Body for $title',
    tags: const ['note'],
    createdAt: now,
    updatedAt: now,
  );
}
