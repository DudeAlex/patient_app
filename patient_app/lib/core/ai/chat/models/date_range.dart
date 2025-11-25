import 'package:flutter/foundation.dart';

/// Date range used to scope context assembly.
@immutable
class DateRange {
  const DateRange({required this.start, required this.end})
      : assert(!end.isBefore(start), 'end must be on/after start');

  final DateTime start;
  final DateTime end;

  factory DateRange.last7Days() {
    final now = DateTime.now();
    return DateRange(
      start: now.subtract(const Duration(days: 7)),
      end: now,
    );
  }

  factory DateRange.last14Days() {
    final now = DateTime.now();
    return DateRange(
      start: now.subtract(const Duration(days: 14)),
      end: now,
    );
  }

  factory DateRange.last30Days() {
    final now = DateTime.now();
    return DateRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
  }

  Map<String, dynamic> toJson() => {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      };
}
