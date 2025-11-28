import '../../../../core/domain/entities/information_item.dart';

/// Domain representation of a patient record.
/// 
/// Refactored to use the Adapter Pattern, wrapping the universal [InformationItem].
/// This ensures backward compatibility while migrating to the universal system.
class RecordEntity {
  /// The underlying universal item
  final InformationItem _item;

  RecordEntity._(this._item);

  /// Creates a RecordEntity from an existing InformationItem
  factory RecordEntity.fromItem(InformationItem item) {
    return RecordEntity._(item);
  }

  /// Creates a new RecordEntity (and underlying InformationItem)
  factory RecordEntity({
    int? id,
    String? spaceId,
    required String type,
    required DateTime date,
    required String title,
    String? text,
    List<String>? tags,
    int viewCount = 0,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) {
    final validatedSpaceId = _validateSpaceId(spaceId);
    final validatedType = _validateType(type);
    final validatedTitle = _validateTitle(title);
    final validatedUpdatedAt = _validateUpdatedAt(createdAt, updatedAt);
    final validatedDeletedAt = _validateDeletedAt(validatedUpdatedAt, deletedAt);
    
    final data = {
      'type': validatedType,
      'date': date.toIso8601String(),
      'title': validatedTitle,
      'text': text,
      'tags': tags ?? [],
      'viewCount': viewCount,
    };

    final item = InformationItem(
      id: id,
      spaceId: validatedSpaceId,
      domainId: 'health', // Default domain for legacy records
      data: data,
      createdAt: createdAt,
      updatedAt: validatedUpdatedAt,
      deletedAt: validatedDeletedAt,
    );

    return RecordEntity._(item);
  }

  /// Access to the underlying item
  InformationItem get toItem => _item;

  // Forwarding properties to _item
  int? get id => _item.id;
  String get spaceId => _item.spaceId;
  DateTime get createdAt => _item.createdAt;
  DateTime get updatedAt => _item.updatedAt;
  DateTime? get deletedAt => _item.deletedAt;

  // Domain-specific properties mapped from _item.data
  String get type => _item.data['type'] as String;
  DateTime get date => DateTime.parse(_item.data['date'] as String);
  String get title => _item.data['title'] as String;
  String? get text => _item.data['text'] as String?;
  List<String> get tags => List<String>.unmodifiable(_item.data['tags'] as List? ?? []);
  int get viewCount => (_item.data['viewCount'] as num?)?.toInt() ?? 0;

  /// Convenience helper to clone the entity with updated fields.
  RecordEntity copyWith({
    int? id,
    String? spaceId,
    String? type,
    DateTime? date,
    String? title,
    String? text,
    List<String>? tags,
    int? viewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    // We create a new RecordEntity which constructs a new InformationItem
    return RecordEntity(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      type: type ?? this.type,
      date: date ?? this.date,
      title: title ?? this.title,
      text: text ?? this.text,
      tags: tags ?? this.tags,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  static String _validateSpaceId(String? value) {
    // Default to 'health' for backward compatibility
    if (value == null || value.trim().isEmpty) {
      return 'health';
    }
    return value.trim();
  }

  static String _validateType(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'type', 'Record type cannot be empty.');
    }
    return trimmed;
  }

  static String _validateTitle(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'title', 'Record title cannot be empty.');
    }
    return trimmed;
  }

  static DateTime _validateUpdatedAt(DateTime createdAt, DateTime updatedAt) {
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError.value(
        updatedAt,
        'updatedAt',
        'updatedAt cannot be before createdAt.',
      );
    }
    return updatedAt;
  }

  static DateTime? _validateDeletedAt(DateTime updatedAt, DateTime? deletedAt) {
    if (deletedAt != null && deletedAt.isBefore(updatedAt)) {
      throw ArgumentError.value(
        deletedAt,
        'deletedAt',
        'deletedAt cannot be before updatedAt.',
      );
    }
    return deletedAt;
  }
}
