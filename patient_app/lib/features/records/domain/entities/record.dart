/// Domain representation of a patient record.
/// Free of persistence annotations so it can move across layers.
class RecordEntity {
  RecordEntity({
    this.id,
    required String type,
    required this.date,
    required String title,
    this.text,
    List<String>? tags,
    required this.createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  })  : type = _validateType(type),
        title = _validateTitle(title),
        updatedAt = _validateUpdatedAt(createdAt, updatedAt),
        deletedAt = _validateDeletedAt(updatedAt, deletedAt),
        tags = List<String>.unmodifiable(tags ?? const []);

  /// Database identifier (null before the entity is persisted).
  final int? id;
  final String type;
  final DateTime date;
  final String title;
  final String? text;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  /// Convenience helper to clone the entity with updated fields.
  RecordEntity copyWith({
    int? id,
    String? type,
    DateTime? date,
    String? title,
    String? text,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return RecordEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      date: date ?? this.date,
      title: title ?? this.title,
      text: text ?? this.text,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
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
