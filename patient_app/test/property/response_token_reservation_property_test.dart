import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/context/token_budget_allocator.dart';

/// Property 8: Response Token Reservation
/// Validates: Requirements 7.2
///
/// For any token allocation, the system must always reserve at least 1000 tokens
/// for the response, ensuring the LLM has sufficient budget to generate a complete answer.
void main() {
  test('Property: Response tokens are always >= 1000', () async {
    // Test with various total budgets
    for (int totalBudget in [3000, 4800, 6000, 8000]) {
      // Test with various system allocations
      for (int systemTokens in [500, 800, 1000]) {
        // Test with various history allocations
        for (int historyTokens in [500, 1000, 1500]) {
          // Skip if system + history + minimum response already exceeds total
          if (systemTokens + historyTokens + 1000 >= totalBudget) continue;

          // Test with various context requests
          for (int contextTokens in [500, 1000, 2000]) {
            final allocator = TokenBudgetAllocator(
              total: totalBudget,
              system: systemTokens,
              context: contextTokens,
              history: historyTokens,
              response: 1000,
              minimumResponseReservation: 1000,
            );

            final allocation = allocator.allocate();

            // Response must always be at least 1000 tokens
            expect(
              allocation.response,
              greaterThanOrEqualTo(1000),
              reason: 'Response reservation must be >= 1000 tokens. '
                  'Total: $totalBudget, System: $systemTokens, '
                  'History: $historyTokens, Context: $contextTokens, '
                  'Response: ${allocation.response}',
            );
          }
        }
      }
    }
  });

  test('Property: Response reservation enforced even with small total budget', () async {
    // Test edge case: very small total budget
    final allocator = const TokenBudgetAllocator(
      total: 1500,
      system: 200,
      context: 200,
      history: 100,
      response: 1000,
      minimumResponseReservation: 1000,
    );

    final allocation = allocator.allocate();

    // Response should still be at least 1000
    expect(
      allocation.response,
      greaterThanOrEqualTo(1000),
      reason: 'Even with small total budget, response must be >= 1000',
    );

    // Context should be reduced to accommodate response reservation
    expect(
      allocation.context,
      lessThanOrEqualTo(200),
      reason: 'Context should be reduced when response reservation is enforced',
    );
  });

  test('Property: Response reservation with random overrides', () async {
    final random = Random(123);
    final allocator = const TokenBudgetAllocator(
      total: 4800,
      system: 800,
      context: 2000,
      history: 1000,
      response: 1000,
      minimumResponseReservation: 1000,
    );

    // Test with 100 random override combinations
    for (int i = 0; i < 100; i++) {
      final totalOverride = 4000 + random.nextInt(4000); // 4000-8000
      final systemOverride = 300 + random.nextInt(700); // 300-1000
      final historyOverride = 300 + random.nextInt(1000); // 300-1300
      final contextOverride = 500 + random.nextInt(2000); // 500-2500
      final responseOverride = 800 + random.nextInt(400); // 800-1200

      // Skip if minimum requirements exceed total
      if (systemOverride + historyOverride + 1000 >= totalOverride) continue;

      final allocation = allocator.allocate(
        totalOverride: totalOverride,
        systemOverride: systemOverride,
        historyOverride: historyOverride,
        contextOverride: contextOverride,
        responseOverride: responseOverride,
      );

      // Response must always be at least minimum reservation
      expect(
        allocation.response,
        greaterThanOrEqualTo(allocator.minimumResponseReservation),
        reason: 'Response must be >= ${allocator.minimumResponseReservation} '
            'even with overrides. Got: ${allocation.response}',
      );

      // Response should be the max of requested and minimum
      final expectedResponse = max(responseOverride, allocator.minimumResponseReservation);
      expect(
        allocation.response,
        equals(expectedResponse),
        reason: 'Response should be max(requested, minimum). '
            'Requested: $responseOverride, Minimum: ${allocator.minimumResponseReservation}, '
            'Got: ${allocation.response}',
      );
    }
  });

  test('Property: getAvailableForContext respects response reservation', () async {
    final random = Random(456);

    // Test with various configurations
    for (int i = 0; i < 50; i++) {
      final total = 3000 + random.nextInt(5000); // 3000-8000
      final system = 500 + random.nextInt(500); // 500-1000
      final history = 500 + random.nextInt(1000); // 500-1500
      final response = 800 + random.nextInt(400); // 800-1200

      final allocator = TokenBudgetAllocator(
        total: total,
        system: system,
        context: 2000,
        history: history,
        response: response,
        minimumResponseReservation: 1000,
      );

      final availableForContext = allocator.getAvailableForContext();

      // Calculate what's actually reserved for response
      final usedByOthers = system + history + availableForContext;
      final actualResponseReservation = total - usedByOthers;

      // Response reservation should be at least minimum
      expect(
        actualResponseReservation,
        greaterThanOrEqualTo(allocator.minimumResponseReservation),
        reason: 'getAvailableForContext must leave >= ${allocator.minimumResponseReservation} '
            'for response. Total: $total, System: $system, History: $history, '
            'Available: $availableForContext, Response: $actualResponseReservation',
      );
    }
  });

  test('Property: Response reservation takes precedence over context', () async {
    // Create scenario where context + response would exceed budget
    final allocator = const TokenBudgetAllocator(
      total: 3000,
      system: 500,
      context: 2000, // Requesting 2000
      history: 500,
      response: 1000,
      minimumResponseReservation: 1000,
    );

    final allocation = allocator.allocate();

    // Response should get its minimum
    expect(
      allocation.response,
      equals(1000),
      reason: 'Response should get minimum reservation',
    );

    // Context should be reduced to fit
    final expectedContext = allocator.total -
        allocation.system -
        allocation.history -
        allocation.response;
    expect(
      allocation.context,
      equals(expectedContext),
      reason: 'Context should be reduced when response reservation takes precedence. '
          'Expected: $expectedContext, Got: ${allocation.context}',
    );

    // Context should be less than requested
    expect(
      allocation.context,
      lessThan(2000),
      reason: 'Context should be reduced from requested 2000',
    );
  });

  test('Property: Zero context is acceptable if response needs it', () async {
    // Extreme case: very small budget
    final allocator = const TokenBudgetAllocator(
      total: 1800,
      system: 500,
      context: 1000,
      history: 300,
      response: 1000,
      minimumResponseReservation: 1000,
    );

    final allocation = allocator.allocate();

    // Response must still get minimum
    expect(
      allocation.response,
      greaterThanOrEqualTo(1000),
      reason: 'Response must get minimum even if context becomes zero',
    );

    // Context might be zero or very small
    expect(
      allocation.context,
      greaterThanOrEqualTo(0),
      reason: 'Context can be zero if needed for response reservation',
    );

    // Total should not exceed budget
    final sum = allocation.system +
        allocation.context +
        allocation.history +
        allocation.response;
    expect(
      sum,
      lessThanOrEqualTo(allocator.total),
      reason: 'Total allocation should not exceed budget',
    );
  });

  test('Property: Response reservation with varying minimum values', () async {
    final random = Random(789);

    // Test with different minimum reservation values
    for (int minReservation in [500, 1000, 1500, 2000]) {
      for (int i = 0; i < 20; i++) {
        final total = 4000 + random.nextInt(4000); // 4000-8000
        final system = 500 + random.nextInt(500);
        final history = 500 + random.nextInt(1000);
        final requestedResponse = 800 + random.nextInt(1000);

        final allocator = TokenBudgetAllocator(
          total: total,
          system: system,
          context: 2000,
          history: history,
          response: requestedResponse,
          minimumResponseReservation: minReservation,
        );

        final allocation = allocator.allocate();

        // Response should be at least the minimum
        expect(
          allocation.response,
          greaterThanOrEqualTo(minReservation),
          reason: 'Response must be >= minimum reservation ($minReservation)',
        );

        // Response should be the max of requested and minimum
        expect(
          allocation.response,
          equals(max(requestedResponse, minReservation)),
          reason: 'Response should be max(requested, minimum)',
        );
      }
    }
  });

  test('Property: Allocation components sum correctly with response reservation', () async {
    final random = Random(321);

    for (int i = 0; i < 50; i++) {
      final total = 4000 + random.nextInt(4000); // 4000-8000
      final system = 500 + random.nextInt(500); // 500-1000
      final context = 1000 + random.nextInt(2000); // 1000-3000
      final history = 500 + random.nextInt(1000); // 500-1500
      final response = 800 + random.nextInt(400); // 800-1200

      // Skip if minimum requirements exceed total
      if (system + history + 1000 >= total) continue;

      final allocator = TokenBudgetAllocator(
        total: total,
        system: system,
        context: context,
        history: history,
        response: response,
        minimumResponseReservation: 1000,
      );

      final allocation = allocator.allocate();

      // Sum should not exceed total
      final sum = allocation.system +
          allocation.context +
          allocation.history +
          allocation.response;

      expect(
        sum,
        lessThanOrEqualTo(total),
        reason: 'Sum of allocations should not exceed total budget. '
            'Sum: $sum, Total: $total',
      );

      // Response should be at least 1000
      expect(
        allocation.response,
        greaterThanOrEqualTo(1000),
        reason: 'Response must be >= 1000',
      );
    }
  });
}
