import 'package:collection/collection.dart';

/// Supported automatic backup cadences. Each option maps to a persisted id so
/// patients can pick their preferred schedule from Settings.
enum AutoSyncCadence {
  sixHours('6h', Duration(hours: 6)),
  twelveHours('12h', Duration(hours: 12)),
  daily('daily', Duration(days: 1)),
  weekly('weekly', Duration(days: 7)),
  manual('manual', null);

  const AutoSyncCadence(this.id, this.interval);

  final String id;
  final Duration? interval;

  bool get isManual => this == AutoSyncCadence.manual;

  static AutoSyncCadence fromId(String? id) {
    if (id == null || id.isEmpty) {
      return AutoSyncCadence.weekly;
    }
    return AutoSyncCadence.values
            .firstWhereOrNull((value) => value.id == id) ??
        AutoSyncCadence.weekly;
  }
}
