import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/ai_providers.dart';
import 'package:patient_app/core/ai/ai_service.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/ai/repositories/ai_consent_repository.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';
import 'package:patient_app/features/information_items/ui/widgets/information_item_summary_sheet.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

class _SuccessAiService implements AiService {
  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) async {
    return AiSummaryResult.success(summaryText: 'Mock summary', actionHints: ['Hint one']);
  }
}

class _ErrorAiService implements AiService {
  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) {
    throw Exception('boom');
  }
}

class _ConsentRepo implements AiConsentRepository {
  @override
  Future<bool> hasConsent() async => true;
  @override
  Future<void> grantConsent() async {}
  @override
  Future<void> revokeConsent() async {}
}

RecordEntity _record() {
  final now = DateTime.now();
  return RecordEntity.fromItem(
    InformationItem(
      id: 1,
      spaceId: 'health',
      domainId: 'visit',
      data: {'title': 'Visit', 'type': 'Visit'},
      createdAt: now,
      updatedAt: now,
    ),
  );
}

void main() {
  testWidgets('InformationItemSummarySheet shows summary on success', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiServiceProvider.overrideWithValue(_SuccessAiService()),
          aiConsentRepositoryProvider.overrideWithValue(_ConsentRepo()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: InformationItemSummarySheet(record: _record()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mock summary'), findsOneWidget);
    expect(find.text('Hint one'), findsOneWidget);
  });

  testWidgets('InformationItemSummarySheet shows error state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiServiceProvider.overrideWithValue(_ErrorAiService()),
          aiConsentRepositoryProvider.overrideWithValue(_ConsentRepo()),
        ],
        child: MaterialApp(
          home: InformationItemSummarySheet(record: _record()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Unable to generate'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
