import 'package:flutter/foundation.dart';
import 'package:patient_app/core/ai/chat/models/record_summary.dart';

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
    this.filters,
    this.tokenAllocation,
    this.stats,
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

  /// Filters used during assembly (Stage 4).
  final Object? filters;

  /// Token allocation used during assembly (Stage 4).
  final Object? tokenAllocation;

  /// Stats captured during assembly (Stage 4).
  final Object? stats;

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
    Object? filters,
    Object? tokenAllocation,
    Object? stats,
  }) {
    return SpaceContext(
      spaceId: spaceId ?? this.spaceId,
      spaceName: spaceName ?? this.spaceName,
      persona: persona ?? this.persona,
      description: description ?? this.description,
      categories: categories ?? this.categories,
      recentRecords: recentRecords ?? this.recentRecords,
      maxContextRecords: maxContextRecords ?? this.maxContextRecords,
      filters: filters ?? this.filters,
      tokenAllocation: tokenAllocation ?? this.tokenAllocation,
      stats: stats ?? this.stats,
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
      if (filters != null) 'filters': filters,
      if (tokenAllocation != null) 'tokenAllocation': tokenAllocation,
      if (stats != null) 'stats': stats,
    };
  }
}

/// Space-specific persona influencing AI tone and hints.
enum SpacePersona { health, education, finance, travel, general }
