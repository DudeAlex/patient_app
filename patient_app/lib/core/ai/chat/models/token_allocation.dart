import 'package:flutter/foundation.dart';

/// Token allocation across prompt sections.
@immutable
class TokenAllocation {
  const TokenAllocation({
    required this.system,
    required this.context,
    required this.history,
    required this.response,
    required this.total,
  }) : assert(total >= system + context + history + response, 'total must cover all allocations');

  final int system;
  final int context;
  final int history;
  final int response;
  final int total;

  Map<String, dynamic> toJson() => {
        'system': system,
        'context': context,
        'history': history,
        'response': response,
        'total': total,
      };
}
