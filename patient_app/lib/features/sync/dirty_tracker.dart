import '../records/domain/entities/record.dart';
import '../records/model/record_types.dart';

import 'application/use_cases/record_auto_sync_change_use_case.dart';

/// Classifies record mutations and forwards dirty counters to [SyncStateRepository].
class AutoSyncDirtyTracker {
  AutoSyncDirtyTracker(this._recordChangeUseCase);

  final RecordAutoSyncChangeUseCase _recordChangeUseCase;

  static const Set<String> _criticalTypes = {
    RecordTypes.visit,
    RecordTypes.lab,
    RecordTypes.medication,
  };

  bool isCriticalRecord(RecordEntity record) => _criticalTypes.contains(record.type);

  Future<void> recordRecordSave(RecordEntity record) {
    return _recordChangeUseCase.execute(
      RecordAutoSyncChangeInput(critical: isCriticalRecord(record)),
    );
  }

  Future<void> recordRecordDelete(RecordEntity? record) {
    final critical = record == null ? true : isCriticalRecord(record);
    return _recordChangeUseCase.execute(
      RecordAutoSyncChangeInput(critical: critical),
    );
  }
}
