import 'package:flutter/foundation.dart';
import 'package:patient_app/core/ai/chat/models/date_range.dart';

/// Filters applied when assembling chat context.
@immutable
class ContextFilters {
  const ContextFilters({
    required this.dateRange,
    required this.spaceId,
    this.maxRecords = 20,
  }) : assert(maxRecords > 0, 'maxRecords must be > 0');

  final DateRange dateRange;
  final int maxRecords;
  final String spaceId;

  Map<String, dynamic> toJson() => {
        'dateRange': dateRange.toJson(),
        'maxRecords': maxRecords,
        'spaceId': spaceId,
      };
}
