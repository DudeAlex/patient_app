import 'package:flutter/foundation.dart';

import '../../sync/dirty_tracker.dart';
import '../../sync/sync_state_repository.dart';
import '../application/use_cases/delete_record_use_case.dart';
import '../application/use_cases/fetch_records_page_use_case.dart';
import '../application/use_cases/save_record_use_case.dart';
import '../domain/entities/record.dart';

/// Simple [ChangeNotifier] that loads recent records and exposes loading/error
/// states. This keeps UI widgets focused on presentation.
class RecordsHomeState extends ChangeNotifier {
  RecordsHomeState(
    this._fetchRecordsPage,
    this._saveRecordCase,
    this._deleteRecordCase,
    this._dirtyTracker,
    this._syncStateRepository,
  );

  static const int _pageSize = 20;

  final FetchRecordsPageUseCase _fetchRecordsPage;
  final SaveRecordUseCase _saveRecordCase;
  final DeleteRecordUseCase _deleteRecordCase;
  final AutoSyncDirtyTracker _dirtyTracker;
  final SyncStateRepository _syncStateRepository;

  List<RecordEntity> _records = const <RecordEntity>[];
  Object? _error;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _initialised = false;
  String _searchQuery = '';

  List<RecordEntity> get records => _records;
  Object? get error => _error;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  bool get hasData => _records.isNotEmpty;
  String get searchQuery => _searchQuery;

  SyncStateRepository get syncStateRepository => _syncStateRepository;

  RecordEntity? recordById(int id) {
    for (final record in _records) {
      if (record.id == id) return record;
    }
    return null;
  }

  Future<void> load({String? query, bool force = false}) async {
    final normalized = (query ?? _searchQuery).trim();
    final shouldReset = force || !_initialised || normalized != _searchQuery;
    if (!shouldReset && _records.isNotEmpty) return;

    _searchQuery = normalized;
    _initialised = true;
    _records = const <RecordEntity>[];
    _hasMore = true;
    _error = null;
    _loading = true;
    notifyListeners();

    await _fetchPage(reset: true);
  }

  Future<void> loadMore() async {
    await _fetchPage(reset: false);
  }

  Future<RecordEntity> saveRecord(RecordEntity record) async {
    final output = await _saveRecordCase.execute(
      SaveRecordInput(record: record),
    );
    await _dirtyTracker.recordRecordSave(output.record);
    await load(query: _searchQuery, force: true);
    return output.record;
  }

  Future<void> deleteRecord(int id) async {
    final existing = recordById(id);
    await _deleteRecordCase.execute(DeleteRecordInput(recordId: id));
    await _dirtyTracker.recordRecordDelete(existing);
    await load(query: _searchQuery, force: true);
  }

  Future<void> _fetchPage({required bool reset}) async {
    if (_loadingMore) return;
    if (!reset && !_hasMore) return;

    if (!reset && _loading) return;

    _loadingMore = true;
    notifyListeners();

    try {
      final offset = reset ? 0 : _records.length;
      final output = await _fetchRecordsPage.execute(
        FetchRecordsPageInput(
          offset: offset,
          limit: _pageSize,
          query: _searchQuery,
        ),
      );
      if (reset) {
        _records = output.records;
      } else {
        _records = [..._records, ...output.records];
      }
      _hasMore = output.hasMore;
      _error = null;
    } catch (e) {
      _error = e;
      if (reset) {
        _records = const <RecordEntity>[];
      }
    } finally {
      _loading = false;
      _loadingMore = false;
      notifyListeners();
    }
  }
}
