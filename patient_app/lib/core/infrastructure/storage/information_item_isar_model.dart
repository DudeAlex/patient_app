import 'package:isar/isar.dart';

part 'information_item_isar_model.g.dart';

/// Universal persistence model stored in Isar.
/// Replaces the domain-specific [Record] model.
@collection
class InformationItem {
  Id id = Isar.autoIncrement;

  /// Space identifier (e.g., 'health', 'finance')
  @Index()
  late String spaceId;

  /// Domain identifier (e.g., 'medical_record', 'expense')
  @Index()
  late String domainId;

  /// Schema version for the data JSON
  late int schemaVersion;

  /// JSON string representation of the item's data
  /// Isar doesn't support Map directly, so we store as JSON string
  late String dataJson;

  @Index()
  late DateTime createdAt;

  late DateTime updatedAt;

  DateTime? deletedAt;

  /// Composite index for efficient querying within a space and domain
  @Index(composite: [CompositeIndex('domainId'), CompositeIndex('createdAt')])
  String get spaceDomainDateIndex => '$spaceId-$domainId-${createdAt.toIso8601String()}';
}
