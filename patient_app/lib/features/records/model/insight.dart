import 'package:isar/isar.dart';

part 'insight.g.dart';

@collection
class Insight {
  Id id = Isar.autoIncrement;
  int? recordId;
  late String kind; // summary/trend
  late String text;
  late DateTime createdAt;
}

