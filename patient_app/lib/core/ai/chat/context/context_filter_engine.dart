import 'package:patient_app/core/ai/chat/models/date_range.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

/// Filters records by space, deletion status, and date range.
class ContextFilterEngine {
  Future<List<RecordEntity>> filterRecords(
    List<RecordEntity> records, {
    required String spaceId,
    required DateRange dateRange,
  }) async {
    var deletedCount = 0;
    var wrongSpaceCount = 0;
    var beforeDateRangeCount = 0;
    var afterDateRangeCount = 0;

    final filtered = records.where((record) {
      if (record.deletedAt != null) {
        deletedCount++;
        return false;
      }
      if (record.spaceId != spaceId) {
        wrongSpaceCount++;
        return false;
      }
      if (record.date.isBefore(dateRange.start)) {
        beforeDateRangeCount++;
        return false;
      }
      if (record.date.isAfter(dateRange.end)) {
        afterDateRangeCount++;
        return false;
      }
      return true;
    }).toList();

    await AppLogger.info(
      'Filtered records for context',
      context: {
        'spaceId': spaceId,
        'inputCount': records.length,
        'filteredCount': filtered.length,
        'excludedCount': records.length - filtered.length,
        'excludedBreakdown': {
          'deleted': deletedCount,
          'wrongSpace': wrongSpaceCount,
          'beforeDateRange': beforeDateRangeCount,
          'afterDateRange': afterDateRangeCount,
        },
        'dateRangeStart': dateRange.start.toIso8601String(),
        'dateRangeEnd': dateRange.end.toIso8601String(),
        'dateRangeDays': dateRange.end.difference(dateRange.start).inDays,
      },
    );

    return filtered;
  }
}
