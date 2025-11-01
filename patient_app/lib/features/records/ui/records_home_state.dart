import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../model/record.dart';
import '../repo/records_repo.dart';

/// Simple [ChangeNotifier] that loads recent records and exposes loading/error
/// states. This keeps UI widgets focused on presentation.
class RecordsHomeState extends ChangeNotifier {
  RecordsHomeState(this._repository);

  final RecordsRepository _repository;

  List<Record> _records = const [];
  Object? _error;
  bool _loading = false;
  Future<void>? _pendingLoad;

  List<Record> get records => _records;
  Object? get error => _error;
  bool get isLoading => _loading;
  bool get hasData => _records.isNotEmpty;

  RecordsRepository get repository => _repository;

  Record? recordById(Id id) {
    for (final record in _records) {
      if (record.id == id) return record;
    }
    return null;
  }

  Future<void> load({int limit = 50, bool force = false}) {
    final current = _pendingLoad;
    if (current != null && !force) {
      return current;
    }
    final future = _performLoad(limit);
    _pendingLoad = future;
    future.whenComplete(() {
      if (identical(_pendingLoad, future)) {
        _pendingLoad = null;
      }
    });
    return future;
  }

  Future<Record> saveRecord(Record record) async {
    final savedId = await _repository.add(record);
    record.id = savedId;

    final updated = List<Record>.from(_records);
    final index = updated.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      updated[index] = record;
    } else {
      updated.add(record);
    }
    updated.sort((a, b) => b.date.compareTo(a.date));
    _records = updated;
    notifyListeners();
    return record;
  }

  Future<void> deleteRecord(Id id) async {
    await _repository.delete(id);
    _records = _records.where((r) => r.id != id).toList(growable: false);
    notifyListeners();
  }

  Future<void> _performLoad(int limit) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _records = await _repository.recent(limit: limit);
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
