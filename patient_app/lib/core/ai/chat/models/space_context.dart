import 'package:flutter/foundation.dart';

/// Persona-aware context passed to AI chat operations.
@immutable
class SpaceContext {
  SpaceContext({
    required this.spaceId,
    required this.spaceName,
    required this.persona,
    List<RecordSummary> recentRecords = const [],
    this.maxContextRecords = 5,
  })  : assert(spaceId.trim().isNotEmpty, 'spaceId cannot be empty'),
        assert(spaceName.trim().isNotEmpty, 'spaceName cannot be empty'),
        assert(maxContextRecords > 0, 'maxContextRecords must be > 0'),
        recentRecords = List.unmodifiable(recentRecords);

  /// Current space identifier (e.g., health, education).
  final String spaceId;

  /// Display name for the space.
  final String spaceName;

  /// Persona used to shape AI tone and guidance.
  final SpacePersona persona;

  /// Recent records used for grounding responses.
  final List<RecordSummary> recentRecords;

  /// Maximum records to include when building payloads.
  final int maxContextRecords;

  /// Returns records trimmed to the configured maximum to limit token use.
  List<RecordSummary> get limitedRecords =>
      recentRecords.take(maxContextRecords).toList(growable: false);

  SpaceContext copyWith({
    String? spaceId,
    String? spaceName,
    SpacePersona? persona,
    List<RecordSummary>? recentRecords,
    int? maxContextRecords,
  }) {
    return SpaceContext(
      spaceId: spaceId ?? this.spaceId,
      spaceName: spaceName ?? this.spaceName,
      persona: persona ?? this.persona,
      recentRecords: recentRecords ?? this.recentRecords,
      maxContextRecords: maxContextRecords ?? this.maxContextRecords,
    );
  }
}

/// Space-specific persona influencing AI tone and hints.
enum SpacePersona { health, education, finance, travel, general }

/// Minimal summary of a record used for context grounding.
@immutable
class RecordSummary {
  const RecordSummary({
    required this.title,
    required this.category,
    List<String> tags = const [],
    this.summaryText,
    required this.createdAt,
  })  : assert(title.trim().isNotEmpty, 'title cannot be empty'),
        assert(category.trim().isNotEmpty, 'category cannot be empty'),
        tags = List.unmodifiable(tags);

  final String title;
  final String category;
  final List<String> tags;
  final String? summaryText;
  final DateTime createdAt;

  RecordSummary copyWith({
    String? title,
    String? category,
    List<String>? tags,
    String? summaryText,
    DateTime? createdAt,
  }) {
    return RecordSummary(
      title: title ?? this.title,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      summaryText: summaryText ?? this.summaryText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'tags': tags,
      'summary': summaryText,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
