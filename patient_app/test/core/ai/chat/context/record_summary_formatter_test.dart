import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/context/record_summary_formatter.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

void main() {
  final formatter = RecordSummaryFormatter(maxNoteLength: 100);

  RecordEntity _record({String? text}) {
    return RecordEntity(
      id: 1,
      spaceId: 'health',
      type: 'visit',
      date: DateTime(2025, 1, 1),
      title: 'Annual Checkup',
      text: text,
      tags: const ['tag1', 'tag2'],
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );
  }

  test('truncates notes to max length with ellipsis inside budget', () {
    final longNote = 'a' * 120;
    final summary = formatter.format(_record(text: longNote));
    expect(summary.summary, isNotNull);
    expect(summary.summary!.length, lessThanOrEqualTo(100));
    expect(summary.summary!.endsWith('...'), isTrue);
  });

  test('returns null summary when note is null', () {
    final summary = formatter.format(_record(text: null));
    expect(summary.summary, isNull);
  });

  test('estimates tokens using heuristic', () {
    final summary = formatter.format(_record(text: 'note'));
    final tokens = formatter.estimateTokens(summary);
    expect(tokens, equals(6)); // (Title+Type+tags+summary+separators)/4 rounded up
  });
}
