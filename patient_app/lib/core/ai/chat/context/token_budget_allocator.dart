import 'package:patient_app/core/ai/chat/models/token_allocation.dart';

/// Allocates token budget across prompt sections.
class TokenBudgetAllocator {
  const TokenBudgetAllocator({
    this.total = 4800,
    this.system = 800,
    this.context = 2000,
    this.history = 1000,
    this.response = 1000,
  });

  final int total;
  final int system;
  final int context;
  final int history;
  final int response;

  TokenAllocation allocate() {
    return TokenAllocation(
      system: system,
      context: context,
      history: history,
      response: response,
      total: total,
    );
  }
}
