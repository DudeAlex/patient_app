import 'package:flutter/foundation.dart';

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
