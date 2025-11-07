import 'package:meta/meta.dart';

/// Immutable view of the persisted sync state used by auto sync flows.
///
/// This keeps higher level coordinators decoupled from the underlying Isar
/// collection so we can evolve storage without touching every consumer.
@immutable
class AutoSyncStatus {
  AutoSyncStatus({
    required this.autoSyncEnabled,
    required this.pendingCriticalChanges,
    required this.pendingRoutineChanges,
    required this.localChangeCounter,
    required this.deviceId,
    this.lastSyncedAt,
    this.lastRemoteModified,
  })  : assert(pendingCriticalChanges >= 0,
            'pendingCriticalChanges cannot be negative.'),
        assert(pendingRoutineChanges >= 0,
            'pendingRoutineChanges cannot be negative.'),
        assert(localChangeCounter >= 0,
            'localChangeCounter cannot be negative.'),
        assert(
          localChangeCounter >=
              pendingCriticalChanges + pendingRoutineChanges,
          'localChangeCounter cannot be less than the sum of pending changes.',
        ),
        assert(deviceId.isNotEmpty, 'deviceId cannot be empty.');

  /// Flag persisted from Settings that allows patients to disable auto sync.
  final bool autoSyncEnabled;

  /// Count of changes that should trigger an immediate backup (records marked
  /// as critical, attachments, etc.).
  final int pendingCriticalChanges;

  /// Routine changes that can be batched until the next critical event or
  /// manual sync.
  final int pendingRoutineChanges;

  /// Total change counter to detect local mutation even if classification
  /// thresholds shift in future milestones.
  final int localChangeCounter;

  /// Stable device identifier used to annotate Drive backups.
  final String deviceId;

  final DateTime? lastSyncedAt;
  final DateTime? lastRemoteModified;

  bool get hasPendingCriticalChanges => pendingCriticalChanges > 0;
  bool get hasPendingRoutineChanges => pendingRoutineChanges > 0;
  bool get hasPendingChanges =>
      hasPendingCriticalChanges || hasPendingRoutineChanges;

  AutoSyncStatus copyWith({
    bool? autoSyncEnabled,
    int? pendingCriticalChanges,
    int? pendingRoutineChanges,
    int? localChangeCounter,
    String? deviceId,
    DateTime? lastSyncedAt,
    DateTime? lastRemoteModified,
  }) {
    return AutoSyncStatus(
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      pendingCriticalChanges:
          pendingCriticalChanges ?? this.pendingCriticalChanges,
      pendingRoutineChanges:
          pendingRoutineChanges ?? this.pendingRoutineChanges,
      localChangeCounter: localChangeCounter ?? this.localChangeCounter,
      deviceId: deviceId ?? this.deviceId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastRemoteModified: lastRemoteModified ?? this.lastRemoteModified,
    );
  }
}
