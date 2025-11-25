import 'dart:math';

import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

/// Formats records into compact summaries for AI context assembly.
class RecordSummaryFormatter {
  RecordSummaryFormatter({this.maxNoteLength = 100});

  /// Maximum characters to keep from record notes.
  final int maxNoteLength;

  /// Builds a [RecordSummary] from a [RecordEntity], truncating notes and
  /// tolerating missing optional fields.
  RecordSummary format(RecordEntity record) {
    return RecordSummary(
      title: record.title,
      category: record.type,
      tags: record.tags,
      summaryText: _truncate(record.text),
      createdAt: record.date,
    );
  }

  /// Rough token estimate using a 4-chars-per-token heuristic.
  int estimateTokens(RecordSummary summary) {
    final parts = <String>[
      summary.title,
      summary.category,
      ...summary.tags,
      summary.summaryText ?? '',
    ];
    final length = parts.fold<int>(0, (total, part) => total + part.length + 1);
    return max(1, (length / 4).ceil());
  }

  String? _truncate(String? text) {
    if (text == null) return null;
    if (text.length <= maxNoteLength) return text;
    return '${text.substring(0, maxNoteLength)}...';
  }
}
