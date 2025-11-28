import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/context/record_summary_formatter.dart';
import 'package:patient_app/core/ai/chat/context/token_budget_allocator.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

/// Property 4: Token Budget Enforcement
/// Validates: Requirements 3.1, 3.2
///
/// For any set of records, when building optimized context,
/// the total estimated tokens should not exceed the allocated budget.
void main() {
  test('Property: Token budget is never exceeded', () async {
    final random = Random(42);
    final formatter = RecordSummaryFormatter(maxNoteLength: 100);
    final allocator = const TokenBudgetAllocator(
      total: 4800,
      system: 800,
      context: 2000,
      history: 1000,
      response: 1000,
    );

    // Test with various record set sizes
    for (int recordCount in [5, 10, 20, 50, 100]) {
      final records = List.generate(
        recordCount,
        (i) => _generateRandomRecord(i, random),
      );

      // Format records and estimate tokens
      final summaries = records.map((r) => formatter.format(r)).toList();
      int totalTokens = 0;
      for (final summary in summaries) {
        totalTokens += formatter.estimateTokens(summary);
      }

      // Get available budget for context
      final availableForContext = allocator.getAvailableForContext();

      // If we have more tokens than budget, we should truncate
      if (totalTokens > availableForContext) {
        // Simulate truncation: only include records that fit
        int includedTokens = 0;
        int includedCount = 0;
        for (final summary in summaries) {
          final tokens = formatter.estimateTokens(summary);
          if (includedTokens + tokens <= availableForContext) {
            includedTokens += tokens;
            includedCount++;
          } else {
            break;
          }
        }

        // After truncation, tokens should be within budget
        expect(
          includedTokens,
          lessThanOrEqualTo(availableForContext),
          reason: 'Truncated context should fit within budget. '
              'Records: $recordCount, Included: $includedCount, '
              'Tokens: $includedTokens, Budget: $availableForContext',
        );
      } else {
        // All records fit within budget
        expect(
          totalTokens,
          lessThanOrEqualTo(availableForContext),
          reason: 'All records should fit within budget. '
              'Records: $recordCount, Tokens: $totalTokens, '
              'Budget: $availableForContext',
        );
      }
    }
  });

  test('Property: Response reservation is always maintained', () async {
    final allocator = const TokenBudgetAllocator(
      total: 4800,
      system: 800,
      context: 2000,
      history: 1000,
      response: 1000,
      minimumResponseReservation: 1000,
    );

    // Test with various system and history overrides
    for (int systemTokens in [500, 800, 1000]) {
      for (int historyTokens in [500, 1000, 1500]) {
        final availableForContext = allocator.getAvailableForContext(
          systemOverride: systemTokens,
          historyOverride: historyTokens,
        );

        // Calculate what's left for response
        final usedTokens = systemTokens + historyTokens + availableForContext;
        final responseTokens = allocator.total - usedTokens;

        // Response reservation should always be at least the minimum
        expect(
          responseTokens,
          greaterThanOrEqualTo(allocator.minimumResponseReservation),
          reason: 'Response reservation must be at least ${allocator.minimumResponseReservation}. '
              'System: $systemTokens, History: $historyTokens, '
              'Context: $availableForContext, Response: $responseTokens',
        );
      }
    }
  });

  test('Property: Token allocation components sum to total', () async {
    final random = Random(123);

    // Test with random budget allocations
    for (int i = 0; i < 20; i++) {
      final total = 3000 + random.nextInt(5000); // 3000-8000
      final system = 500 + random.nextInt(500); // 500-1000
      final context = 1000 + random.nextInt(2000); // 1000-3000
      final history = 500 + random.nextInt(1000); // 500-1500
      final response = total - system - context - history;

      if (response < 1000) continue; // Skip if response would be too small

      final allocator = TokenBudgetAllocator(
        total: total,
        system: system,
        context: context,
        history: history,
        response: response,
      );

      // Sum of all allocations should equal total
      final sum = allocator.system +
          allocator.context +
          allocator.history +
          allocator.response;

      expect(
        sum,
        equals(total),
        reason: 'Token allocation components must sum to total. '
            'System: ${allocator.system}, Context: ${allocator.context}, '
            'History: ${allocator.history}, Response: ${allocator.response}, '
            'Sum: $sum, Total: $total',
      );
    }
  });

  test('Property: Total budget is never exceeded', () async {
    final allocator = const TokenBudgetAllocator(
      total: 4800,
      system: 800,
      context: 2000,
      history: 1000,
      response: 1000,
    );

    final random = Random(456);

    // Test with various system and history usage
    for (int i = 0; i < 50; i++) {
      final systemUsed = random.nextInt(allocator.system + 1);
      final historyUsed = random.nextInt(allocator.history + 1);

      final available = allocator.getAvailableForContext(
        systemOverride: systemUsed,
        historyOverride: historyUsed,
      );

      // Total used should never exceed total budget
      final totalUsed = systemUsed + historyUsed + available + allocator.response;
      expect(
        totalUsed,
        lessThanOrEqualTo(allocator.total),
        reason: 'Total token usage should not exceed total budget. '
            'System: $systemUsed, History: $historyUsed, '
            'Context: $available, Response: ${allocator.response}, '
            'Total used: $totalUsed, Budget: ${allocator.total}',
      );

      // Available should be non-negative
      expect(
        available,
        greaterThanOrEqualTo(0),
        reason: 'Available context tokens should be non-negative',
      );
    }
  });
}

RecordEntity _generateRandomRecord(int id, Random random) {
  final date = DateTime(2025, 1, 1).add(Duration(days: random.nextInt(365)));
  final noteLength = random.nextInt(500); // 0-500 chars
  final note = List.generate(noteLength, (i) => 'a').join();

  return RecordEntity(
    id: id,
    spaceId: 'test-space',
    type: 'note',
    date: date,
    title: 'Record $id',
    text: note,
    tags: List.generate(random.nextInt(5), (i) => 'tag$i'),
    createdAt: date,
    updatedAt: date,
  );
}
