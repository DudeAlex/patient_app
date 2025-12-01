import 'package:shared_preferences/shared_preferences.dart';

import 'package:patient_app/core/diagnostics/app_logger.dart';
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
    
    // Validate that stored value is between 1 and 1095 (approximately 3 years)
    if (days != null && days >= 1 && days <= 1095) {
      final isCustom = ![7, 14, 30].contains(days);
      await AppLogger.info(
        'Read date range setting from repository',
        context: {
          'dateRangeDays': days,
          'isCustom': isCustom,
          'source': 'SharedPreferences',
        },
      );
      return days;
    }
    
    // Use default if setting is missing or invalid
    final reason = days == null ? 'Setting not found' : 'Invalid value: $days';
    await AppLogger.info(
      'Using default date range',
        context: {
        'reason': reason,
        'defaultDays': _defaultDateRangeDays,
        'storedValue': days,
      },
    );
    return _defaultDateRangeDays;
  }

  @override
  Future<void> setDateRangeDays(int days) async {
    // Validate input
    if (days < 1 || days > 1095) {
      await AppLogger.warning(
        'Attempted to set invalid date range',
        context: {
          'attemptedValue': days,
          'validRange': '1-1095',
        },
      );
      throw ArgumentError.value(
        days,
        'days',
        'Date range must be between 1 and 1095 days (approximately 3 years)',
      );
    }
    
    final previousValue = _preferences.getInt(_dateRangeDaysKey);
    await _preferences.setInt(_dateRangeDaysKey, days);
    
    final isCustom = ![7, 14, 30].contains(days);
    await AppLogger.info(
      'Date range setting saved',
      context: {
        'dateRangeDays': days,
        'previousValue': previousValue,
        'isCustom': isCustom,
      },
    );
  }
}



