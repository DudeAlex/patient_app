// Standalone RecordEntity for command-line tool, without Flutter dependencies
class RecordEntity {
  final int? id;
  final String spaceId;
  final String type;
  final DateTime date;
  final String title;
  final String? text;
  final List<String> tags;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;
 final DateTime? deletedAt;

  RecordEntity({
    this.id,
    required this.spaceId,
    required this.type,
    required this.date,
    required this.title,
    this.text,
    List<String>? tags,
    this.viewCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  }) : tags = tags?.toList() ?? <String>[];

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecordEntity &&
        other.id == id &&
        other.spaceId == spaceId &&
        other.type == type &&
        other.date == date &&
        other.title == title &&
        other.text == text &&
        _listEquals(other.tags, tags) &&
        other.viewCount == viewCount &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.deletedAt == deletedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      spaceId,
      type,
      date,
      title,
      text,
      _listHash(tags),
      viewCount,
      createdAt,
      updatedAt,
      deletedAt,
    );
  }

  @override
  String toString() {
    return 'RecordEntity(id: $id, spaceId: $spaceId, type: $type, date: $date, title: $title)';
  }

  // Helper methods for equality checks
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  int _listHash<T>(List<T> list) {
    return list.fold(0, (hash, element) => hash * 31 + element.hashCode);
  }
}