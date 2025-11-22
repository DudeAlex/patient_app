import 'dart:async';

import '../models/ai_call_log_entry.dart';

class AiCallLogRepository {
  final _entries = <AiCallLogEntry>[];
  final _controller = StreamController<List<AiCallLogEntry>>.broadcast();
  final int maxEntries;

  AiCallLogRepository({this.maxEntries = 20});

  List<AiCallLogEntry> get entries => List.unmodifiable(_entries);
  Stream<List<AiCallLogEntry>> get stream => _controller.stream;

  void add(AiCallLogEntry entry) {
    _entries.insert(0, entry);
    if (_entries.length > maxEntries) {
      _entries.removeLast();
    }
    _controller.add(entries);
  }

  void dispose() {
    _controller.close();
  }
}
