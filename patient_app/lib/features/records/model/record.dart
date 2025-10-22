import 'package:isar/isar.dart';

part 'record.g.dart';

@collection
class Record {
  Id id = Isar.autoIncrement;
  late String type; // note, lab, visit, med
  late DateTime date;
  late String title;
  String? text;
  List<String> tags = [];
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;

  @Index()
  String get typeDateIndex => '$type-${date.toIso8601String()}';
}

