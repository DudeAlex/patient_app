import 'package:shared_preferences/shared_preferences.dart';

import 'context_config_repository.dart';

/// SharedPreferences-backed implementation of ContextConfigRepository.
class ContextConfigRepositoryImpl implements ContextConfigRepository {
  ContextConfigRepositoryImpl(this._preferences);

  static const String _dateRangeDaysKey = 'context_date_range_days';
  static const int _defaultDateRangeDays = 14;

  final SharedPreferences _preferences;

  @override
  Future<int> getDateRangeDays() async {
    final days = _preferences.getInt(_dateRangeDaysKey);
    // Validate that stored value is one of the allowed options
    if (days != null && (days == 7 || days == 14 || days == 30)) {
      return days;
    }
    return _defaultDateRangeDays;
  }

  @override
  Future<void> setDateRangeDays(int days) async {
    // Validate input
    if (days != 7 && days != 14 && days != 30) {
      throw ArgumentError.value(
        days,
        'days',
        'Date range must be 7, 14, or 30 days',
      );
    }
    await _preferences.setInt(_dateRangeDaysKey, days);
  }
}


