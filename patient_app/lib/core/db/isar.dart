import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/records/model/record.dart';
import '../../features/records/model/attachment.dart';
import '../../features/records/model/insight.dart';
import '../../features/records/model/sync_state.dart';

class IsarDatabase {
  static Isar? _instance;

  static Future<Isar> open({required Uint8List encryptionKey}) async {
    if (_instance != null && !_instance!.isClosed) return _instance!;
    final dir = await getApplicationDocumentsDirectory();
    _instance = await Isar.open(
      schemas: [
        RecordSchema,
        AttachmentSchema,
        InsightSchema,
        SyncStateSchema,
      ],
      directory: dir.path,
      name: 'patient',
      encryptionKey: encryptionKey,
    );
    return _instance!;
  }
}
