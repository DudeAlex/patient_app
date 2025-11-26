import 'package:patient_app/core/ai/chat/context/token_budget_allocator.dart';
import 'package:patient_app/core/ai/chat/models/token_allocation.dart';

/// Simple deterministic allocator for tests.
class FakeTokenBudgetAllocator extends TokenBudgetAllocator {
  const FakeTokenBudgetAllocator({
    TokenAllocation? allocation,
  })  : _allocation = allocation ??
            const TokenAllocation(
              system: 50,
              context: 100,
              history: 25,
              response: 25,
              total: 200,
            ),
        super();

  final TokenAllocation _allocation;

  @override
  TokenAllocation allocate() => _allocation;
}
