import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';

void main() {
  group('AiSummaryResult', () {
    test('clamps confidence between 0 and 1', () {
      final low = AiSummaryResult(summaryText: '', tokensUsed: 0, latencyMs: 0, provider: 'fake', confidence: -5);
      final high = AiSummaryResult(summaryText: '', tokensUsed: 0, latencyMs: 0, provider: 'fake', confidence: 5);
      expect(low.confidence, 0);
      expect(high.confidence, 1);
    });

    test('unmodifiable action hints', () {
      final result = AiSummaryResult(summaryText: '', actionHints: ['a'], tokensUsed: 0, latencyMs: 0, provider: 'fake');
      expect(() => result.actionHints.add('b'), throwsUnsupportedError);
    });
  });
}
