import '../records/model/record.dart';
import '../records/model/record_types.dart';

import 'sync_state_repository.dart';

/// Classifies record mutations and forwards dirty counters to [SyncStateRepository].
class AutoSyncDirtyTracker {
  AutoSyncDirtyTracker(this._syncState);

  final SyncStateRepository _syncState;

  static const Set<String> _criticalTypes = {
    RecordTypes.visit,
    RecordTypes.lab,
    RecordTypes.medication,
  };

  bool isCriticalRecord(Record record) => _criticalTypes.contains(record.type);

  Future<void> recordRecordSave(Record record) {
    return _syncState.recordChange(critical: isCriticalRecord(record));
  }

  Future<void> recordRecordDelete(Record? record) {
    final critical = record == null ? true : isCriticalRecord(record);
    return _syncState.recordChange(critical: critical);
  }
}
