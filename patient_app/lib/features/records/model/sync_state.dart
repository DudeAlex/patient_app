import 'package:isar/isar.dart';

part 'sync_state.g.dart';

@collection
class SyncState {
  Id id = 1; // singleton
  DateTime? lastSyncedAt;
  DateTime? lastRemoteModified;
  int localChangeCounter = 0;
  late String deviceId;
}

