import 'package:flutter/foundation.dart';

/// Metrics produced during context assembly.
@immutable
class ContextStats {
  const ContextStats({
    required this.recordsFiltered,
    required this.recordsIncluded,
    required this.tokensEstimated,
    required this.tokensAvailable,
    required this.compressionRatio,
    required this.assemblyTime,
  });

  final int recordsFiltered;
  final int recordsIncluded;
  final int tokensEstimated;
  final int tokensAvailable;
  final double compressionRatio;
  final Duration assemblyTime;

  Map<String, dynamic> toJson() => {
        'recordsFiltered': recordsFiltered,
        'recordsIncluded': recordsIncluded,
        'tokensEstimated': tokensEstimated,
        'tokensAvailable': tokensAvailable,
        'compressionRatio': compressionRatio,
        'assemblyTimeMs': assemblyTime.inMilliseconds,
      };
}
