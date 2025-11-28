import 'dart:async';
import 'dart:math';

import 'package:patient_app/core/ai/chat/models/token_allocation.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';

/// Allocates token budget across prompt sections.
class TokenBudgetAllocator {
  const TokenBudgetAllocator({
    this.total = 4800,
    this.system = 800,
    this.context = 2000,
    this.history = 1000,
    this.response = 1000,
    this.minimumResponseReservation = 1000,
  }) : assert(total > 0, 'total must be positive');

  final int total;
  final int system;
  final int context;
  final int history;
  final int response;
  final int minimumResponseReservation;

  /// Computes how many tokens can be used for context after reserving
  /// system, history, and response budgets.
  int getAvailableForContext({
    int? totalOverride,
    int? systemOverride,
    int? historyOverride,
    int? responseOverride,
  }) {
    final availableTotal = totalOverride ?? total;
    final systemTokens = systemOverride ?? system;
    final historyTokens = historyOverride ?? history;
    final responseTokens = max(
      responseOverride ?? response,
      minimumResponseReservation,
    );
    final remaining = availableTotal - systemTokens - historyTokens - responseTokens;
    return max(0, remaining);
  }

  TokenAllocation allocate({
    int? totalOverride,
    int? systemOverride,
    int? contextOverride,
    int? historyOverride,
    int? responseOverride,
  }) {
    final availableTotal = totalOverride ?? total;
    final systemTokens = systemOverride ?? system;
    final historyTokens = historyOverride ?? history;
    final responseTokens = max(
      responseOverride ?? response,
      minimumResponseReservation,
    );
    final availableContext = getAvailableForContext(
      totalOverride: availableTotal,
      systemOverride: systemTokens,
      historyOverride: historyTokens,
      responseOverride: responseTokens,
    );
    final contextTokens = min(contextOverride ?? context, availableContext);

    final allocation = TokenAllocation(
      system: systemTokens,
      context: contextTokens,
      history: historyTokens,
      response: responseTokens,
      total: availableTotal,
    );

    // Log token allocation breakdown
    unawaited(
      AppLogger.info(
        'Token budget allocated',
        context: {
          'total': allocation.total,
          'system': allocation.system,
          'context': allocation.context,
          'history': allocation.history,
          'response': allocation.response,
          'contextAvailable': availableContext,
          'contextRequested': contextOverride ?? context,
          'contextAllocated': contextTokens,
          'minimumResponseReservation': minimumResponseReservation,
        },
      ),
    );

    return allocation;
  }
}
