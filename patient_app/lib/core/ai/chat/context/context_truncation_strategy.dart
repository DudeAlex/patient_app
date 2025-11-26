import 'package:patient_app/core/ai/chat/context/record_summary_formatter.dart';
import 'package:patient_app/core/ai/chat/models/record_summary.dart';
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
    final summaries = <RecordSummary>[];
    var tokensUsed = 0;
    for (final record in sortedRecords) {
      if (summaries.length >= maxRecords) break;
      final summary = formatter.format(record);
      final tokens = formatter.estimateTokens(summary);
      if (tokensUsed + tokens > availableTokens) {
        continue;
      }
      tokensUsed += tokens;
      summaries.add(summary);
    }
    return summaries;
  }
}
