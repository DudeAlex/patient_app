import 'package:isar/isar.dart';

part 'record.g.dart';

@collection
class Record {
  Id id = Isar.autoIncrement;
  @Index()
  late String type; // note, lab, visit, med
  @Index()
  late DateTime date;
  @Index(caseSensitive: false)
  late String title;
  @Index(type: IndexType.value, caseSensitive: false)
  String? text;
  List<String> tags = [];
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;

  @Index()
  String get typeDateIndex => '$type-${date.toIso8601String()}';
}
