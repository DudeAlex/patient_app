import 'dart:math';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:patient_app/core/ai/ai_service.dart';
import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';
import 'package:patient_app/core/ai/fake_ai_service.dart';
import 'package:patient_app/core/ai/http/http_ai_service.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/ai/repositories/ai_consent_repository.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';
import 'package:patient_app/features/information_items/application/use_cases/summarize_information_item_use_case.dart';

class _StubConsentRepo implements AiConsentRepository {
  bool consent;
  _StubConsentRepo(this.consent);
  @override
  Future<bool> hasConsent() async => consent;
  @override
  Future<void> grantConsent() async => consent = true;
  @override
  Future<void> revokeConsent() async => consent = false;
}


void main() {
  group('Property tests - FakeAiService', () {
    final now = DateTime.now();
    InformationItem buildItem(String notes) => InformationItem(
          spaceId: 'space',
          domainId: 'domain',
          data: {'title': 'Title', 'notes': notes, 'tags': ['tag']},
          createdAt: now,
          updatedAt: now,
        );

    test('summary stays reasonably short (<350 words)', () async {
      final service = FakeAiService(latency: Duration.zero);
      final rand = Random(42);
      for (var i = 0; i < 20; i++) {
        final notes = _randomText(rand, 200);
        final result = await service.summarizeItem(buildItem(notes));
        final wordCount = result.summaryText.trim().split(RegExp(r'\s+')).length;
        expect(wordCount <= 350, isTrue);
      }
    });

    test('action hints <=3 and each <=12 words', () async {
      final service = FakeAiService(latency: Duration.zero);
      final rand = Random(99);
      for (var i = 0; i < 10; i++) {
        final result = await service.summarizeItem(buildItem(_randomText(rand, 50)));
        expect(result.actionHints.length <= 3, isTrue);
        for (final hint in result.actionHints) {
          final words = hint.trim().split(RegExp(r'\s+')).length;
          expect(words <= 12, isTrue);
        }
      }
    });
  });

  test('Use case enforces consent (property)', () async {
    final now = DateTime.now();
    final item = InformationItem(spaceId: 'space', domainId: 'domain', data: {}, createdAt: now, updatedAt: now);
    final ai = _ImmediateAiService();
    final rand = Random(7);
    for (var i = 0; i < 20; i++) {
      final consent = rand.nextBool();
      final repo = _StubConsentRepo(consent);
      final useCase = SummarizeInformationItemUseCase(aiService: ai, consentRepository: repo);
      if (consent) {
        final result = await useCase.execute(item);
        expect(result.summaryText, 'ok');
      } else {
        expect(() => useCase.execute(item), throwsA(isA<AiConsentRequiredException>()));
      }
    }
  });

  test('HttpAiService retries up to maxRetries', () async {
    var callCount = 0;
    final client = MockClient((request) async {
      callCount++;
      return http.Response('error', 500);
    });
    final service = HttpAiService(
      client: client,
      baseUrl: 'https://example.com',
      maxRetries: 3,
      timeout: const Duration(milliseconds: 10),
    );
    final now = DateTime.now();
    final item = InformationItem(spaceId: 'space', domainId: 'domain', data: {}, createdAt: now, updatedAt: now);
    await expectLater(
      service.summarizeItem(item),
      throwsA(isA<AiProviderUnavailableException>()),
    );
    expect(callCount, 3);
  });
}

class _ImmediateAiService implements AiService {
  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) async {
    return AiSummaryResult.success(summaryText: 'ok');
  }
}

String _randomText(Random rand, int words) {
  return List.generate(words, (_) => 'word${rand.nextInt(1000)}').join(' ');
}
