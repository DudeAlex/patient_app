import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/ai_service.dart';
import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/ai/repositories/ai_consent_repository.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';
import 'package:patient_app/features/information_items/application/use_cases/summarize_information_item_use_case.dart';

class _FakeAiService implements AiService {
  bool called = false;
  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) async {
    called = true;
    return AiSummaryResult.success(summaryText: 'ok');
  }
}

class _FakeConsentRepo implements AiConsentRepository {
  bool consent = false;
  @override
  Future<bool> hasConsent() async => consent;
  @override
  Future<void> grantConsent() async {
    consent = true;
  }
  @override
  Future<void> revokeConsent() async {
    consent = false;
  }
}

void main() {
  final now = DateTime.now();
  final item = InformationItem(spaceId: 'space', domainId: 'domain', data: {}, createdAt: now, updatedAt: now);

  test('throws when consent missing', () async {
    final ai = _FakeAiService();
    final consent = _FakeConsentRepo()..consent = false;
    final useCase = SummarizeInformationItemUseCase(aiService: ai, consentRepository: consent);
    expect(() => useCase.execute(item), throwsA(isA<AiConsentRequiredException>()));
    expect(ai.called, isFalse);
  });

  test('calls ai service when consent granted', () async {
    final ai = _FakeAiService();
    final consent = _FakeConsentRepo()..consent = true;
    final useCase = SummarizeInformationItemUseCase(aiService: ai, consentRepository: consent);
    final result = await useCase.execute(item);
    expect(result.summaryText, 'ok');
    expect(ai.called, isTrue);
  });
}
