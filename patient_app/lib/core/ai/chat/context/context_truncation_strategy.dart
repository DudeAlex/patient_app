import 'dart:async';

import 'package:patient_app/core/ai/chat/context/record_summary_formatter.dart';
import 'package:patient_app/core/ai/chat/models/record_summary.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

/// Truncates sorted records to fit within a token budget and record limit.
class ContextTruncationStrategy {
  const ContextTruncationStrategy();

  List<RecordSummary> truncateToFit(
    List<RecordEntity> sortedRecords, {
    required int availableTokens,
    required RecordSummaryFormatter formatter,
    required int maxRecords,
  }) {
    final allowedRecords = maxRecords > 20 ? 20 : maxRecords;
    final kept = <_SummarizedRecord>[];
    var tokensUsed = 0;
    var droppedForBudget = 0;

    for (final record in sortedRecords) {
      if (kept.length >= allowedRecords) {
        break;
      }

      final summary = formatter.format(record);
      final tokens = formatter.estimateTokens(summary);
      if (tokens > availableTokens) {
        unawaited(
          AppLogger.debug(
            'Skipping record summary exceeding budget',
            context: {'recordId': record.id, 'tokens': tokens, 'budget': availableTokens},
          ),
        );
        continue;
      }

      if (tokensUsed + tokens <= availableTokens) {
        kept.add(_SummarizedRecord(summary, tokens));
        tokensUsed += tokens;
        continue;
      }

      while (kept.isNotEmpty && tokensUsed + tokens > availableTokens) {
        final removed = kept.removeLast();
        tokensUsed -= removed.tokens;
        droppedForBudget++;
        unawaited(
          AppLogger.debug(
            'Dropped lowest-scoring record to fit budget',
            context: {
              'droppedTokens': removed.tokens,
              'tokensUsed': tokensUsed,
              'budget': availableTokens,
            },
          ),
        );
      }

      if (tokensUsed + tokens > availableTokens) {
        unawaited(
          AppLogger.debug(
            'Stopping truncation; budget exhausted',
            context: {'tokensUsed': tokensUsed, 'budget': availableTokens},
          ),
        );
        break;
      }

      kept.add(_SummarizedRecord(summary, tokens));
      tokensUsed += tokens;
    }

    unawaited(
      AppLogger.info(
        'Context truncation complete',
        context: {
          'recordsConsidered': sortedRecords.length,
          'recordsIncluded': kept.length,
          'droppedForBudget': droppedForBudget,
          'availableTokens': availableTokens,
          'tokensUsed': tokensUsed,
          'maxRecords': allowedRecords,
        },
      ),
    );

    return kept.map((entry) => entry.summary).toList(growable: false);
  }
}

class _SummarizedRecord {
  _SummarizedRecord(this.summary, this.tokens);

  final RecordSummary summary;
  final int tokens;
}
