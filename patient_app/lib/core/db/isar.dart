import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/records/model/record.dart';
import '../../features/records/model/attachment.dart';
import '../../features/records/model/insight.dart';
import '../../features/records/model/sync_state.dart';

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
    ],
        directory: dir.path,
        name: 'patient');
    return _instance!;
  }
}
