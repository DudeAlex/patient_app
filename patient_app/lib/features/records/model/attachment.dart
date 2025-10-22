import 'package:isar/isar.dart';

part 'attachment.g.dart';

@collection
class Attachment {
  Id id = Isar.autoIncrement;
  late int recordId;
  late String path; // file path within app documents
  late String kind; // image/pdf
  String? ocrText;
  late DateTime createdAt;

  @Index()
  int get recordIndex => recordId;
}

