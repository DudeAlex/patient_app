import 'package:isar/isar.dart';

part 'attachment.g.dart';

@collection
class Attachment {
  Id id = Isar.autoIncrement;
  late int recordId;
  late String path; // file path within app documents
  late String kind; // image/pdf
  String? mimeType;
  int? sizeBytes;
  int? durationMs; // audio/video duration in milliseconds
  int? pageCount; // for document scans
  DateTime? capturedAt;
  String? source; // e.g., capture mode identifier
  String? metadataJson; // serialized extras for future-proofing
  String? ocrText;
  late DateTime createdAt;

  @Index()
  int get recordIndex => recordId;
}
