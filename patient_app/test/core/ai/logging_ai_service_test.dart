import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/fake_ai_service.dart';
import 'package:patient_app/core/ai/logging_ai_service.dart';
import 'package:patient_app/core/ai/repositories/ai_call_log_repository.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';

void main() {
  final now = DateTime.now();
  InformationItem item() => InformationItem(
        spaceId: 'health',
        domainId: 'medical_visit',
        data: {'title': 'Visit'},
        createdAt: now,
        updatedAt: now,
      );

  test('records successful call in repository', () async {
    final repo = AiCallLogRepository();
    final service = LoggingAiService(FakeAiService(latency: Duration.zero), callLogRepository: repo);
    await service.summarizeItem(item());
    expect(repo.entries.length, 1);
    expect(repo.entries.first.success, isTrue);
  });
}
