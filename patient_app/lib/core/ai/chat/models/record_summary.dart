import 'package:flutter/foundation.dart';

/// Compact summary of a record for AI context.
@immutable
class RecordSummary {
  static const int maxSummaryLength = 100;

  RecordSummary({
    required this.title,
    required this.type,
    required this.date,
    this.tags = const [],
    this.summary,
  })  : assert(title.trim().isNotEmpty, 'title cannot be empty'),
        assert(type.trim().isNotEmpty, 'type cannot be empty'),
        assert(
          summary == null || summary.length <= maxSummaryLength,
          'summary cannot exceed $maxSummaryLength characters',
        );

  final String title;
  final String type;
  final DateTime date;
  final List<String> tags;
  final String? summary;

  Map<String, dynamic> toJson() => {
        'title': title,
        'type': type,
        'date': date.toIso8601String(),
        'tags': tags,
        'summary': summary,
      };
}
