import 'package:google_drive_backup/google_drive_backup.dart';

/// Result describing the outcome of a backup attempt.
class AutoSyncBackupResult {
  AutoSyncBackupResult._({
    required this.isSuccess,
    this.completedAt,
    this.error,
    this.stackTrace,
  });

  factory AutoSyncBackupResult.success({required DateTime completedAt}) {
    return AutoSyncBackupResult._(isSuccess: true, completedAt: completedAt);
  }

  factory AutoSyncBackupResult.failure({
    required Object error,
    required StackTrace stackTrace,
  }) {
    return AutoSyncBackupResult._(
      isSuccess: false,
      error: error,
      stackTrace: stackTrace,
    );
  }

  final bool isSuccess;
  final DateTime? completedAt;
  final Object? error;
  final StackTrace? stackTrace;
}

/// Contract consumed by auto-sync orchestration whenever a Drive backup is needed.
abstract class AutoSyncBackupClient {
  bool get hasCachedAccount;
  String? get cachedEmail;
  Future<AutoSyncBackupResult> runBackup({bool promptIfNecessary = true});
}

/// Wraps [DriveBackupManager] so manual and background backups reuse the same
/// orchestration logic.
class AutoSyncBackupService implements AutoSyncBackupClient {
  AutoSyncBackupService({
    DriveBackupManager? manager,
    DateTime Function()? clock,
  }) : _manager = manager ?? DriveBackupManager(),
       _clock = clock ?? DateTime.now;

  final DriveBackupManager _manager;
  final DateTime Function() _clock;

  /// Exposes the underlying manager so UI flows (sign-in, restore, diagnostics)
  /// can reuse the same auth instance.
  DriveBackupManager get manager => _manager;

  @override
  bool get hasCachedAccount {
    final email = _manager.auth.cachedEmail;
    return email != null && email.isNotEmpty;
  }

  @override
  String? get cachedEmail => _manager.auth.cachedEmail;

  @override
  Future<AutoSyncBackupResult> runBackup({
    bool promptIfNecessary = true,
  }) async {
    try {
      await _manager.backupToDrive(promptIfNecessary: promptIfNecessary);
      return AutoSyncBackupResult.success(completedAt: _clock());
    } on Exception catch (e, st) {
      return AutoSyncBackupResult.failure(error: e, stackTrace: st);
    }
  }
}
