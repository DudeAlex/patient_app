import 'package:flutter/foundation.dart';

import '../models/date_range.dart';

/// Configuration for context assembly in Stage 3 and Stage 4.
/// 
/// Provides stage-specific settings for record limits, date ranges, and token budgets.
@immutable
class ContextConfig {
  const ContextConfig({
    required this.maxRecordsStage3,
    required this.maxRecordsStage4,
    required this.defaultDateRange,
    required this.totalTokenBudget,
  });

  /// Maximum records to include in Stage 3 (basic context).
  final int maxRecordsStage3;

  /// Maximum records to include in Stage 4 (optimized context).
  final int maxRecordsStage4;

  /// Default date range for filtering records.
  final DateRange defaultDateRange;

  /// Total token budget for the entire request.
  final int totalTokenBudget;

  /// Factory method for Stage 3 configuration.
  /// 
  /// Stage 3 uses basic context with last 10 records and 4000 token budget.
  factory ContextConfig.stage3() {
    return ContextConfig(
      maxRecordsStage3: 10,
      maxRecordsStage4: 20,
      defaultDateRange: DateRange.last14Days(),
      totalTokenBudget: 4000,
    );
  }

  /// Factory method for Stage 4 configuration.
  /// 
  /// Stage 4 uses optimized context with up to 20 records and 4800 token budget.
  factory ContextConfig.stage4() {
    return ContextConfig(
      maxRecordsStage3: 10,
      maxRecordsStage4: 20,
      defaultDateRange: DateRange.last14Days(),
      totalTokenBudget: 4800,
    );
  }

  /// Default configuration (Stage 4).
  /// 
  /// Returns a Stage 4 configuration instance.
  static ContextConfig defaultConfig() => ContextConfig.stage4();

  /// Creates a copy of this config with updated values.
  ContextConfig copyWith({
    int? maxRecordsStage3,
    int? maxRecordsStage4,
    DateRange? defaultDateRange,
    int? totalTokenBudget,
  }) {
    return ContextConfig(
      maxRecordsStage3: maxRecordsStage3 ?? this.maxRecordsStage3,
      maxRecordsStage4: maxRecordsStage4 ?? this.maxRecordsStage4,
      defaultDateRange: defaultDateRange ?? this.defaultDateRange,
      totalTokenBudget: totalTokenBudget ?? this.totalTokenBudget,
    );
  }
}

