/// Context configuration for Stage 3/4 assemblies.
class ContextConfig {
  const ContextConfig({
    this.maxRecordsStage3 = 10,
    this.maxRecordsStage4 = 20,
    this.defaultDateRangeDays = 14,
    this.totalTokenBudget = 4800,
  });

  final int maxRecordsStage3;
  final int maxRecordsStage4;
  final int defaultDateRangeDays;
  final int totalTokenBudget;
}
