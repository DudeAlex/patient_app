import 'package:isar/isar.dart';

part 'record_isar_model.g.dart';

/// Persistence model stored in Isar. Mapped to [RecordEntity] via the adapter
/// layer.
@collection
class Record {
  Record();

  Id id = Isar.autoIncrement;

  /// Space identifier - associates record with a specific life area/domain
  /// Defaults to 'health' for backward compatibility with existing records
  @Index()
  late String spaceId;

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

  /// Composite index for efficient space-based queries
  /// Enables fast filtering by space, then category (type), then date
  @Index(composite: [CompositeIndex('type'), CompositeIndex('date')])
  String get spaceTypeDateIndex => '$spaceId-$type-${date.toIso8601String()}';

  /// Legacy index maintained for backward compatibility
  @Index()
  String get typeDateIndex => '$type-${date.toIso8601String()}';
}
