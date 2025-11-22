import 'package:shared_preferences/shared_preferences.dart';

import 'ai_consent_repository.dart';

/// SharedPreferences-backed consent repository.
class AiConsentRepositoryImpl implements AiConsentRepository {
  AiConsentRepositoryImpl(this._preferences);

  static const _consentKey = 'ai_consent_granted';

  final SharedPreferences _preferences;

  @override
  Future<bool> hasConsent() async {
    return _preferences.getBool(_consentKey) ?? false;
  }

  @override
  Future<void> grantConsent() async {
    await _preferences.setBool(_consentKey, true);
  }

  @override
  Future<void> revokeConsent() async {
    await _preferences.setBool(_consentKey, false);
  }
}
