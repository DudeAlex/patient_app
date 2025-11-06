import 'package:isar/isar.dart';

part 'record_isar_model.g.dart';

/// Persistence model stored in Isar. Mapped to [RecordEntity] via the adapter
/// layer.
@collection
class Record {
  Record();

  Id id = Isar.autoIncrement;

  @Index()
  late String type; // note, lab, visit, med

  @Index()
  late DateTime date;

  @Index(caseSensitive: false)
  late String title;

  @Index(type: IndexType.value, caseSensitive: false)
  String? text;

  List<String> tags = <String>[];

  late DateTime createdAt;

  late DateTime updatedAt;

  DateTime? deletedAt;

  @Index()
  String get typeDateIndex => '$type-${date.toIso8601String()}';
}
