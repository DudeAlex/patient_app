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
    final filtered = records.where((record) {
      if (record.deletedAt != null) return false;
      if (record.spaceId != spaceId) return false;
      if (record.date.isBefore(dateRange.start)) return false;
      if (record.date.isAfter(dateRange.end)) return false;
      return true;
    }).toList();

    await AppLogger.info(
      'Filtered records for context',
      context: {
        'spaceId': spaceId,
        'inputCount': records.length,
        'filteredCount': filtered.length,
        'start': dateRange.start.toIso8601String(),
        'end': dateRange.end.toIso8601String(),
      },
    );

    return filtered;
  }
}
