import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/records/adapters/storage/record_isar_model.dart';
import '../../features/records/model/attachment.dart';
import '../../features/records/model/insight.dart';
import '../../features/records/model/sync_state.dart';
import '../../features/authentication/infrastructure/models/user_isar_model.dart';
import '../../features/authentication/infrastructure/models/session_isar_model.dart';
import '../../features/authentication/infrastructure/models/login_attempt_isar_model.dart';
import '../../features/authentication/infrastructure/models/mfa_pending_isar_model.dart';
import '../infrastructure/storage/information_item_isar_model.dart';

class IsarDatabase {
  static Isar? _instance;

  // Note: At-rest encryption is not enabled at this time. The
  // `encryptionKey` parameter is intentionally unused to keep the
  // call-sites stable while we finalize the decision (see SPEC.md).
  static Future<Isar> open({required List<int> encryptionKey}) async {
    // Reuse the instance if already open.
    if (_instance != null && _instance!.isOpen) return _instance!;
    final dir = await getApplicationDocumentsDirectory();
    _instance = await Isar.open([
      RecordSchema,
      AttachmentSchema,
      InsightSchema,
      SyncStateSchema,
      // Authentication schemas
      UserIsarModelSchema,
      SessionIsarModelSchema,
      LoginAttemptIsarModelSchema,
      MfaPendingIsarModelSchema,
      // Universal schema
      InformationItemSchema,
    ],
        directory: dir.path,
        name: 'patient');
    return _instance!;
  }
}
