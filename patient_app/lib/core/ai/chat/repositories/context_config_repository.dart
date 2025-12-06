/// Repository for context configuration settings.
abstract class ContextConfigRepository {
  /// Get the selected date range preference (1-1095 days, approximately 3 years).
  /// Returns the number of days, defaulting to 14 if not set or invalid.
  Future<int> getDateRangeDays();

  /// Set the date range preference.
  /// 
  /// [days] must be between 1 and 1095 (approximately 3 years).
  /// Throws [ArgumentError] if the value is outside this range.
  Future<void> setDateRangeDays(int days);
}





