/// Repository for context configuration settings.
abstract class ContextConfigRepository {
  /// Get the selected date range preference (7, 14, or 30 days).
  /// Returns the number of days, defaulting to 14 if not set.
  Future<int> getDateRangeDays();

  /// Set the date range preference.
  /// 
  /// [days] must be one of: 7, 14, or 30.
  Future<void> setDateRangeDays(int days);
}


