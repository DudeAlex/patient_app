import 'package:flutter/foundation.dart';

/// Persona-aware context passed to AI chat operations.
@immutable
class SpaceContext {
  SpaceContext({
    required this.spaceId,
    required this.spaceName,
    required this.persona,
    required this.description,
    List<String> categories = const [],
    List<RecordSummary> recentRecords = const [],
    this.maxContextRecords = 10,
  })  : assert(spaceId.trim().isNotEmpty, 'spaceId cannot be empty'),
        assert(spaceName.trim().isNotEmpty, 'spaceName cannot be empty'),
        assert(maxContextRecords > 0, 'maxContextRecords must be > 0'),
        categories = List.unmodifiable(categories),
        recentRecords = List.unmodifiable(recentRecords);

  /// Current space identifier (e.g., health, education).
  final String spaceId;

  /// Display name for the space.
  final String spaceName;

  /// Persona used to shape AI tone and guidance.
  final SpacePersona persona;

  /// Brief description of the space to ground the AI.
  final String description;

  /// Space-specific categories to hint at common topics.
  final List<String> categories;

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
    String? description,
    List<String>? categories,
    List<RecordSummary>? recentRecords,
    int? maxContextRecords,
  }) {
    return SpaceContext(
      spaceId: spaceId ?? this.spaceId,
      spaceName: spaceName ?? this.spaceName,
      persona: persona ?? this.persona,
      description: description ?? this.description,
      categories: categories ?? this.categories,
      recentRecords: recentRecords ?? this.recentRecords,
      maxContextRecords: maxContextRecords ?? this.maxContextRecords,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spaceId': spaceId,
      'spaceName': spaceName,
      'description': description,
      'categories': categories,
      'persona': persona.name,
      'recentRecords': recentRecords.map((r) => r.toJson()).toList(),
      'maxContextRecords': maxContextRecords,
    };
  }
}

/// Space-specific persona influencing AI tone and hints.
enum SpacePersona { health, education, finance, travel, general }

/// Minimal summary of a record used for context grounding.
@immutable
class RecordSummary {
  static const int maxSummaryLength = 100;

  RecordSummary({
    required this.title,
    required this.type,
    List<String> tags = const [],
    this.summary,
    required this.createdAt,
  })  : assert(title.trim().isNotEmpty, 'title cannot be empty'),
        assert(type.trim().isNotEmpty, 'type cannot be empty'),
        assert(
          summary == null || summary.length <= maxSummaryLength,
          'summary cannot exceed $maxSummaryLength characters',
        ),
        tags = List.unmodifiable(tags);

  final String title;
  final String type;
  final List<String> tags;
  final String? summary;
  final DateTime createdAt;

  RecordSummary copyWith({
    String? title,
    String? type,
    List<String>? tags,
    String? summary,
    DateTime? createdAt,
  }) {
    return RecordSummary(
      title: title ?? this.title,
      type: type ?? this.type,
      tags: tags ?? this.tags,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type,
      'tags': tags,
      'summary': summary,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
