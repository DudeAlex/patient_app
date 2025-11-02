import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../../sync/dirty_tracker.dart';
import '../../sync/sync_state_repository.dart';
import '../model/record.dart';
import '../repo/records_repo.dart';

/// Simple [ChangeNotifier] that loads recent records and exposes loading/error
/// states. This keeps UI widgets focused on presentation.
class RecordsHomeState extends ChangeNotifier {
  RecordsHomeState(this._repository, this._dirtyTracker, this._syncStateRepository);

  static const int _pageSize = 20;

  final RecordsRepository _repository;
  final AutoSyncDirtyTracker _dirtyTracker;
  final SyncStateRepository _syncStateRepository;

  List<Record> _records = const [];
  Object? _error;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _initialised = false;
  String _searchQuery = '';

  List<Record> get records => _records;
  Object? get error => _error;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  bool get hasData => _records.isNotEmpty;
  String get searchQuery => _searchQuery;

  RecordsRepository get repository => _repository;
  SyncStateRepository get syncStateRepository => _syncStateRepository;

  Record? recordById(Id id) {
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
    _records = const [];
    _hasMore = true;
    _error = null;
    _loading = true;
    notifyListeners();

    await _fetchPage(reset: true);
  }

  Future<void> loadMore() async {
    await _fetchPage(reset: false);
  }

  Future<Record> saveRecord(Record record) async {
    final savedId = await _repository.add(record);
    record.id = savedId;
    await _dirtyTracker.recordRecordSave(record);
    await load(query: _searchQuery, force: true);
    return record;
  }

  Future<void> deleteRecord(Id id) async {
    final existing = recordById(id) ?? await _repository.byId(id);
    await _repository.delete(id);
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
      final results = await _repository.fetchPage(
        offset: offset,
        limit: _pageSize,
        query: _searchQuery,
      );
      if (reset) {
        _records = results;
      } else {
        _records = [..._records, ...results];
      }
      _hasMore = results.length == _pageSize;
      _error = null;
    } catch (e) {
      _error = e;
      if (reset) {
        _records = const [];
      }
    } finally {
      _loading = false;
      _loadingMore = false;
      notifyListeners();
    }
  }
}
