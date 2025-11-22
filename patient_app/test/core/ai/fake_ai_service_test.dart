import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/fake_ai_service.dart';
import 'package:patient_app/core/ai/models/ai_error.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';

void main() {
  final now = DateTime.now();
  InformationItem buildItem(Map<String, dynamic> data) {
    return InformationItem(
      id: 1,
      spaceId: 'health',
      domainId: 'medical_visit',
      data: data,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('returns deterministic summary', () async {
    final service = FakeAiService(latency: Duration.zero);
    final result = await service.summarizeItem(buildItem({
      'title': 'Cardiology follow-up',
      'notes': 'Doctor asked for BP diary.',
      'tags': ['cardiology']
    }));
    expect(result.summaryText.contains('Cardiology follow-up'), isTrue);
    expect(result.actionHints, isNotEmpty);
  });

  test('simulates failure when configured', () async {
    final service = FakeAiService(latency: Duration.zero)..configureFailure(enabled: true, error: const AiError(message: 'fail', isRetryable: true));
    expect(
      () => service.summarizeItem(buildItem({'title': 't'})),
      throwsA(isA<Exception>()),
    );
  });
}
