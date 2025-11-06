/// Domain representation of a patient record.
/// Free of persistence annotations so it can move across layers.
class RecordEntity {
  RecordEntity({
    this.id,
    required this.type,
    required this.date,
    required this.title,
    this.text,
    List<String>? tags,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  }) : tags = List<String>.unmodifiable(tags ?? const []);

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
}
