import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/context/token_budget_allocator.dart';

void main() {
  group('TokenBudgetAllocator', () {
    group('default allocation', () {
      test('should allocate with default budget (4800 total)', () {
        const allocator = TokenBudgetAllocator();
        final allocation = allocator.allocate();

        expect(allocation.total, 4800);
        expect(allocation.system, 800);
        expect(allocation.context, 2000);
        expect(allocation.history, 1000);
        expect(allocation.response, 1000);
      });

      test('should respect default budget breakdown', () {
        const allocator = TokenBudgetAllocator(
          total: 4800,
          system: 800,
          context: 2000,
          history: 1000,
          response: 1000,
        );

        final allocation = allocator.allocate();
        final sum = allocation.system + allocation.context + allocation.history + allocation.response;

        expect(sum, allocation.total);
      });
    });

    group('getAvailableForContext', () {
      test('should calculate available context tokens correctly', () {
        const allocator = TokenBudgetAllocator(
          total: 4800,
          system: 800,
          history: 1000,
          response: 1000,
        );

        final available = allocator.getAvailableForContext();

        // 4800 - 800 - 1000 - 1000 = 2000
        expect(available, 2000);
      });

      test('should enforce minimum response reservation', () {
        const allocator = TokenBudgetAllocator(
          total: 3000,
          system: 500,
          history: 500,
          response: 500,
          minimumResponseReservation: 1000,
        );

        final available = allocator.getAvailableForContext();

        // 3000 - 500 - 500 - 1000 (min response) = 1000
        expect(available, 1000);
      });

      test('should return 0 if no space available for context', () {
        const allocator = TokenBudgetAllocator(
          total: 2500,
          system: 800,
          history: 1000,
          response: 1000,
          minimumResponseReservation: 1000,
        );

        final available = allocator.getAvailableForContext();

        // 2500 - 800 - 1000 - 1000 = -300, clamped to 0
        expect(available, 0);
      });

      test('should use overrides when provided', () {
        const allocator = TokenBudgetAllocator();

        final available = allocator.getAvailableForContext(
          totalOverride: 6000,
          systemOverride: 1000,
          historyOverride: 1500,
          responseOverride: 1500,
        );

        // 6000 - 1000 - 1500 - 1500 = 2000
        expect(available, 2000);
      });
    });

    group('allocate', () {
      test('should cap context to available space', () {
        const allocator = TokenBudgetAllocator(
          total: 3000,
          system: 800,
          context: 2000,
          history: 1000,
          response: 1000,
        );

        final allocation = allocator.allocate();

        // Available: 3000 - 800 - 1000 - 1000 = 200
        expect(allocation.context, 200); // Capped from requested 2000
      });

      test('should enforce minimum response reservation in allocation', () {
        const allocator = TokenBudgetAllocator(
          total: 4800,
          system: 800,
          context: 2000,
          history: 1000,
          response: 500,
          minimumResponseReservation: 1000,
        );

        final allocation = allocator.allocate();

        expect(allocation.response, 1000); // Bumped from 500 to meet minimum
      });

      test('should allow response override above minimum', () {
        const allocator = TokenBudgetAllocator(
          minimumResponseReservation: 1000,
        );

        final allocation = allocator.allocate(responseOverride: 1500);

        expect(allocation.response, 1500);
      });

      test('should enforce minimum even with override below it', () {
        const allocator = TokenBudgetAllocator(
          minimumResponseReservation: 1000,
        );

        final allocation = allocator.allocate(responseOverride: 500);

        expect(allocation.response, 1000); // Enforced minimum
      });

      test('should handle custom total budget', () {
        const allocator = TokenBudgetAllocator();

        final allocation = allocator.allocate(totalOverride: 10000);

        expect(allocation.total, 10000);
      });

      test('should respect all overrides', () {
        const allocator = TokenBudgetAllocator();

        final allocation = allocator.allocate(
          totalOverride: 8000,
          systemOverride: 1000,
          contextOverride: 3000,
          historyOverride: 2000,
          responseOverride: 1500,
        );

        expect(allocation.total, 8000);
        expect(allocation.system, 1000);
        expect(allocation.history, 2000);
        expect(allocation.response, 1500);
        // Context: min(3000, 8000 - 1000 - 2000 - 1500) = min(3000, 3500) = 3000
        expect(allocation.context, 3000);
      });

      test('should clamp context override to available space', () {
        const allocator = TokenBudgetAllocator(
          total: 4000,
          system: 800,
          history: 1000,
          response: 1000,
        );

        final allocation = allocator.allocate(contextOverride: 3000);

        // Available: 4000 - 800 - 1000 - 1000 = 1200
        expect(allocation.context, 1200); // Clamped from requested 3000
      });
    });

    group('edge cases', () {
      test('should handle total equal to sum of components', () {
        const allocator = TokenBudgetAllocator(
          total: 4800,
          system: 800,
          context: 2000,
          history: 1000,
          response: 1000,
        );

        final allocation = allocator.allocate();
        final sum = allocation.system + allocation.context + allocation.history + allocation.response;

        expect(sum, allocation.total);
      });

      test('should handle very small budgets', () {
        const allocator = TokenBudgetAllocator(
          total: 1100,
          system: 100,
          context: 100,
          history: 0,
          response: 500,
          minimumResponseReservation: 1000,
        );

        final allocation = allocator.allocate();

        expect(allocation.response, 1000); // Minimum enforced
        expect(allocation.context, 0); // No space left after minimum response
      });

      test('should handle zero history budget', () {
        const allocator = TokenBudgetAllocator(
          total: 4000,
          system: 800,
          context: 2000,
          history: 0,
          response: 1000,
        );

        final allocation = allocator.allocate();

        expect(allocation.history, 0);
        // Available for context: 4000 - 800 - 0 - 1000 = 2200
        expect(allocation.context, 2000); // Requested amount fits
      });
    });

    group('invariants', () {
      test('response allocation should never be below minimum', () {
        const allocator = TokenBudgetAllocator(
          minimumResponseReservation: 1000,
        );

        // Try various overrides
        final cases = [
          allocator.allocate(),
          allocator.allocate(responseOverride: 500),
          allocator.allocate(responseOverride: 0),
          allocator.allocate(responseOverride: 1500),
        ];

        for (final allocation in cases) {
          expect(allocation.response, greaterThanOrEqualTo(1000));
        }
      });

      test('available context should never be negative', () {
        const allocator = TokenBudgetAllocator(
          total: 1000,
          system: 500,
          history: 500,
          response: 500,
        );

        final available = allocator.getAvailableForContext();

        expect(available, greaterThanOrEqualTo(0));
      });

      test('context allocation should not exceed available space', () {
        const allocator = TokenBudgetAllocator(
          total: 3000,
          system: 800,
          context: 5000, // Request more than available
          history: 1000,
          response: 1000,
        );

        final allocation = allocator.allocate();
        final available = allocator.getAvailableForContext();

        expect(allocation.context, lessThanOrEqualTo(available));
      });
    });
  });
}
