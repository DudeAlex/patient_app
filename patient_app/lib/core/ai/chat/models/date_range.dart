import 'package:flutter/foundation.dart';

/// Date range used to scope context assembly.
@immutable
class DateRange {
  DateRange({required this.start, required this.end})
      : assert(!end.isBefore(start), 'end must be on/after start');

  final DateTime start;
  final DateTime end;

  /// Creates a date range for the last N days (1-1095, approximately 3 years).
  /// 
  /// This is the primary factory method for creating date ranges.
  /// The [days] parameter must be between 1 and 1095 (inclusive).
  /// 
  /// Example:
  /// ```dart
  /// final range = DateRange.lastNDays(45); // Last 45 days
  /// ```
  factory DateRange.lastNDays(int days) {
    assert(days >= 1 && days <= 1095, 'days must be between 1 and 1095');
    final now = DateTime.now();
    return DateRange(
      start: now.subtract(Duration(days: days)),
      end: now,
    );
  }

  /// Convenience factory for last 7 days.
  /// Delegates to [lastNDays] for consistency.
  factory DateRange.last7Days() => DateRange.lastNDays(7);

  /// Convenience factory for last 14 days.
  /// Delegates to [lastNDays] for consistency.
  factory DateRange.last14Days() => DateRange.lastNDays(14);

  /// Convenience factory for last 30 days.
  /// Delegates to [lastNDays] for consistency.
  factory DateRange.last30Days() => DateRange.lastNDays(30);

  Map<String, dynamic> toJson() => {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      };
}
