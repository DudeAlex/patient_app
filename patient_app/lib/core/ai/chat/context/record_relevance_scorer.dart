import 'dart:math';

import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

/// Scores records by recency and access frequency.
class RecordRelevanceScorer {
  double calculateScore(RecordEntity record, {DateTime? now, int? accessCount}) {
    now ??= DateTime.now();
    final daysOld = now.difference(record.date).inDays;
    final recencyScore = max(0, 10 - (daysOld / 30) * 10);
    final frequency = accessCount ?? record.viewCount;
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

    // Calculate score statistics
    if (scored.isNotEmpty) {
      final scores = scored.map((e) => e.value).toList();
      final topScore = scores.first;
      final bottomScore = scores.last;
      final avgScore = scores.reduce((a, b) => a + b) / scores.length;
      final medianScore = scores.length.isOdd
          ? scores[scores.length ~/ 2]
          : (scores[scores.length ~/ 2 - 1] + scores[scores.length ~/ 2]) / 2;

      // Log top 5 scores for debugging
      final top5Scores = scored.take(5).map((e) => {
        'recordId': e.key.id,
        'title': e.key.title,
        'score': e.value.toStringAsFixed(2),
        'date': e.key.date.toIso8601String(),
      }).toList();

      await AppLogger.info(
        'Scored records by relevance',
        context: {
          'inputCount': records.length,
          'topScore': topScore.toStringAsFixed(2),
          'bottomScore': bottomScore.toStringAsFixed(2),
          'avgScore': avgScore.toStringAsFixed(2),
          'medianScore': medianScore.toStringAsFixed(2),
          'top5Scores': top5Scores,
        },
      );
    } else {
      await AppLogger.info(
        'Scored records by relevance',
        context: {
          'inputCount': records.length,
          'topScore': 0,
          'bottomScore': 0,
        },
      );
    }

    return scored.map((e) => e.key).toList();
  }
}
