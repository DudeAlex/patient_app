import 'dart:math';

import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

/// Scores records by recency and access frequency.
class RecordRelevanceScorer {
  double calculateScore(RecordEntity record, {DateTime? now, int? accessCount}) {
    now ??= DateTime.now();
    final daysOld = now.difference(record.date).inDays;
    final recencyScore = max(0, 10 - (daysOld / 30) * 10);
    final frequency = accessCount ?? 0;
    final frequencyScore = min(10.0, frequency.toDouble());
    return (recencyScore * 0.7) + (frequencyScore * 0.3);
  }

  Future<List<RecordEntity>> sortByRelevance(
    List<RecordEntity> records, {
    DateTime? now,
    Map<int, int>? accessCounts,
  }) async {
    final scored = records
        .map(
          (r) => MapEntry(
            r,
            calculateScore(
              r,
              now: now,
              accessCount: accessCounts?[r.id ?? -1],
            ),
          ),
        )
        .toList();
    scored.sort((a, b) => b.value.compareTo(a.value));

    await AppLogger.info(
      'Scored records by relevance',
      context: {
        'inputCount': records.length,
        'topScore': scored.isNotEmpty ? scored.first.value : 0,
        'bottomScore': scored.isNotEmpty ? scored.last.value : 0,
      },
    );

    return scored.map((e) => e.key).toList();
  }
}
